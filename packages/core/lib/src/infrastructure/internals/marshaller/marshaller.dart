import 'package:mineral/src/domains/services/cache/cache_provider_contract.dart';
import 'package:mineral/src/domains/services/logger/logger_contract.dart';
import 'package:mineral/src/domains/services/marshaller/marshaller.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/cache_key.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializer_bucket.dart';

final class Marshaller implements MarshallerContract {
  @override
  final LoggerContract logger;

  @override
  final CacheProviderContract? cache;

  @override
  late final SerializerBucket serializers;

  @override
  final CacheKey cacheKey = CacheKey();

  Marshaller({required this.logger, required this.cache}) {
    serializers = SerializerBucket(this);
  }
}
