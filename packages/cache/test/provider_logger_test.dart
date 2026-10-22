import 'package:mineral/api.dart';
import 'package:mineral/container.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/mineral_testing.dart';
import 'package:mineral_cache/providers/memory.dart';
import 'package:mineral_cache/providers/redis.dart';
import 'package:test/test.dart';

void main() {
  group('MemoryProvider logger', () {
    test('init does not throw without any ioc binding', () {
      final provider = MemoryProvider(Env());
      expect(provider.init, returnsNormally);
      provider.dispose();
    });

    test('uses the injected logger', () {
      final logger = FakeLogger();
      final provider = MemoryProvider(Env(), logger: logger)..init();
      expect(logger.traces, hasLength(1));
      provider.dispose();
    });

    test('resolves the ioc logger once and reuses it', () async {
      await runWithIoc(IocContainer(), () async {
        final first = FakeLogger();
        ioc.bind<LoggerContract>(() => first);
        final provider = MemoryProvider(Env());
        expect(provider.logger, same(first));
        ioc.bind<LoggerContract>(() => FakeLogger());
        expect(provider.logger, same(first));
      });
    });
  });

  group('RedisProvider', () {
    test('logger falls back silently without any ioc binding', () {
      final provider = RedisProvider(host: 'h', port: 1);
      expect(() => provider.logger.trace('x'), returnsNormally);
    });

    test('tls defaults to false and is carried into settings', () {
      expect(RedisProvider(host: 'h', port: 1).settings.tls, isFalse);
      expect(RedisProvider(host: 'h', port: 1, tls: true).settings.tls, isTrue);
    });
  });

  group('REDIS_TLS', () {
    final base = {'REDIS_HOST': 'h', 'REDIS_PORT': 6379, 'REDIS_PASSWORD': 'p'};

    test('is parsed as a boolean', () {
      final out = Env().validate(RedisEnv().schema, {
        ...base,
        'REDIS_TLS': 'true',
      });
      expect(RedisEnv.redisTls, 'REDIS_TLS');
      expect(out['REDIS_TLS'], isTrue);
    });

    test('is optional', () {
      final out = Env().validate(RedisEnv().schema, base);
      expect(out['REDIS_TLS'], isNot(isA<bool>()));
    });
  });
}
