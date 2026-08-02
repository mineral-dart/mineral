import 'dart:async';

import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/testing/fake_logger.dart';
import 'package:test/test.dart';

// ── Minimal context fakes ────────────────────────────────────────────────
//
// `dispatch()` only casts and forwards these; none of their members are
// read, so every getter beyond `customId` can safely be a stub.

final class _FakeButtonContext implements ButtonContext {
  @override
  final String customId;
  _FakeButtonContext(this.customId);

  @override
  Snowflake get id => throw UnimplementedError();
  @override
  Snowflake get applicationId => throw UnimplementedError();
  @override
  String get token => 'token';
  @override
  int get version => 1;
  @override
  InteractionContract get interaction => throw UnimplementedError();
}

final class _FakeModalContext implements ModalContext {
  @override
  final String customId;
  _FakeModalContext(this.customId);

  @override
  Snowflake get id => throw UnimplementedError();
  @override
  Snowflake get applicationId => throw UnimplementedError();
  @override
  String get token => 'token';
  @override
  int get version => 1;
  @override
  InteractionContract get interaction => throw UnimplementedError();
}

final class _FakeSelectContext implements SelectContext {
  @override
  final String customId;
  _FakeSelectContext(this.customId);

  @override
  Snowflake get id => throw UnimplementedError();
  @override
  Snowflake get applicationId => throw UnimplementedError();
  @override
  String get token => 'token';
  @override
  int get version => 1;
  @override
  InteractionContract get interaction => throw UnimplementedError();
}

// ── Component fakes ──────────────────────────────────────────────────────
//
// `handle` is driven by an injected `FutureOr<void> Function()` so each test
// can pick the exact failure shape: returning normally, throwing
// synchronously, or returning a Future that rejects.

final class _ScriptedButton implements InteractiveButton {
  @override
  final String customId;
  final FutureOr<void> Function(ButtonContext ctx) onHandle;
  ButtonContext? received;

  _ScriptedButton(this.customId, this.onHandle);

  @override
  Button build() => throw UnimplementedError();

  @override
  FutureOr<void> handle(ButtonContext ctx) {
    received = ctx;
    return onHandle(ctx);
  }
}

final class _ScriptedModal implements InteractiveModal<String> {
  @override
  final String customId;
  final FutureOr<void> Function(ModalContext ctx, String values) onHandle;

  _ScriptedModal(this.customId, this.onHandle);

  @override
  ModalBuilder build() => throw UnimplementedError();

  @override
  FutureOr<void> handle(ModalContext ctx, String values) =>
      onHandle(ctx, values);
}

final class _ScriptedSelectMenu implements InteractiveSelectMenu<List<String>> {
  @override
  final String customId;
  final FutureOr<void> Function(SelectContext ctx, List<String> values)
  onHandle;

  _ScriptedSelectMenu(this.customId, this.onHandle);

  @override
  SelectMenu<List<String>> build() => throw UnimplementedError();

  @override
  FutureOr<void> handle(SelectContext ctx, List<String> values) =>
      onHandle(ctx, values);
}

void main() {
  group('InteractiveComponentManager.dispatch', () {
    late FakeLogger logger;
    late InteractiveComponentManager manager;

    setUp(() {
      logger = FakeLogger();
      manager = InteractiveComponentManager(logger: logger);
    });

    test('dispatch() returns a Future<void>', () {
      final button = _ScriptedButton('btn', (_) {});
      manager.register(button);

      final result = manager.dispatch('btn', [_FakeButtonContext('btn')]);

      expect(result, isA<Future<void>>());
    });

    test('unknown customId is a no-op and does not throw', () async {
      await expectLater(
        manager.dispatch('missing', [_FakeButtonContext('missing')]),
        completes,
      );
    });

    test(
      'invokes a successful button handler with the given context',
      () async {
        final button = _ScriptedButton('btn-ok', (_) {});
        manager.register(button);

        final ctx = _FakeButtonContext('btn-ok');
        await manager.dispatch('btn-ok', [ctx]);

        expect(button.received, same(ctx));
        expect(logger.errors, isEmpty);
      },
    );

    group('button — synchronous throw', () {
      test('is caught, logged, and does not propagate', () async {
        Object? capturedError;
        InteractiveComponent? capturedComponent;

        final button = _ScriptedButton('btn-sync', (_) {
          throw Exception('synchronous button failure');
        });
        manager
          ..onComponentError = (component, error, stackTrace) {
            capturedComponent = component;
            capturedError = error;
          }
          ..register(button);

        await expectLater(
          manager.dispatch('btn-sync', [_FakeButtonContext('btn-sync')]),
          completes,
        );

        expect(capturedComponent, same(button));
        expect(capturedError, isA<Exception>());
        expect(
          logger.errors,
          contains(contains('Failed to dispatch component "btn-sync"')),
        );
      });
    });

    group('button — asynchronous (Future) rejection', () {
      // This is the shape that actually kills the process today: the
      // handler is declared `async`, so it never throws synchronously to
      // its caller — it always returns a Future, which then rejects on a
      // later microtask. A test that only covers the synchronous-throw case
      // would pass even against the pre-fix `dispatch()`, because a plain
      // (non-async) `dispatch()` propagates a synchronous throw normally;
      // it is only the un-awaited *rejected Future* that becomes an
      // unhandled async error with no zone to catch it.
      test('is caught, logged, and does not propagate', () async {
        Object? capturedError;
        InteractiveComponent? capturedComponent;

        final button = _ScriptedButton('btn-async', (_) async {
          await Future<void>.delayed(Duration.zero);
          throw Exception('asynchronous button failure');
        });
        manager
          ..onComponentError = (component, error, stackTrace) {
            capturedComponent = component;
            capturedError = error;
          }
          ..register(button);

        await expectLater(
          manager.dispatch('btn-async', [_FakeButtonContext('btn-async')]),
          completes,
        );

        expect(capturedComponent, same(button));
        expect(capturedError, isA<Exception>());
        expect(
          logger.errors,
          contains(contains('Failed to dispatch component "btn-async"')),
        );
      });

      test('never reaches the zone as an unhandled error', () async {
        Object? escapedToZone;

        final button = _ScriptedButton('btn-zone', (_) async {
          await Future<void>.delayed(Duration.zero);
          throw Exception('this must stay inside dispatch()');
        });
        manager.register(button);

        await runZonedGuarded(() async {
          await manager.dispatch('btn-zone', [_FakeButtonContext('btn-zone')]);
          // Give any stray, un-awaited microtask a chance to surface before
          // the zone guard is torn down.
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }, (error, stackTrace) => escapedToZone = error);

        expect(
          escapedToZone,
          isNull,
          reason:
              'a rejected handler Future escaped dispatch() uncaught — this '
              'is exactly the path that terminates the process outside a '
              'guarded zone',
        );
      });
    });

    group('modal — synchronous throw', () {
      test('is caught, logged, and does not propagate', () async {
        Object? capturedError;

        final modal = _ScriptedModal('modal-sync', (_, _) {
          throw Exception('synchronous modal failure');
        });
        manager
          ..onComponentError = (component, error, stackTrace) {
            capturedError = error;
          }
          ..register(modal);

        await expectLater(
          manager.dispatch('modal-sync', [
            _FakeModalContext('modal-sync'),
            'value',
          ]),
          completes,
        );

        expect(capturedError, isA<Exception>());
        expect(
          logger.errors,
          contains(contains('Failed to dispatch component "modal-sync"')),
        );
      });
    });

    group('modal — asynchronous (Future) rejection', () {
      test('is caught, logged, and does not propagate', () async {
        Object? capturedError;

        final modal = _ScriptedModal('modal-async', (_, _) async {
          await Future<void>.delayed(Duration.zero);
          throw Exception('asynchronous modal failure');
        });
        manager
          ..onComponentError = (component, error, stackTrace) {
            capturedError = error;
          }
          ..register(modal);

        await expectLater(
          manager.dispatch('modal-async', [
            _FakeModalContext('modal-async'),
            'value',
          ]),
          completes,
        );

        expect(capturedError, isA<Exception>());
        expect(
          logger.errors,
          contains(contains('Failed to dispatch component "modal-async"')),
        );
      });
    });

    group('select menu — synchronous throw', () {
      test('is caught, logged, and does not propagate', () async {
        Object? capturedError;

        final select = _ScriptedSelectMenu('select-sync', (_, _) {
          throw Exception('synchronous select failure');
        });
        manager
          ..onComponentError = (component, error, stackTrace) {
            capturedError = error;
          }
          ..register(select);

        await expectLater(
          manager.dispatch('select-sync', [
            _FakeSelectContext('select-sync'),
            <String>['a'],
          ]),
          completes,
        );

        expect(capturedError, isA<Exception>());
        expect(
          logger.errors,
          contains(contains('Failed to dispatch component "select-sync"')),
        );
      });
    });

    group('select menu — asynchronous (Future) rejection', () {
      test('is caught, logged, and does not propagate', () async {
        Object? capturedError;

        final select = _ScriptedSelectMenu('select-async', (_, _) async {
          await Future<void>.delayed(Duration.zero);
          throw Exception('asynchronous select failure');
        });
        manager
          ..onComponentError = (component, error, stackTrace) {
            capturedError = error;
          }
          ..register(select);

        await expectLater(
          manager.dispatch('select-async', [
            _FakeSelectContext('select-async'),
            <String>['a'],
          ]),
          completes,
        );

        expect(capturedError, isA<Exception>());
        expect(
          logger.errors,
          contains(contains('Failed to dispatch component "select-async"')),
        );
      });
    });
  });
}
