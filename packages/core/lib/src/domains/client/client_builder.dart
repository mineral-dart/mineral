import 'dart:isolate';

import 'package:glob/glob.dart';
import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/domains/commands/command_interaction_manager.dart';
import 'package:mineral/src/domains/common/kernel.dart';
import 'package:mineral/src/domains/common/utils/helper.dart';
import 'package:mineral/src/domains/container/ioc_container.dart';
import 'package:mineral/src/domains/events/event_listener.dart';
import 'package:mineral/src/domains/global_states/global_state_manager.dart';
import 'package:mineral/src/domains/providers/provider_manager.dart';
import 'package:mineral/src/infrastructure/internals/datastore/datastore.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_listener.dart';
import 'package:mineral/src/infrastructure/internals/wss/sharding_config.dart';
import 'package:mineral/src/infrastructure/internals/wss/websocket_orchestrator.dart';

final class ClientBuilder {
  late final LoggerContract _logger;
  CacheProviderContract? _cache;
  CacheConfig _cacheConfig = CacheConfig.defaults();
  final List<EnvSchema> _schemas = [];
  final List<ConstructableWithArgs<ProviderContract, Client>> _providers = [];

  SendPort? _devPort;
  bool _hasDefinedDevPort = false;
  WebsocketEncoder _wssEncoder = WebsocketEncoder.json;

  String? _token;
  int? _intent;
  int? _discordRestHttpVersion;
  int? _discordWssVersion;
  final List<Glob> _watchedFiles = [];

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
    _cache = ioc.make<CacheProviderContract>(() => cache(env));
    return this;
  }

  ClientBuilder setLogger(ConstructableWithArgs<LoggerContract, Env> logger) {
    _logger = logger(env);
    return this;
  }

  ClientBuilder setHmrDevPort(SendPort? devPort) {
    _devPort = devPort;
    _hasDefinedDevPort = true;

    ioc.bind<SendPort?>(() => _devPort);

    return this;
  }

  ClientBuilder validateEnvironment(List<EnvSchema> schema) {
    _schemas.addAll(schema);
    return this;
  }

  ClientBuilder watch(List<Glob> globs) {
    _watchedFiles.addAll(globs);
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

  void _createCache() {
    final isDevelopmentMode = env.get(AppEnv.dartEnv) == DartEnv.development;
    final isMainIsolate = Isolate.current.debugName == 'main';

    if (isDevelopmentMode && isMainIsolate) {
      return;
    }

    if (_cache case final CacheProviderContract cache) {
      cache.init();
    }
  }

  Client build() {
    _validateEnvironment();

    final logLevel = env.get(AppEnv.logLevel);
    final dartEnv = env.get<DartEnv>(AppEnv.dartEnv);

    _logger = ioc.make<LoggerContract>(() => Logger(logLevel as LogLevel, dartEnv.value));

    _createCache();

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
        encoding: wsEncodingStrategy.strategy());

    final packetListener = PacketListener();
    final eventListener = EventListener();
    final providerManager = ProviderManager();
    final globalStateManager = ioc.make(GlobalStateManager.new);
    final interactiveComponent = ioc.make<InteractiveComponentManagerContract>(
        InteractiveComponentManager.new);
    final wssOrchestrator = ioc.make<WebsocketOrchestratorContract>(
        () => WebsocketOrchestrator(shardConfig));

    final kernel = Kernel(
      _hasDefinedDevPort,
      _devPort,
      _watchedFiles,
      logger: _logger,
      httpClient: http,
      packetListener: packetListener,
      providerManager: providerManager,
      eventListener: eventListener,
      globalState: globalStateManager,
      interactiveComponent: interactiveComponent,
      wss: wssOrchestrator,
    );

    ioc
      ..require<LoggerContract>()
      ..require<HttpClientContract>()
      ..require<Kernel>()
      ..require<MarshallerContract>()
      ..require<DataStoreContract>()
      ..require<CommandInteractionManagerContract>()
      ..require<WebsocketOrchestratorContract>()
      ..require<InteractiveComponentManagerContract>()
      ..bind<HttpClientContract>(() => http)
      ..bind<Kernel>(() => kernel)
      ..bind<MarshallerContract>(Marshaller.new)
      ..bind<DataStoreContract>(() => DataStore(
            client: http,
            marshaller: ioc.resolve<MarshallerContract>(),
          ))
      ..bind<CommandInteractionManagerContract>(CommandInteractionManager.new)
      ..validateBindings();

    packetListener
      ..kernel = kernel
      ..init();

    final client = Client(kernel);

    for (final provider in _providers) {
      providerManager.register(provider(client));
    }

    return client;
  }
}
