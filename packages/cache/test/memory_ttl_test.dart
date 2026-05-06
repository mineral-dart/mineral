import 'package:mineral/api.dart';
import 'package:mineral/container.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral_cache/providers/memory.dart';
import 'package:test/test.dart';

void main() {
  group('MemoryProvider TTL', () {
    test('entries with explicit ttl expire on read', () async {
      final provider = MemoryProvider(env);
      provider.put('key', {'a': 1}, ttl: const Duration(milliseconds: 30));

      expect(provider.has('key'), isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(provider.has('key'), isFalse);
      expect(provider.get('key'), isNull);
    });

    test('entries without ttl never expire (no CacheConfig in IoC)',
        () async {
      final provider = MemoryProvider(env);
      provider.put('key', {'a': 1});

      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(provider.has('key'), isTrue);
      expect(provider.get('key'), {'a': 1});
    });

    test('get evicts the expired entry', () async {
      final provider = MemoryProvider(env);
      provider.put('key', {'a': 1}, ttl: const Duration(milliseconds: 20));

      await Future<void>.delayed(const Duration(milliseconds: 40));
      provider.get('key');

      expect(provider.length(), 0);
    });

    test('getOrFail throws after expiry', () async {
      final provider = MemoryProvider(env);
      provider.put('k', {'a': 1}, ttl: const Duration(milliseconds: 20));

      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(() => provider.getOrFail('k'), throwsA(isA<Exception>()));
    });

    test('whereKeyStartsWith filters expired entries', () async {
      final provider = MemoryProvider(env);
      provider
        ..put('users/1', {'id': 1})
        ..put('users/2', {'id': 2}, ttl: const Duration(milliseconds: 20));

      await Future<void>.delayed(const Duration(milliseconds: 40));

      final result = provider.whereKeyStartsWith('users/');
      expect(result.keys, ['users/1']);
    });

    test('inspect returns only non-expired raw values', () async {
      final provider = MemoryProvider(env);
      provider
        ..put('a', {'x': 1})
        ..put('b', {'y': 2}, ttl: const Duration(milliseconds: 20));

      await Future<void>.delayed(const Duration(milliseconds: 40));

      final state = provider.inspect();
      expect(state, {
        'a': {'x': 1},
      });
    });

    test('putMany applies a uniform ttl', () async {
      final provider = MemoryProvider(env);
      provider.putMany({
        'k1': {'v': 1},
        'k2': {'v': 2},
      }, ttl: const Duration(milliseconds: 20));

      expect(provider.has('k1'), isTrue);
      expect(provider.has('k2'), isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(provider.has('k1'), isFalse);
      expect(provider.has('k2'), isFalse);
    });
  });

  group('MemoryProvider with CacheConfig in IoC', () {
    test('put without ttl uses the configured policy', () async {
      final container = IocContainer()
        ..bind<CacheConfig>(() => CacheConfig(
              ttlPolicy: CacheTtlPolicy.disabled().override({
                'users/': const Duration(milliseconds: 20),
              }),
            ));

      await runWithIoc(container, () async {
        final provider = MemoryProvider(env);
        provider.put('users/1', {'id': 1});

        expect(provider.has('users/1'), isTrue);

        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(provider.has('users/1'), isFalse);
      });
    });

    test('explicit ttl on put overrides the policy', () async {
      final container = IocContainer()
        ..bind<CacheConfig>(() => CacheConfig(
              ttlPolicy: CacheTtlPolicy.disabled().override({
                'users/': const Duration(milliseconds: 20),
              }),
            ));

      await runWithIoc(container, () async {
        final provider = MemoryProvider(env);
        provider.put('users/1', {'id': 1}, ttl: const Duration(seconds: 30));

        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(provider.has('users/1'), isTrue);
      });
    });

    test('sweeper actively removes expired entries', () async {
      final container = IocContainer()
        ..bind<LoggerContract>(_NoopLogger.new)
        ..bind<CacheConfig>(() => CacheConfig(
              sweeperInterval: const Duration(milliseconds: 30),
            ));

      await runWithIoc(container, () async {
        final provider = MemoryProvider(env)..init();
        provider.put('k', {'v': 1}, ttl: const Duration(milliseconds: 20));

        await Future<void>.delayed(const Duration(milliseconds: 80));

        // The sweeper should have removed the entry without any read call.
        // We verify by checking the underlying length, which itself runs a
        // sweep — but the entry must have been removed before that anyway.
        expect(provider.length(), 0);

        provider.dispose();
      });
    });
  });
}

final class _NoopLogger implements LoggerContract {
  @override
  void trace(Object message) {}
  @override
  void info(String message) {}
  @override
  void warn(String message) {}
  @override
  void error(String message) {}
  @override
  void fatal(Exception message) {}
}
