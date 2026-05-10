import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/cache_key.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializer_bucket.dart';

import 'fake_logger.dart';
import 'fake_websocket_orchestrator.dart';

/// A minimal [MarshallerContract] for use in tests.
///
/// Has no cache by default; pass a [CacheProviderContract] to enable caching.
/// Pass a [logger] to share the same [FakeLogger] instance with the test so
/// that log assertions work correctly.
final class FakeMarshaller implements MarshallerContract {
  @override
  final LoggerContract logger;

  @override
  late final SerializerBucket serializers;

  @override
  final CacheProviderContract? cache;

  @override
  final CacheKey cacheKey = CacheKey();

  FakeMarshaller({
    LoggerContract? logger,
    this.cache,
    EntityContext? entityContext,
    DataStoreContract? dataStore,
  }) : logger = logger ?? FakeLogger() {
    final ctx = entityContext ??
        EntityContext(
          datastore: dataStore ?? _UnimplementedDataStore(),
          wss: FakeWebsocketOrchestrator(),
          logger: this.logger,
        );
    serializers = SerializerBucket(this, ctx);
  }
}

final class _UnimplementedDataStore implements DataStoreContract {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(
          'FakeMarshaller default datastore does not implement '
          '${invocation.memberName}; pass a real DataStoreContract via '
          'FakeMarshaller(dataStore: ...) if your test needs it.');
}
