import 'dart:async';

import 'package:mineral/contracts.dart';

/// An in-memory [CacheProviderContract] for use in tests.
///
/// All data is stored in [store] — tests can read it directly to assert on
/// what was cached, or pre-populate it before calling the system under test.
final class FakeCacheProvider implements CacheProviderContract {
  final Map<String, dynamic> store = {};

  @override
  String get name => 'fake';

  @override
  CacheConfig config = CacheConfig.defaults();

  @override
  FutureOr<void> init() {}

  @override
  FutureOr<int> length() => store.length;

  @override
  FutureOr<Map<String, dynamic>> inspect() => store;

  @override
  FutureOr<Map<String, dynamic>?> get(String? key) =>
      key != null ? store[key] as Map<String, dynamic>? : null;

  @override
  FutureOr<List<Map<String, dynamic>?>> getMany(List<String> keys) =>
      keys.map((k) => store[k] as Map<String, dynamic>?).toList();

  @override
  FutureOr<Map<String, dynamic>> getOrFail(
    String key, {
    Exception Function()? onFail,
  }) =>
      store[key] as Map<String, dynamic>? ??
      (throw (onFail?.call() ?? Exception('Key $key not found')));

  @override
  FutureOr<Map<String, dynamic>?> whereKeyStartsWith(String prefix) => store
      .entries
      .where((e) => e.key.startsWith(prefix))
      .map((e) => e.value as Map<String, dynamic>)
      .firstOrNull;

  @override
  FutureOr<Map<String, dynamic>> whereKeyStartsWithOrFail(
    String prefix, {
    Exception Function()? onFail,
  }) =>
      whereKeyStartsWith(prefix) as Map<String, dynamic>? ??
      (throw (onFail?.call() ?? Exception('Prefix $prefix not found')));

  @override
  FutureOr<bool> has(String key) => store.containsKey(key);

  @override
  FutureOr<void> put<T>(String key, T object, {Duration? ttl}) =>
      store[key] = object;

  @override
  FutureOr<void> putMany<T>(Map<String, T> object, {Duration? ttl}) {
    store.addAll(object);
  }

  @override
  FutureOr<void> remove(String key) {
    store.remove(key);
  }

  @override
  FutureOr<void> removeMany(List<String> keys) {
    for (final k in keys) {
      store.remove(k);
    }
  }

  @override
  FutureOr<void> clear() {
    store.clear();
  }

  @override
  FutureOr<void> dispose() {
    store.clear();
  }

  @override
  FutureOr<bool> getHealth() => true;
}
