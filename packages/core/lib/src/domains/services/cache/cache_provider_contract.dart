import 'dart:async';

abstract interface class CacheProviderContract {
  String get name;

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
  /// If [ttl] is provided, the entry expires after that duration. Providers
  /// that support expiration (e.g. memory, Redis) honor this; providers that
  /// don't may ignore it. A `null` [ttl] means "never expire".
  FutureOr<void> put<T>(String key, T object, {Duration? ttl});

  /// Stores all entries from [object]. The optional [ttl] applies uniformly
  /// to every entry; pass `null` to skip expiration.
  FutureOr<void> putMany<T>(Map<String, T> object, {Duration? ttl});

  FutureOr<void> remove(String key);

  FutureOr<void> removeMany(List<String> key);

  FutureOr<void> clear();

  FutureOr<void> dispose();

  FutureOr<bool> getHealth();
}
