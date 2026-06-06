import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/common/runtime_state.dart';
import 'package:mineral/src/domains/services/cache/cache_provider_contract.dart';
import 'package:mineral/src/domains/services/logger/logger_contract.dart';
import 'package:mineral/src/domains/services/marshaller/marshaller.dart';
import 'package:mineral/src/infrastructure/internals/datastore/datastore.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/cache_key.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializer_bucket.dart';

/// Composition output for the marshaller / datastore / entity-context
/// cluster: three objects whose dependencies are mutually circular by nature
/// (entities call DataStore, DataStore is built using Marshaller, Marshaller's
/// serializers construct entities). Returned by [composeDataLayer], which is
/// the only sanctioned entry point for building these three together.
typedef DataLayerComposition = ({
  MarshallerContract marshaller,
  DataStoreContract dataStore,
  EntityContext entityContext,
});

final class Marshaller implements MarshallerContract {
  @override
  final LoggerContract logger;

  @override
  final CacheProviderContract? cache;

  @override
  final CacheKey cacheKey = CacheKey();

  late final SerializerBucket _serializers;

  Marshaller._({required this.logger, required this.cache});

  @override
  SerializerBucket get serializers => _serializers;
}

/// Constructs the cyclic Marshaller / DataStore / EntityContext cluster in
/// one step. The cycle is closed in this single function: outside this file
/// the three components appear fully formed and immutable.
DataLayerComposition composeDataLayer({
  required LoggerContract marshallerLogger,
  required LoggerContract dataStoreLogger,
  required LoggerContract httpLogger,
  required CacheProviderContract? cache,
  required HttpClientContract httpClient,
  required WebsocketOrchestratorContract wss,
  required RuntimeState runtimeState,
}) {
  final marshaller = Marshaller._(logger: marshallerLogger, cache: cache);
  final dataStore = DataStore(
    client: httpClient,
    marshaller: marshaller,
    logger: dataStoreLogger,
    httpLogger: httpLogger,
  );
  final entityContext = EntityContext(
    datastore: dataStore,
    wss: wss,
    logger: dataStoreLogger,
    runtimeState: runtimeState,
  );
  marshaller._serializers = SerializerBucket(marshaller, entityContext);
  return (
    marshaller: marshaller,
    dataStore: dataStore,
    entityContext: entityContext,
  );
}
