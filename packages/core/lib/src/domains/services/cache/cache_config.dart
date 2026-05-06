import 'package:mineral/src/domains/services/cache/cache_ttl_policy.dart';

/// Runtime configuration for the cache layer.
///
/// `CacheConfig.defaults()` enables TTL eviction and Discord-event driven
/// invalidation. `CacheConfig.legacy()` reproduces the pre-v5 behavior where
/// entries never expire and no automatic invalidation runs.
final class CacheConfig {
  const CacheConfig({
    CacheTtlPolicy? ttlPolicy,
    this.clearOnReady = true,
    this.invalidationEnabled = true,
    this.sweeperInterval = const Duration(minutes: 1),
    this.staggerClearMs = 500,
  }) : _ttlPolicy = ttlPolicy;

  /// Default configuration (TTL active, invalidation listener enabled).
  factory CacheConfig.defaults() => const CacheConfig();

  /// Pre-v5 configuration: cache grows unbounded, no automatic invalidation.
  factory CacheConfig.legacy() => CacheConfig(
        ttlPolicy: CacheTtlPolicy.disabled(),
        clearOnReady: false,
        invalidationEnabled: false,
        sweeperInterval: Duration.zero,
        staggerClearMs: 0,
      );

  final CacheTtlPolicy? _ttlPolicy;

  /// Whether to clear the cache when the gateway emits `READY`.
  final bool clearOnReady;

  /// Whether the cache invalidation listener is registered automatically.
  final bool invalidationEnabled;

  /// Frequency of the in-memory sweeper. `Duration.zero` disables it.
  final Duration sweeperInterval;

  /// Maximum random delay (ms) added before [clearOnReady] runs, to avoid
  /// stampedes when several shards reconnect simultaneously.
  final int staggerClearMs;

  /// TTL policy applied by cache providers when storing entries.
  CacheTtlPolicy get ttlPolicy => _ttlPolicy ?? CacheTtlPolicy.defaults();
}
