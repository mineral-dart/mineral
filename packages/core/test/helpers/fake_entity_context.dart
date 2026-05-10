import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

import 'fake_datastore.dart';
import 'fake_http_client.dart';
import 'fake_websocket_orchestrator.dart';

/// Builds an [EntityContext] with stubbed datastore + websocket orchestrator
/// suitable for tests of code that does not exercise either dependency.
EntityContext fakeEntityContext({
  DataStoreContract? dataStore,
  WebsocketOrchestratorContract? wss,
}) =>
    EntityContext(
      datastore: dataStore ?? FakeDataStore(FakeHttpClient()),
      wss: wss ?? FakeWebsocketOrchestrator(),
    );
