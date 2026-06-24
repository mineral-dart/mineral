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
      T Function(Client) provider) {
    _providers.add(provider);
    return this;
  }

  void _validateEnvironment() {
    env.defineOf(AppEnv.new);
  }

  Client build() {
    _validateEnvironment();

    final logLevel = env.get(AppEnv.logLevel);
    final dartEnv = env.get<DartEnv>(AppEnv.dartEnv);

    final logger = _logger ?? Logger(logLevel as LogLevel, dartEnv.value);
    ioc.bind<LoggerContract>(() => logger);

    // Dedicated subsystem loggers so output is prefixed with a meaningful
    // label (`[websocket]`, `[http]`, `[datastore]`, `[marshaller]`) instead
    // of the default `[mineral]`. Only applies when the user hasn't
    // overridden the logger via `setLogger` — custom loggers are used as-is
    // to respect their own labelling conventions.
    LoggerContract labelled(String label) => _logger ??
        Logger(logLevel as LogLevel, dartEnv.value, label: label);

    final wssLogger = labelled('websocket');
    final httpLogger = labelled('http');
    final dataStoreLogger = labelled('datastore');
    final marshallerLogger = labelled('marshaller');

    final token = env.get<String>(AppEnv.token, defaultValue: _token);
    final intent = env.get<int>(AppEnv.intent, defaultValue: _intent);

    final httpVersion = env.get<int>(AppEnv.discordRestHttpVersion,
        defaultValue: _discordRestHttpVersion);

    final shardVersion = env.get<int>(AppEnv.discordWssVersion,
        defaultValue: _discordWssVersion);

    final wsEncodingStrategy =
        env.get(AppEnv.discordWssEncoding, defaultValue: _wssEncoder);

    final http = ResilientHttpClient(
        HttpClient(
            config: HttpClientConfigImpl(
                uri: Uri.parse('https://discord.com/api/v$httpVersion'),
                headers: {
              Header.userAgent('Mineral'),
              Header.contentType('application/json'),
            })));

    final shardConfig = ShardingConfig(
        token: token,
        intent: intent,
        version: shardVersion,
        encoding: wsEncodingStrategy.strategy(logger: wssLogger));

    final packetListener = PacketListener();
    final eventListener = EventListener();
    final providerManager = ProviderManager(logger: logger);
    final globalStateManager = GlobalStateManager();
    final interactiveComponent = InteractiveComponentManager();
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
      cache: _cache,
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

    final kernel = Kernel(
      logger: logger,
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
      logger: logger,
      httpClient: http,
      cache: _cache,
      cacheConfig: _cacheConfig,
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

    // Mirror AppState into the IoC for end-user DX. The core itself never
    // reads from these bindings; they exist so user handlers/commands/
    // providers can keep using `container.resolve<T>()`.
    ioc
      ..bind<HttpClientContract>(() => appState.httpClient)
      ..bind<Kernel>(() => appState.kernel)
      ..bind<MarshallerContract>(() => appState.marshaller)
      ..bind<DataStoreContract>(() => appState.dataStore)
      ..bind<CommandInteractionManagerContract>(() => appState.commandManager)
      ..bind<WebsocketOrchestratorContract>(() => appState.wss)
      ..bind<InteractiveComponentManagerContract>(() => appState.interactiveComponent)
      ..bindLazy<Bot>(() =>
          runtimeState.bot ??
          (throw StateError(
              'Bot is not yet available — wait for the gateway READY event before resolving Bot from the container.')))
      ..require<LoggerContract>()
      ..require<HttpClientContract>()
      ..require<Kernel>()
      ..require<MarshallerContract>()
      ..require<DataStoreContract>()
      ..require<CommandInteractionManagerContract>()
      ..require<WebsocketOrchestratorContract>()
      ..require<InteractiveComponentManagerContract>()
      ..validateBindings();

    packetListener
      ..kernel = appState.kernel
      ..marshaller = appState.marshaller
      ..dataStore = appState.dataStore
      ..interactiveComponent = appState.interactiveComponent
      ..commandManager = appState.commandManager
      ..entityContext = entityContext
      ..runtimeState = runtimeState
      ..cacheConfig = appState.cacheConfig
      ..init();

    eventListener.kernel = appState.kernel;

    final client = Client(
      appState.kernel,
      rest: appState.dataStore,
      commandManager: appState.commandManager,
      cache: _cache,
    );

    for (final provider in _providers) {
      providerManager.register(provider(client));
    }

    return client;
  }
}
