import 'package:mineral/src/domains/services/cache/cache_config.dart';
import 'package:mineral/src/domains/services/cache/cache_ttl_policy.dart';
import 'package:test/test.dart';

void main() {
  group('CacheConfig.defaults', () {
    final config = CacheConfig.defaults();

    test('clears the cache on READY by default', () {
      expect(config.clearOnReady, isTrue);
    });

    test('enables the invalidation listener by default', () {
      expect(config.invalidationEnabled, isTrue);
    });

    test('runs the sweeper every minute by default', () {
      expect(config.sweeperInterval, const Duration(minutes: 1));
    });

    test('uses a 500 ms stagger by default', () {
      expect(config.staggerClearMs, 500);
    });

    test('exposes the default TTL policy', () {
      expect(config.ttlPolicy.ttlFor('users/123'), const Duration(hours: 1));
    });
  });

  group('CacheConfig.legacy', () {
    final config = CacheConfig.legacy();

    test('does not clear on READY', () {
      expect(config.clearOnReady, isFalse);
    });

    test('disables the invalidation listener', () {
      expect(config.invalidationEnabled, isFalse);
    });

    test('disables the sweeper', () {
      expect(config.sweeperInterval, Duration.zero);
    });

    test('removes the stagger', () {
      expect(config.staggerClearMs, 0);
    });

    test('uses a disabled TTL policy', () {
      expect(config.ttlPolicy.ttlFor('users/123'), isNull);
      expect(config.ttlPolicy.ttlFor('guild/1/members/2'), isNull);
    });
  });

  group('CacheConfig with explicit values', () {
    test('honors a custom TTL policy', () {
      final policy = CacheTtlPolicy.disabled().override({
        'users/': const Duration(seconds: 10),
      });
      final config = CacheConfig(ttlPolicy: policy);

      expect(config.ttlPolicy.ttlFor('users/1'), const Duration(seconds: 10));
    });

    test('falls back to defaults when ttlPolicy is null', () {
      const config = CacheConfig();

      expect(config.ttlPolicy.ttlFor('users/1'), const Duration(hours: 1));
    });
  });
}
