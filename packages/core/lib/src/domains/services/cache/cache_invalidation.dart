import 'package:mineral/src/domains/services/cache/cache_provider_contract.dart';

/// Removes [key] from the cache when automatic invalidation is enabled.
///
/// Reads [CacheConfig.invalidationEnabled] directly from the provider's own
/// [CacheProviderContract.config] — no IoC look-up required. When the
/// provider carries [CacheConfig.defaults] (the default), invalidation is
/// enabled. Pass a provider configured with [CacheConfig.legacy] (or any
/// config whose [CacheConfig.invalidationEnabled] is `false`) to suppress it.
extension CacheInvalidation on CacheProviderContract? {
  Future<void> invalidate(String key) async {
    final cache = this;
    if (cache == null) {
      return;
    }

    if (!cache.config.invalidationEnabled) {
      return;
    }

    await cache.remove(key);
  }
}
