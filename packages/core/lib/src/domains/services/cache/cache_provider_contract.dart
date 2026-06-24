import 'dart:async';

import 'package:mineral/src/domains/services/cache/cache_config.dart';

abstract interface class CacheProviderContract {
  String get name;

  /// The [CacheConfig] that governs this provider's TTL policy and
  /// invalidation behaviour. Assigned by [ClientBuilder] after construction.
  /// Defaults to [CacheConfig.defaults] so providers remain usable in tests
  /// without a full application wiring.
  CacheConfig get config;
  set config(CacheConfig value);

  FutureOr<void> init();

  FutureOr<int> length();

  FutureOr<Map<String, dynamic>> inspect();

  FutureOr<Map<String, dynamic>?> get(String? key);

  FutureOr<List<Map<String, dynamic>?>> getMany(List<String> keys);

  FutureOr<Map<String, dynamic>> getOrFail(String key,
      {Exception Function()? onFail});

  FutureOr<Map<String, dynamic>?> whereKeyStartsWith(String prefix);

  FutureOr<Map<String, dynamic>> whereKeyStartsWithOrFail(String prefix,
      {Exception Function()? onFail});

  FutureOr<bool> has(String key);

  /// Stores [object] under [key].
  ///
  /// [ttl] semantics (identical across all providers):
  /// - `null` — the TTL policy attached to this provider resolves the
  ///   duration from the key.  If the policy returns `null` the entry
  ///   never expires.
  /// - `Duration.zero` — treated as "no expiry" (equivalent to the policy
  ///   returning `null`).  Do **not** pass `Duration.zero` expecting
  ///   immediate eviction.
  /// - Any positive [Duration] — the entry expires after that duration.
  ///
  /// Both providers (memory and Redis) honor these semantics identically and
  /// store a structural deep copy of [object], so caller mutations after
  /// `put` cannot corrupt the cached value.
  FutureOr<void> put<T>(String key, T object, {Duration? ttl});

  /// Stores all entries from [object]. The optional [ttl] applies uniformly
  /// to every entry; pass `null` to let the TTL policy decide per key,
  /// `Duration.zero` for no expiry.
  FutureOr<void> putMany<T>(Map<String, T> object, {Duration? ttl});

  FutureOr<void> remove(String key);

  FutureOr<void> removeMany(List<String> key);

  FutureOr<void> clear();

  FutureOr<void> dispose();

  FutureOr<bool> getHealth();
}
