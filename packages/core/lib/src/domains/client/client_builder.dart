import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/domains/common/app_state.dart';
import 'package:mineral/src/domains/common/kernel.dart';
import 'package:mineral/src/domains/common/runtime_state.dart';
import 'package:mineral/src/domains/common/utils/helper.dart';
import 'package:mineral/src/domains/container/ioc_container.dart';
import 'package:mineral/src/domains/events/event_listener.dart';
import 'package:mineral/src/domains/global_states/global_state_manager.dart';
import 'package:mineral/src/domains/providers/provider_manager.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_listener.dart';
import 'package:mineral/src/infrastructure/internals/wss/sharding_config.dart';
import 'package:mineral/src/infrastructure/internals/wss/websocket_orchestrator.dart';

/// Composition output of [composeApp]: the application graph every
/// downstream bot is built from. Mirrors the shape of [DataLayerComposition]
/// in `marshaller.dart` — the fields most callers need direct access to are
/// exposed individually even though most are also reachable through
/// [appState], because [composeApp] is the only sanctioned place where the
/// graph's two genuine construction cycles are closed:
/// [WebsocketOrchestrator.onFatalDisconnect] <-> [Kernel], and
/// [PacketListener.kernel] / [PacketListener.init] <-> [Kernel]. Outside this
/// function the graph appears fully wired and immutable.
typedef AppComposition = ({
  Kernel kernel,
  PacketListener packetListener,
  WebsocketOrchestratorContract wss,
  DataStoreContract dataStore,
  MarshallerContract marshaller,
  AppState appState,
});

/// Builds the full application graph — every module [ClientBuilder.build]
/// constructs, wired together — from an explicitly-passed [env] instead of
/// the process-global one. This is what makes the composition root testable:
/// a test can call [composeApp] directly with an [Env] it controls and
/// inspect the returned graph, without touching process globals.
///
/// [composeApp] never reads or writes the global `ioc` container; mirroring
/// bindings into it for end-user DX is [ClientBuilder.build]'s job, once it
/// has a finished [AppComposition] in hand.
AppComposition composeApp({
  required Env env,
  LoggerContract? logger,
  CacheProviderContract? cache,
  CacheConfig? cacheConfig,
  String? token,
  int? intent,
  int? discordRestHttpVersion,
  int? discordWssVersion,
  WebsocketEncoder wssEncoder = WebsocketEncoder.json,
}) {
  final resolvedCacheConfig = cacheConfig ?? CacheConfig.defaults();

  final logLevel = env.get(AppEnv.logLevel);
  final dartEnv = env.get<DartEnv>(AppEnv.dartEnv);

  final resolvedLogger = logger ?? Logger(logLevel as LogLevel, dartEnv.value);

  // Dedicated subsystem loggers so output is prefixed with a meaningful
  // label (`[websocket]`, `[http]`, `[datastore]`, `[marshaller]`) instead
  // of the default `[mineral]`. Only applies when the caller hasn't
  // overridden the logger — custom loggers are used as-is to respect their
  // own labelling conventions.
  LoggerContract labelled(String label) =>
      logger ?? Logger(logLevel as LogLevel, dartEnv.value, label: label);

  final wssLogger = labelled('websocket');
  final httpLogger = labelled('http');
  final dataStoreLogger = labelled('datastore');
  final marshallerLogger = labelled('marshaller');

  final resolvedToken = env.get<String>(AppEnv.token, defaultValue: token);
  final resolvedIntent = env.get<int>(AppEnv.intent, defaultValue: intent);

  final httpVersion = env.get<int>(
    AppEnv.discordRestHttpVersion,
    defaultValue: discordRestHttpVersion,
  );

  final shardVersion = env.get<int>(
    AppEnv.discordWssVersion,
    defaultValue: discordWssVersion,
  );

  final wsEncodingStrategy = env.get(
    AppEnv.discordWssEncoding,
    defaultValue: wssEncoder,
  );

  final http = ResilientHttpClient(
    HttpClient(
      config: HttpClientConfigImpl(
        uri: Uri.parse('https://discord.com/api/v$httpVersion'),
        headers: {
          Header.userAgent('Mineral'),
          Header.contentType('application/json'),
        },
      ),
    ),
  );

  final shardConfig = ShardingConfig(
    token: resolvedToken,
    intent: resolvedIntent,
    version: shardVersion,
    encoding: wsEncodingStrategy.strategy(logger: wssLogger),
  );

  final eventListener = EventListener();
  final providerManager = ProviderManager(logger: resolvedLogger);
  final globalStateManager = GlobalStateManager();
  final interactiveComponent = InteractiveComponentManager(
    logger: labelled('components'),
  );
  final wssOrchestrator = WebsocketOrchestrator(
    shardConfig,
    logger: wssLogger,
    httpClient: http,
  );

  final runtimeState = RuntimeState();

  final dataLayer = composeDataLayer(
    marshallerLogger: marshallerLogger,
    dataStoreLogger: dataStoreLogger,
    httpLogger: httpLogger,
    cache: cache,
    httpClient: http,
    wss: wssOrchestrator,
    runtimeState: runtimeState,
  );
  final marshaller = dataLayer.marshaller;
  final dataStore = dataLayer.dataStore;
  final entityContext = dataLayer.entityContext;
  final commandManager = CommandInteractionManager(
    dataStore: dataStore,
    marshaller: marshaller,
    ctx: entityContext,
  );

  // PacketListener is constructed here — after all its dependencies are
  // available but before Kernel, because Kernel takes PacketListener as a
  // required argument. The only field that cannot be passed here is `kernel`
  // itself (genuine cycle), which is wired via the setter below.
  final packetListener = PacketListener(
    marshaller: marshaller,
    dataStore: dataStore,
    interactiveComponent: interactiveComponent,
    commandManager: commandManager,
    entityContext: entityContext,
    runtimeState: runtimeState,
    cacheConfig: resolvedCacheConfig,
  );

  final kernel = Kernel(
    logger: resolvedLogger,
    httpClient: http,
    packetListener: packetListener,
    providerManager: providerManager,
    eventListener: eventListener,
    globalState: globalStateManager,
    interactiveComponent: interactiveComponent,
    wss: wssOrchestrator,
    runtimeState: runtimeState,
  );

  // Close the cycle: the orchestrator was built before the kernel, so its
  // fatal-disconnect hook is wired here once the kernel exists.
  wssOrchestrator.onFatalDisconnect = kernel.dispose;

  final appState = AppState(
    logger: resolvedLogger,
    httpClient: http,
    cache: cache,
    cacheConfig: resolvedCacheConfig,
    marshaller: marshaller,
    dataStore: dataStore,
    wss: wssOrchestrator,
    packetListener: packetListener,
    eventListener: eventListener,
    providerManager: providerManager,
    globalState: globalStateManager,
    interactiveComponent: interactiveComponent,
    commandManager: commandManager,
    kernel: kernel,
  );

  // Wire the one field that could not be passed at construction time (cycle).
  packetListener
    ..kernel = appState.kernel
    ..init();

  eventListener.kernel = appState.kernel;

  return (
    kernel: kernel,
    packetListener: packetListener,
    wss: wssOrchestrator,
    dataStore: dataStore,
    marshaller: marshaller,
    appState: appState,
  );
}

final class ClientBuilder {
  LoggerContract? _logger;
  CacheProviderContract? _cache;
  CacheConfig _cacheConfig = CacheConfig.defaults();
  final List<EnvSchema> _schemas = [];
  final List<ConstructableWithArgs<ProviderContract, Client>> _providers = [];

  WebsocketEncoder _wssEncoder = WebsocketEncoder.json;

  String? _token;
  int? _intent;
  int? _discordRestHttpVersion;
  int? _discordWssVersion;

  ClientBuilder setToken(String token) {
    _token = token;
    return this;
  }

  ClientBuilder setIntent(int intent) {
    _intent = intent;
    return this;
  }

  ClientBuilder setDiscordRestHttpVersion(int version) {
    _discordRestHttpVersion = version;
    return this;
  }

  ClientBuilder setDiscordWssVersion(int version) {
    _discordWssVersion = version;
    return this;
  }

  ClientBuilder setEncoder(WebsocketEncoder encoding) {
    _wssEncoder = encoding;
    return this;
  }

  ClientBuilder setCache(
    ConstructableWithArgs<CacheProviderContract, Env> cache, {
    CacheConfig? config,
  }) {
    _cacheConfig = config ?? CacheConfig.defaults();
    ioc.bind<CacheConfig>(() => _cacheConfig);
    _cache = ioc.make<CacheProviderContract>(() => cache(env))
      ..config = _cacheConfig;
    return this;
  }

  ClientBuilder setLogger(ConstructableWithArgs<LoggerContract, Env> logger) {
    _logger = logger(env);
    return this;
  }

  ClientBuilder validateEnvironment(List<EnvSchema> schema) {
    _schemas.addAll(schema);
    return this;
  }

  ClientBuilder registerProvider<T extends ProviderContract>(
    T Function(Client) provider,
  ) {
    _providers.add(provider);
    return this;
  }

  void _validateEnvironment() {
    env.defineOf(AppEnv.new);
  }

  Client build() {
    _validateEnvironment();

    final composition = composeApp(
      env: env,
      logger: _logger,
      cache: _cache,
      cacheConfig: _cacheConfig,
      token: _token,
      intent: _intent,
      discordRestHttpVersion: _discordRestHttpVersion,
      discordWssVersion: _discordWssVersion,
      wssEncoder: _wssEncoder,
    );
    final appState = composition.appState;

    // Mirror AppState into the IoC for end-user DX. The core itself never
    // reads from these bindings; they exist so user handlers/commands/
    // providers can keep using `container.resolve<T>()`.
    ioc
      ..bind<LoggerContract>(() => appState.logger)
      ..bind<HttpClientContract>(() => appState.httpClient)
      ..bind<Kernel>(() => appState.kernel)
      ..bind<MarshallerContract>(() => appState.marshaller)
      ..bind<DataStoreContract>(() => appState.dataStore)
      ..bind<CommandInteractionManagerContract>(() => appState.commandManager)
      ..bind<WebsocketOrchestratorContract>(() => appState.wss)
      ..bind<InteractiveComponentManagerContract>(
        () => appState.interactiveComponent,
      )
      ..bindLazy<Bot>(
        () =>
            appState.kernel.runtimeState.bot ??
            (throw StateError(
              'Bot is not yet available — wait for the gateway READY event before resolving Bot from the container.',
            )),
      )
      ..require<LoggerContract>()
      ..require<HttpClientContract>()
      ..require<Kernel>()
      ..require<MarshallerContract>()
      ..require<DataStoreContract>()
      ..require<CommandInteractionManagerContract>()
      ..require<WebsocketOrchestratorContract>()
      ..require<InteractiveComponentManagerContract>()
      ..validateBindings();

    final client = Client(
      appState.kernel,
      rest: appState.dataStore,
      commandManager: appState.commandManager,
      cache: _cache,
    );

    for (final provider in _providers) {
      appState.providerManager.register(provider(client));
    }

    return client;
  }
}
