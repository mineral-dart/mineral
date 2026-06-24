import 'package:mineral/src/domains/services/cache/cache_config.dart';
import 'package:mineral/src/domains/services/cache/cache_invalidation.dart';
import 'package:mineral/src/domains/services/cache/cache_provider_contract.dart';
import 'package:mineral/src/testing/fake_cache_provider.dart';
import 'package:test/test.dart';

void main() {
  group('CacheInvalidation.invalidate', () {
    test(
      'removes the key when invalidationEnabled is true (defaults)',
      () async {
        final cache = FakeCacheProvider()
          ..store['users/1'] = {'id': '1'}
          ..config = CacheConfig.defaults();

        final CacheProviderContract nullable = cache;
        await nullable.invalidate('users/1');

        expect(cache.store.containsKey('users/1'), isFalse);
      },
    );

    test('keeps the key when invalidationEnabled is false (legacy)', () async {
      final cache = FakeCacheProvider()
        ..store['users/1'] = {'id': '1'}
        ..config = CacheConfig.legacy();

      final CacheProviderContract nullable = cache;
      await nullable.invalidate('users/1');

      expect(cache.store['users/1'], {'id': '1'});
    });

    test(
      'keeps the key when invalidationEnabled is false (disabled config)',
      () async {
        final cache = FakeCacheProvider()
          ..store['users/1'] = {'id': '1'}
          ..config = const CacheConfig(invalidationEnabled: false);

        final CacheProviderContract nullable = cache;
        await nullable.invalidate('users/1');

        expect(cache.store['users/1'], {'id': '1'});
      },
    );

    test(
      'removes the key when invalidationEnabled is true (explicit config)',
      () async {
        final cache = FakeCacheProvider()
          ..store['users/2'] = {'id': '2'}
          ..config = const CacheConfig(invalidationEnabled: true);

        final CacheProviderContract nullable = cache;
        await nullable.invalidate('users/2');

        expect(cache.store.containsKey('users/2'), isFalse);
      },
    );

    test('is a no-op when the cache is null', () async {
      const CacheProviderContract? nullable = null;
      // Must not throw — null-safe extension guard.
      await nullable.invalidate('users/1');
    });

    test('no IoC binding is required for invalidation to work', () async {
      // This test intentionally runs WITHOUT any IoC container or CacheConfig
      // bound in a container. The provider carries its own config, so this
      // must work without ioc.resolveOrNull<CacheConfig>().
      final cache = FakeCacheProvider()..store['k'] = {'v': 1};
      // config defaults to CacheConfig.defaults() → invalidationEnabled=true
      final CacheProviderContract nullable = cache;
      await nullable.invalidate('k');
      expect(cache.store.containsKey('k'), isFalse);
    });
  });
}
