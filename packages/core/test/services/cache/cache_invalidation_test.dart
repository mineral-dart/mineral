import 'package:mineral/src/domains/container/ioc_container.dart';
import 'package:mineral/src/domains/services/cache/cache_config.dart';
import 'package:mineral/src/domains/services/cache/cache_invalidation.dart';
import 'package:mineral/src/domains/services/cache/cache_provider_contract.dart';
import 'package:mineral/src/testing/fake_cache_provider.dart';
import 'package:test/test.dart';

void main() {
  group('CacheInvalidation.invalidate', () {
    test('removes the key when invalidationEnabled is true', () async {
      final cache = FakeCacheProvider()..store['users/1'] = {'id': '1'};
      final container = IocContainer()
        ..bind<CacheConfig>(() => CacheConfig.defaults());

      await runWithIoc(container, () async {
        final CacheProviderContract? nullable = cache;
        await nullable.invalidate('users/1');
      });

      expect(cache.store.containsKey('users/1'), isFalse);
    });

    test('keeps the key when invalidationEnabled is false', () async {
      final cache = FakeCacheProvider()..store['users/1'] = {'id': '1'};
      final container = IocContainer()
        ..bind<CacheConfig>(() => CacheConfig.legacy());

      await runWithIoc(container, () async {
        final CacheProviderContract? nullable = cache;
        await nullable.invalidate('users/1');
      });

      expect(cache.store['users/1'], {'id': '1'});
    });

    test('defaults to enabled when no CacheConfig is bound', () async {
      final cache = FakeCacheProvider()..store['users/1'] = {'id': '1'};
      final container = IocContainer();

      await runWithIoc(container, () async {
        final CacheProviderContract? nullable = cache;
        await nullable.invalidate('users/1');
      });

      expect(cache.store.containsKey('users/1'), isFalse);
    });

    test('is a no-op when the cache is null', () async {
      final container = IocContainer()
        ..bind<CacheConfig>(() => CacheConfig.defaults());

      await runWithIoc(container, () async {
        const CacheProviderContract? nullable = null;
        await nullable.invalidate('users/1');
      });
    });
  });
}
