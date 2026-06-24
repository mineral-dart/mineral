import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/common/runtime_state.dart';
import 'package:mineral/src/testing/fake_logger.dart';

import 'fake_datastore.dart';
import 'fake_http_client.dart';
import 'fake_websocket_orchestrator.dart';

/// Builds an [EntityContext] with stubbed datastore + websocket orchestrator
/// + logger + runtime state suitable for tests of code that does not
/// exercise these dependencies.
EntityContext fakeEntityContext({
  DataStoreContract? dataStore,
  WebsocketOrchestratorContract? wss,
  LoggerContract? logger,
  RuntimeState? runtimeState,
}) => EntityContext(
  datastore: dataStore ?? FakeDataStore(FakeHttpClient()),
  wss: wss ?? FakeWebsocketOrchestrator(),
  logger: logger ?? FakeLogger(),
  runtimeState: runtimeState ?? RuntimeState(),
);
