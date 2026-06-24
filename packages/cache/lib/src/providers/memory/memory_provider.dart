import 'dart:async';
import 'dart:convert';

import 'package:mineral/api.dart';
import 'package:mineral/container.dart';
import 'package:mineral/contracts.dart';

final class MemoryProvider implements CacheProviderContract {
  final Map<String, _Entry> _storage = {};
  Timer? _sweeper;

  LoggerContract get logger => ioc.resolve<LoggerContract>();

  CacheTtlPolicy get _ttlPolicy =>
      ioc.resolveOrNull<CacheConfig>()?.ttlPolicy ??
      CacheTtlPolicy.disabled();

  Duration get _sweeperInterval =>
      ioc.resolveOrNull<CacheConfig>()?.sweeperInterval ?? Duration.zero;

  MemoryProvider(Env env);

  @override
  void init() {
    logger.trace(jsonEncode({
      'service': 'cache',
      'message': 'memory is used',
      'payload': {},
    }));

    if (_sweeperInterval > Duration.zero) {
      _sweeper = Timer.periodic(_sweeperInterval, (_) => _sweepExpired());
    }
  }

  @override
  String get name => 'In memory provider';

  @override
  int length() {
    _sweepExpired();
    return _storage.length;
  }

  @override
  Map<String, dynamic> inspect() {
    _sweepExpired();
    return {
      for (final entry in _storage.entries) entry.key: entry.value.value,
    };
  }

  @override
  Map<String, dynamic> whereKeyStartsWith(String prefix) {
    final result = <String, dynamic>{};
    for (final entry in _storage.entries) {
      if (!entry.key.startsWith(prefix)) {
        continue;
      }
      if (entry.value.isExpired) {
        continue;
      }
      result[entry.key] = entry.value.value;
    }
    return result;
  }

  @override
  Map<String, dynamic> whereKeyStartsWithOrFail(String prefix,
      {Exception Function()? onFail}) {
    final entries = whereKeyStartsWith(prefix);

    return entries.isEmpty
        ? onFail != null
            ? throw onFail()
            : throw Exception('No keys found')
        : entries;
  }

  @override
  Map<String, dynamic>? get(String? key) {
    if (key == null) {
      return null;
    }
    final entry = _storage[key];
    if (entry == null) {
      return null;
    }
    if (entry.isExpired) {
      _storage.remove(key);
      return null;
    }
    return _deepCopy(entry.value) as Map<String, dynamic>?;
  }

  @override
  List<Map<String, dynamic>?> getMany(List<String> keys) {
    return keys.map(get).toList();
  }

  @override
  Map<String, dynamic> getOrFail(String key, {Exception Function()? onFail}) {
    final value = get(key);
    if (value == null) {
      if (onFail case Function()) {
        throw onFail!();
      }

      throw Exception('Key $key not found');
    }
    return value;
  }

  @override
  bool has(String key) {
    final entry = _storage[key];
    if (entry == null) {
      return false;
    }
    if (entry.isExpired) {
      _storage.remove(key);
      return false;
    }
    return true;
  }

  @override
  void put<T>(String key, T object, {Duration? ttl}) {
    final effectiveTtl = ttl ?? _ttlPolicy.ttlFor(key);
    _storage[key] = _Entry(_deepCopy(object), effectiveTtl);
  }

  @override
  void putMany<T>(Map<String, T> objects, {Duration? ttl}) {
    for (final entry in objects.entries) {
      final effectiveTtl = ttl ?? _ttlPolicy.ttlFor(entry.key);
      _storage[entry.key] = _Entry(_deepCopy(entry.value), effectiveTtl);
    }
  }

  /// Returns a structural deep copy of [value] via a JSON round-trip.
  ///
  /// The marshaller normalises all entities to `Map<String, dynamic>` before
  /// caching, so the stored values are always JSON-encodable.  The round-trip
  /// matches Redis's serialisation semantics: after `put`, the caller cannot
  /// mutate the cached entry by modifying the original object.
  static dynamic _deepCopy(dynamic value) =>
      jsonDecode(jsonEncode(value));

  @override
  void remove(String key) => _storage.remove(key);

  @override
  void removeMany(List<String> keys) {
    for (final key in keys) {
      _storage.remove(key);
    }
  }

  @override
  void clear() => _storage.clear();

  @override
  bool getHealth() => true;

  @override
  void dispose() {
    _sweeper?.cancel();
    _sweeper = null;
    _storage.clear();
  }

  void _sweepExpired() {
    _storage.removeWhere((_, entry) => entry.isExpired);
  }
}

final class _Entry {
  _Entry(this.value, Duration? ttl)
      // Duration.zero is treated as "no expiry", matching Redis semantics
      // where buildSetCommand omits PX for non-positive durations.
      : expiresAt = (ttl == null || ttl <= Duration.zero)
            ? null
            : DateTime.now().add(ttl);

  final dynamic value;
  final DateTime? expiresAt;

  bool get isExpired {
    final at = expiresAt;
    return at != null && DateTime.now().isAfter(at);
  }
}
