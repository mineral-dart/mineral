import 'package:mineral/src/domains/container/ioc_container.dart';
import 'package:mineral/src/domains/services/cache/cache_config.dart';
import 'package:mineral/src/domains/services/cache/cache_provider_contract.dart';

/// Removes [key] from the cache when automatic invalidation is enabled.
///
/// Resolves [CacheConfig] via the IoC container and short-circuits when
/// `invalidationEnabled` is false (e.g. `CacheConfig.legacy()`). When no
/// `CacheConfig` is bound — typical for older tests — defaults to `true` so
/// existing behavior is preserved.
extension CacheInvalidation on CacheProviderContract? {
  Future<void> invalidate(String key) async {
    final cache = this;
    if (cache == null) {
      return;
    }

    final enabled =
        ioc.resolveOrNull<CacheConfig>()?.invalidationEnabled ?? true;
    if (!enabled) {
      return;
    }

    await cache.remove(key);
  }
}
