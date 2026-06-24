import 'dart:async';

import 'package:mineral/src/domains/providers/provider.dart';
import 'package:mineral/src/domains/providers/provider_manager.dart';
import 'package:test/test.dart';

import '../helpers/ioc_test_helper.dart';

final class _TrackingProvider implements ProviderContract {
  final String name;
  final List<String> log;

  _TrackingProvider(this.name, this.log);

  @override
  FutureOr<void> ready() {
    log.add('ready:$name');
  }

  @override
  FutureOr<void> dispose() {
    log.add('dispose:$name');
  }
}

final class _FailingReadyProvider implements ProviderContract {
  final String name;
  final List<String> log;

  _FailingReadyProvider(this.name, this.log);

  @override
  FutureOr<void> ready() {
    log.add('ready:$name');
    throw Exception('$name failed in ready');
  }

  @override
  FutureOr<void> dispose() {
    log.add('dispose:$name');
  }
}

final class _FailingDisposeProvider implements ProviderContract {
  final String name;
  final List<String> log;

  _FailingDisposeProvider(this.name, this.log);

  @override
  FutureOr<void> ready() {
    log.add('ready:$name');
  }

  @override
  FutureOr<void> dispose() {
    log.add('dispose:$name');
    throw Exception('$name failed in dispose');
  }
}

void main() {
  late ProviderManager manager;
  late void Function() restore;
  late List<String> log;

  setUp(() {
    final env = createTestIoc();
    restore = env.restore;
    manager = ProviderManager(logger: env.logger);
    log = [];
  });

  tearDown(() => restore());

  group('Registration', () {
    test('providers are called in registration order during ready()', () async {
      manager
        ..register(_TrackingProvider('A', log))
        ..register(_TrackingProvider('B', log))
        ..register(_TrackingProvider('C', log));

      await manager.ready();

      expect(log, ['ready:A', 'ready:B', 'ready:C']);
    });

    test('ready() with no providers completes without error', () async {
      await expectLater(manager.ready(), completes);
    });
  });

  group('LIFO disposal', () {
    test('providers are disposed in reverse registration order', () async {
      manager
        ..register(_TrackingProvider('A', log))
        ..register(_TrackingProvider('B', log))
        ..register(_TrackingProvider('C', log));

      await manager.dispose();

      expect(log, ['dispose:C', 'dispose:B', 'dispose:A']);
    });

    test('dispose() with no providers completes without error', () async {
      await expectLater(manager.dispose(), completes);
    });
  });

  group('Ready failure', () {
    test(
      'error propagates and subsequent providers are not initialized',
      () async {
        manager
          ..register(_TrackingProvider('A', log))
          ..register(_FailingReadyProvider('B', log))
          ..register(_TrackingProvider('C', log));

        await expectLater(
          manager.ready(),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('B failed in ready'),
            ),
          ),
        );

        expect(log, ['ready:A', 'ready:B']);
        expect(log, isNot(contains('ready:C')));
      },
    );

    test('logger records the error', () async {
      final env = createTestIoc();
      addTearDown(env.restore);

      final localManager = ProviderManager(logger: env.logger)
        ..register(_FailingReadyProvider('X', log));

      try {
        await localManager.ready();
      } on Exception catch (_) {}

      expect(env.logger.errors, isNotEmpty);
      expect(env.logger.errors.first, contains('X'));
      expect(env.logger.errors.first, contains('failed to initialize'));
    });
  });

  group('Dispose failure', () {
    test('error is caught and other providers are still disposed', () async {
      manager
        ..register(_TrackingProvider('A', log))
        ..register(_FailingDisposeProvider('B', log))
        ..register(_TrackingProvider('C', log));

      await manager.dispose();

      expect(log, ['dispose:C', 'dispose:B', 'dispose:A']);
    });

    test('logger records the dispose error', () async {
      final env = createTestIoc();
      addTearDown(env.restore);

      final localManager = ProviderManager(logger: env.logger)
        ..register(_FailingDisposeProvider('X', log));

      await localManager.dispose();

      expect(env.logger.errors, isNotEmpty);
      expect(env.logger.errors.first, contains('X'));
      expect(env.logger.errors.first, contains('failed to dispose'));
    });
  });
}
