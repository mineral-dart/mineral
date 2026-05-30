import 'package:mineral/contracts.dart';
import 'package:mineral/mineral_testing.dart';
// ignore: implementation_imports
import 'package:mineral/src/domains/common/entity_context.dart';
// ignore: implementation_imports
import 'package:mineral/src/infrastructure/internals/marshaller/cache_key.dart';
// ignore: implementation_imports
import 'package:mineral/src/infrastructure/internals/marshaller/serializer_bucket.dart';

/// Minimal [MarshallerContract] used by [TestKernel].
///
/// No cache by default. Pass an injected [logger] to share it with the test
/// (e.g. when the test needs to assert on log output).
final class TestMarshaller implements MarshallerContract {
  @override
  final LoggerContract logger;

  @override
  late final SerializerBucket serializers;

  @override
  final CacheProviderContract? cache;

  @override
  final CacheKey cacheKey = CacheKey();

  TestMarshaller({
    required EntityContext entityContext,
    LoggerContract? logger,
    this.cache,
  }) : logger = logger ?? FakeLogger() {
    serializers = SerializerBucket(this, entityContext);
  }

  /// Constructor used when the [EntityContext] is not yet available because
  /// the [DataStore] needs the marshaller to construct itself. Call
  /// [bindSerializers] once the context can be built.
  TestMarshaller.unbound({LoggerContract? logger, this.cache})
      : logger = logger ?? FakeLogger();

  /// Closes the cyclic Marshaller / DataStore / EntityContext loop in
  /// test fixtures. Mirrors the pattern used by `composeDataLayer` in
  /// production. Must be called exactly once.
  void bindSerializers(EntityContext entityContext) {
    serializers = SerializerBucket(this, entityContext);
  }
}
