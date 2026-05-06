import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mineral/api.dart';
import 'package:mineral/container.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral_cache/src/providers/redis/redis_commands.dart';
import 'package:mineral_cache/src/providers/redis/redis_env_keys.dart';
import 'package:mineral_cache/src/providers/redis/redis_settings.dart';
import 'package:redis/redis.dart';

final class RedisProvider implements CacheProviderContract {
  final RedisConnection _connection = RedisConnection();

  late final RedisSettings settings;

  String? _password;

  LoggerContract get logger => ioc.resolve<LoggerContract>();

  CacheTtlPolicy get _ttlPolicy =>
      ioc.resolveOrNull<CacheConfig>()?.ttlPolicy ??
      CacheTtlPolicy.disabled();

  RedisProvider({required String host, required int port, String? password})
      : _password = password {
    settings = RedisSettings(host, port, hasPassword: password != null);
  }

  @override
  String get name => 'RedisProvider';

  @override
  Future<void> init() async {
    try {
      await _connection.connect(settings.host, settings.port);

      if (_password != null) {
        await Command(_connection).send_object(['AUTH', _password!]);
        _password = null;
      }

      final Map<String, dynamic> credentials = {
        'service': 'cache',
        'message': 'redis is connected',
        'payload': {
          'host': settings.host,
          'port': settings.port,
          'password': settings.hasPassword ? 'REDACTED' : 'NO PASSWORD',
        },
      };

      logger.trace(jsonEncode(credentials));
    } on SocketException catch (error) {
      logger.fatal(error);
      throw Exception('$name - ${error.message}');
    }
  }

  @override
  Future<int> length() async {
    final value = await Command(_connection).send_object(['SCAN', 0]);
    return switch (value) {
      List() => value.length,
      String() => int.parse(value),
      _ => value,
    };
  }

  /// Scans all keys in the current database using the non-blocking SCAN command.
  Future<List<dynamic>> _scanKeys({String match = '*'}) async {
    final keys = <dynamic>[];
    var cursor = '0';
    do {
      final result = await Command(_connection)
          .send_object(['SCAN', cursor, 'MATCH', match, 'COUNT', 100]);
      cursor = (result as List)[0].toString();
      keys.addAll(result[1] as List);
    } while (cursor != '0');
    return keys;
  }

  /// Escapes Redis glob special characters in a prefix to avoid unintended matches.
  String _escapeGlob(String prefix) => prefix
      .replaceAll('\\', '\\\\')
      .replaceAll('*', '\\*')
      .replaceAll('?', '\\?')
      .replaceAll('[', '\\[');

  @override
  Future<Map<String, dynamic>> inspect() async {
    final keys = await _scanKeys();
    if (keys.isEmpty) return {};
    final values = await Command(_connection).send_object(['MGET', ...keys]);

    return Map.fromIterables(
        keys.map((k) => k.toString()),
        (values as List).map((e) => jsonDecode(e as String)));
  }

  @override
  Future<Map<String, dynamic>> whereKeyStartsWith(String prefix) async {
    final keys = await _scanKeys(match: '${_escapeGlob(prefix)}*');
    if (keys.isEmpty) return {};

    final List values =
        await Command(_connection).send_object(['MGET', ...keys]);
    final results = await List.generate(values.length, (i) async {
      return {keys[i].toString(): jsonDecode(values[i] as String)};
    }).wait;

    final Map<String, dynamic> r = {};
    for (final result in results) {
      r.addAll(result);
    }

    return r;
  }

  @override
  Future<Map<String, dynamic>> whereKeyStartsWithOrFail(String prefix,
      {Exception Function()? onFail}) async {
    final entries = await whereKeyStartsWith(prefix);

    return entries.isEmpty
        ? onFail != null
            ? throw onFail()
            : throw Exception('No entries found')
        : entries;
  }

  @override
  Future<Map<String, dynamic>?> get(String? key) async {
    final value = await Command(_connection).get(key ?? '');
    return switch (value) {
      String() => jsonDecode(value),
      _ => value,
    };
  }

  @override
  Future<List<Map<String, dynamic>?>> getMany(List<String> keys) async {
    final values = await Command(_connection).send_object(['MGET', ...keys]);
    if (values case final List values) {
      return List<Map<String, dynamic>?>.from(
          values.map((e) => e == null ? null : jsonDecode(e as String)).toList());
    }

    throw Exception('Values are not iterable');
  }

  @override
  Future<Map<String, dynamic>> getOrFail(String key,
      {Exception Function()? onFail}) async {
    final value = await get(key);
    if (value == null) {
      if (onFail case Function()) {
        throw onFail!();
      }

      throw Exception('Key $key not found');
    }

    return value;
  }

  @override
  Future<bool> has(String key) async {
    final result = await Command(_connection).send_object(['EXISTS', key]);
    return switch (result) {
      0 => false,
      _ => true,
    };
  }

  @override
  Future<void> put<T>(String key, T object, {Duration? ttl}) async {
    final effectiveTtl = ttl ?? _ttlPolicy.ttlFor(key);
    final command = buildSetCommand(key, jsonEncode(object), effectiveTtl);
    await Command(_connection).send_object(command);
  }

  @override
  Future<void> putMany<T>(Map<String, T> objects, {Duration? ttl}) async {
    // MSET cannot carry an expiration, so when any entry has a TTL we issue
    // one SET … PX per key. Without TTL we keep the single MSET round-trip.
    final keyTtls = {
      for (final key in objects.keys) key: ttl ?? _ttlPolicy.ttlFor(key),
    };
    final hasAnyTtl =
        keyTtls.values.any((d) => d != null && d > Duration.zero);

    if (!hasAnyTtl) {
      final encoded = {
        for (final entry in objects.entries) entry.key: jsonEncode(entry.value),
      };
      await Command(_connection).send_object(buildMsetCommand(encoded));
      return;
    }

    for (final entry in objects.entries) {
      await Command(_connection).send_object(
        buildSetCommand(entry.key, jsonEncode(entry.value), keyTtls[entry.key]),
      );
    }
  }

  @override
  Future<void> remove(String key) async {
    return Command(_connection).send_object(['DEL', key]);
  }

  @override
  Future<void> removeMany(List<String> keys) async {
    await Command(_connection).send_object(['DEL', ...keys]);
  }

  @override
  Future<void> clear() async {
    return Command(_connection).send_object(['FLUSHDB']);
  }

  @override
  Future<bool> getHealth() async {
    final value = await Command(_connection).send_object(['PING']);
    return value == 'PONG';
  }

  @override
  Future<void> dispose() async {
    await _connection.close();
  }

  factory RedisProvider.fromEnvironment(Env env) {
    env.defineOf(RedisEnv.new);

    return RedisProvider(
      host: env.get(RedisEnv.redisHost),
      port: env.get<int>(RedisEnv.redisPort),
      password: env.get<String?>(RedisEnv.redisPassword),
    );
  }
}
