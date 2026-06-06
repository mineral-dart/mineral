import 'package:mineral/container.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/mineral_testing.dart';
import 'package:mineral/services.dart' show HttpClientContract;
// ignore: implementation_imports
import 'package:mineral/src/domains/common/entity_context.dart';
// ignore: implementation_imports
import 'package:mineral/src/domains/common/runtime_state.dart';
// ignore: implementation_imports
import 'package:mineral/src/infrastructure/internals/datastore/datastore.dart';

import '../fakes/test_marshaller.dart';
import '../recorders/bot_actions.dart';
import '../recorders/recording_http_client.dart';

/// Boots a Mineral-compatible IoC container without WebSocket or HTTP.
///
/// [TestKernel] is the in-memory equivalent of `ClientBuilder.build()` —
/// it registers the contracts that handlers may resolve at runtime
/// ([LoggerContract], [HttpClientContract], [MarshallerContract],
/// [DataStoreContract], [CommandInteractionManagerContract],
/// [InteractiveComponentManagerContract]) but skips everything network-bound
/// (no `Kernel`, no `WebsocketOrchestratorContract`, no packet listener).
///
/// Each kernel owns a fresh [IocContainer] and uses [scopedIoc] to swap it in
/// for the duration of the test. Call [dispose] in `tearDown` to restore the
/// previous global container and release resources.
final class TestKernel {
  final IocContainer container;
  final IocContainer Function() _restore;

  /// The fake logger backing this kernel.
  final FakeLogger logger;

  /// Recorder of every observable bot side-effect.
  final BotActions actions;

  TestKernel._(this.container, this._restore, this.logger, this.actions);

  /// Creates a new kernel and installs it as the active [ioc] container.
  factory TestKernel.boot() {
    final logger = FakeLogger();
    final actions = BotActions();
    final httpClient = RecordingHttpClient(actions);

    // Compose the data layer manually here. We can't use composeDataLayer
    // because TestKernel skips the websocket orchestrator; we still need a
    // valid EntityContext for serializers and entities.
    late final TestMarshaller marshaller;
    late final DataStore dataStore;
    late final EntityContext entityContext;

    marshaller = TestMarshaller.unbound(logger: logger);
    dataStore = DataStore(
        client: httpClient,
        marshaller: marshaller,
        logger: logger,
        httpLogger: logger);
    entityContext = EntityContext(
      datastore: dataStore,
      wss: _UnimplementedWss(),
      logger: logger,
      runtimeState: RuntimeState(),
    );
    marshaller.bindSerializers(entityContext);

    final commandManager = CommandInteractionManager(
      dataStore: dataStore,
      marshaller: marshaller,
      ctx: entityContext,
    );

    final container = IocContainer()
      ..bind<LoggerContract>(() => logger)
      ..bind<HttpClientContract>(() => httpClient)
      ..bind<MarshallerContract>(() => marshaller)
      ..bind<DataStoreContract>(() => dataStore)
      ..bind<CommandInteractionManagerContract>(() => commandManager)
      ..bind<InteractiveComponentManagerContract>(
          InteractiveComponentManager.new);

    final restore = scopedIoc(container);
    return TestKernel._(container, restore, logger, actions);
  }

  /// Restores the previous global container and disposes bindings.
  Future<void> dispose() async {
    _restore();
    await container.dispose();
  }
}

final class _UnimplementedWss implements WebsocketOrchestratorContract {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(
          'TestKernel does not bind a real WebsocketOrchestratorContract; '
          'tests that touch wss should be migrated to a richer fixture.');
}
