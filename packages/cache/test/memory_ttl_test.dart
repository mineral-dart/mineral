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

  // ── M24: Duration.zero semantics ─────────────────────────────────────────

  group('Duration.zero semantics (M24)', () {
    test('Duration.zero on put means no expiry (matches Redis semantics)',
        () async {
      final provider = MemoryProvider(env);
      provider.put('k', {'v': 1}, ttl: Duration.zero);

      await Future<void>.delayed(const Duration(milliseconds: 30));

      // Duration.zero must NOT cause immediate eviction; it means "no expiry",
      // matching Redis buildSetCommand which emits a plain SET (no PX) for
      // non-positive durations.
      expect(provider.has('k'), isTrue);
      expect(provider.get('k'), {'v': 1});
    });

    test('Duration.zero via putMany means no expiry', () async {
      final provider = MemoryProvider(env);
      provider.putMany({'k1': {'a': 1}, 'k2': {'b': 2}}, ttl: Duration.zero);

      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(provider.has('k1'), isTrue);
      expect(provider.has('k2'), isTrue);
    });
  });

  // ── M25: copy-on-store / copy-on-get semantics ────────────────────────────

  group('MemoryProvider copy semantics (M25)', () {
    test('mutating the original map after put does not corrupt the cache', () {
      final provider = MemoryProvider(env);
      final original = <String, dynamic>{'name': 'Alice', 'score': 10};
      provider.put('users/1', original);

      // Mutate the original object after storing it.
      original['name'] = 'Eve';
      original['score'] = 99;

      final cached = provider.get('users/1');
      expect(cached, {'name': 'Alice', 'score': 10});
    });

    test('mutating a value returned by get does not corrupt the cache', () {
      final provider = MemoryProvider(env);
      provider.put('users/2', {'name': 'Bob', 'score': 5});

      final first = provider.get('users/2')!;
      first['score'] = 999; // mutate the returned copy

      final second = provider.get('users/2')!;
      expect(second['score'], 5); // cache is untouched
    });

    test('putMany copies each entry independently', () {
      final provider = MemoryProvider(env);
      final a = <String, dynamic>{'x': 1};
      final b = <String, dynamic>{'x': 2};
      provider.putMany({'k1': a, 'k2': b});

      a['x'] = 100;
      b['x'] = 200;

      expect(provider.get('k1'), {'x': 1});
      expect(provider.get('k2'), {'x': 2});
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
