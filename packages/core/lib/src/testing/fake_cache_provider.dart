import 'dart:async';
import 'dart:convert';

import 'package:mineral/contracts.dart';

/// An in-memory [CacheProviderContract] for use in tests.
///
/// Mirrors `MemoryProvider` semantics: values are deep-copied on write and
/// read, TTLs expire lazily, and [whereKeyStartsWith] returns a key→value
/// map. [store] exposes the live values for assertions and pre-population.
final class FakeCacheProvider implements CacheProviderContract {
  final Map<String, dynamic> _values = {};
  final Map<String, DateTime> _expiries = {};

  Map<String, dynamic> get store {
    _purgeExpired();
    return _values;
  }

  @override
  String get name => 'fake';

  @override
  CacheConfig config = CacheConfig.defaults();

  @override
  FutureOr<void> init() {}

  @override
  FutureOr<int> length() => store.length;

  @override
  FutureOr<Map<String, dynamic>> inspect() => Map.of(store);

  @override
  FutureOr<Map<String, dynamic>?> get(String? key) {
    if (key == null) {
      return null;
    }
    _purgeExpired();
    final value = _values[key];
    if (value == null) {
      return null;
    }
    return _deepCopy(value) as Map<String, dynamic>?;
  }

  @override
  FutureOr<List<Map<String, dynamic>?>> getMany(List<String> keys) =>
      keys.map((k) => get(k) as Map<String, dynamic>?).toList();

  @override
  FutureOr<Map<String, dynamic>> getOrFail(
    String key, {
    Exception Function()? onFail,
  }) =>
      get(key) as Map<String, dynamic>? ??
      (throw (onFail?.call() ?? Exception('Key $key not found')));

  @override
  FutureOr<Map<String, dynamic>> whereKeyStartsWith(String prefix) {
    _purgeExpired();
    return {
      for (final entry in _values.entries)
        if (entry.key.startsWith(prefix)) entry.key: entry.value,
    };
  }

  @override
  FutureOr<Map<String, dynamic>> whereKeyStartsWithOrFail(
    String prefix, {
    Exception Function()? onFail,
  }) {
    final entries = whereKeyStartsWith(prefix) as Map<String, dynamic>;
    if (entries.isEmpty) {
      throw onFail != null ? onFail() : Exception('No keys found');
    }
    return entries;
  }

  @override
  FutureOr<bool> has(String key) {
    _purgeExpired();
    return _values.containsKey(key);
  }

  @override
  FutureOr<void> put<T>(String key, T object, {Duration? ttl}) {
    _write(key, object, ttl);
  }

  @override
  FutureOr<void> putMany<T>(Map<String, T> object, {Duration? ttl}) {
    for (final entry in object.entries) {
      _write(entry.key, entry.value, ttl);
    }
  }

  @override
  FutureOr<void> remove(String key) {
    _values.remove(key);
    _expiries.remove(key);
  }

  @override
  FutureOr<void> removeMany(List<String> keys) {
    for (final k in keys) {
      remove(k);
    }
  }

  @override
  FutureOr<void> clear() {
    _values.clear();
    _expiries.clear();
  }

  @override
  FutureOr<void> dispose() {
    clear();
  }

  @override
  FutureOr<bool> getHealth() => true;

  void _write(String key, dynamic object, Duration? ttl) {
    final effectiveTtl = ttl ?? config.ttlPolicy.ttlFor(key);
    _values[key] = _deepCopy(object);
    if (effectiveTtl == null || effectiveTtl <= Duration.zero) {
      _expiries.remove(key);
    } else {
      _expiries[key] = DateTime.now().add(effectiveTtl);
    }
  }

  void _purgeExpired() {
    if (_expiries.isEmpty) {
      return;
    }
    final now = DateTime.now();
    final expired = [
      for (final e in _expiries.entries)
        if (now.isAfter(e.value)) e.key,
    ];
    for (final key in expired) {
      _values.remove(key);
      _expiries.remove(key);
    }
  }

  static dynamic _deepCopy(dynamic value) => jsonDecode(jsonEncode(value));
}
