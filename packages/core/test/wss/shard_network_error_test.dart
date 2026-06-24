import 'dart:async';

import 'package:mineral/src/domains/services/wss/constants/shard_disconnect_error.dart';
import 'package:mineral/src/infrastructure/internals/wss/dispatchers/shard_network_error.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard.dart';
import 'package:mineral/src/testing/fake_logger.dart';
import 'package:test/test.dart';

import '../helpers/fake_logger.dart';
import '../helpers/fake_websocket_client.dart';
import '../helpers/fake_websocket_orchestrator.dart';
import '../helpers/ioc_test_helper.dart';
import '../helpers/mocks.dart';

// ── Helpers ────────────────────────────────────────────────────────────────

/// Creates a shard with configurable maxReconnectAttempts so that
/// resume/reconnect throw FatalGatewayException when set to 0.
///
/// Pass [onFatalDisconnect] to install a fatal-disconnect callback on the
/// orchestrator (used in H4 supervision tests).
Shard _createShard({
  required FakeLogger logger,
  int maxReconnect = 0,
  Future<void> Function()? onFatalDisconnect,
}) {
  final wss = FakeWebsocketOrchestrator(maxReconnectAttempts: maxReconnect)
    ..onFatalDisconnect = onFatalDisconnect;
  return Shard(
    shardName: 'test-shard-0',
    shardIndex: 0,
    shardCount: 1,
    url: 'wss://fake',
    wss: wss,
    logger: logger,
    strategy: FakeRunningStrategy(),
  );
}

/// Runs [fn] while silencing uncaught async errors (from fire-and-forget
/// futures inside dispatch). Returns any synchronous error thrown by [fn].
Object? _dispatchSilently(void Function() fn) {
  Object? caught;
  runZonedGuarded(() {
    try {
      fn();
    } on Object catch (e) {
      caught = e;
    }
  }, (_, _) {
    // Silently absorb uncaught async errors from resume()/reconnect()
  });
  return caught;
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('ShardNetworkError', () {
    late FakeLogger logger;
    late void Function() restoreIoc;

    setUp(() {
      final testIoc = createTestIoc();
      logger = testIoc.logger;
      restoreIoc = testIoc.restore;
    });

    tearDown(() {
      restoreIoc();
    });

    test('does nothing when payload is null', () {
      final shard = _createShard(logger: logger)
        ..client = FakeWebsocketClient();
      ShardNetworkError(shard).dispatch(null);

      expect(logger.warnings, isEmpty);
      expect(logger.errors, isEmpty);
      expect((shard.client as FakeWebsocketClient).disconnected, isFalse);
    });

    test('does nothing when intentionalDisconnect is true', () {
      final shard = _createShard(logger: logger)
        ..client = FakeWebsocketClient();
      shard.authentication.intentionalDisconnect = true;
      ShardNetworkError(shard).dispatch(4000);

      expect(logger.warnings, isEmpty);
      expect(logger.errors, isEmpty);
      expect((shard.client as FakeWebsocketClient).disconnected, isFalse);
    });

    group('resume codes', () {
      test('logs warning for code 4000 (unknownError)', () {
        final shard = _createShard(logger: logger)
          ..client = FakeWebsocketClient();
        final networkError = ShardNetworkError(shard);

        _dispatchSilently(() => networkError.dispatch(4000));

        expect(logger.warnings, contains(contains('code 4000')));
      });

      test('logs warning for code 4009 (sessionTimeout)', () {
        final shard = _createShard(logger: logger)
          ..client = FakeWebsocketClient();
        final networkError = ShardNetworkError(shard);

        _dispatchSilently(() => networkError.dispatch(4009));

        expect(logger.warnings, contains(contains('code 4009')));
      });

      test('disconnects client when resuming', () {
        final fakeClient = FakeWebsocketClient();
        final shard = _createShard(logger: logger)..client = fakeClient;
        final networkError = ShardNetworkError(shard);

        _dispatchSilently(() => networkError.dispatch(4000));

        expect(fakeClient.disconnected, isTrue);
      });
    });

    group('reconnect codes', () {
      test('logs warning for code 1000 (normal)', () {
        final shard = _createShard(logger: logger)
          ..client = FakeWebsocketClient();
        final networkError = ShardNetworkError(shard);

        _dispatchSilently(() => networkError.dispatch(1000));

        expect(logger.warnings, contains(contains('code 1000')));
      });

      test('logs warning for code 1001 (goingAway)', () {
        final shard = _createShard(logger: logger)
          ..client = FakeWebsocketClient();
        final networkError = ShardNetworkError(shard);

        _dispatchSilently(() => networkError.dispatch(1001));

        expect(logger.warnings, contains(contains('code 1001')));
      });

      test('logs warning for code 1006 (abnormalClosure)', () {
        final shard = _createShard(logger: logger)
          ..client = FakeWebsocketClient();
        final networkError = ShardNetworkError(shard);

        _dispatchSilently(() => networkError.dispatch(1006));

        expect(logger.warnings, contains(contains('code 1006')));
      });

      test('disconnects client when reconnecting', () {
        final fakeClient = FakeWebsocketClient();
        final shard = _createShard(logger: logger)..client = fakeClient;
        final networkError = ShardNetworkError(shard);

        _dispatchSilently(() => networkError.dispatch(1000));

        expect(fakeClient.disconnected, isTrue);
      });

      test('invalidates session before reconnect on code 1000', () {
        final shard = _createShard(logger: logger)
          ..client = FakeWebsocketClient();
        shard.authentication.setupRequirements({
          'session_id': 'dead-session',
          'resume_gateway_url': 'wss://old-resume',
        });
        final networkError = ShardNetworkError(shard);

        _dispatchSilently(() => networkError.dispatch(1000));

        expect(shard.authentication.sessionId, isNull);
        expect(shard.authentication.resumeUrl, isNull);
      });
    });

    group('fatal codes', () {
      // H4 fix: dispatch() must NOT throw for fatal codes — _handleFatal
      // absorbs the error and routes to onFatalDisconnect.

      test('does NOT throw for code 4004 (H4 fix)', () {
        final fakeClient = FakeWebsocketClient();
        final shard = _createShard(logger: logger)..client = fakeClient;
        final networkError = ShardNetworkError(shard);

        // dispatch() must complete without throwing
        expect(() => networkError.dispatch(4004), returnsNormally);
      });

      test('logs fatal error and disconnects for code 4004', () {
        final fakeClient = FakeWebsocketClient();
        final shard = _createShard(logger: logger)..client = fakeClient;

        ShardNetworkError(shard).dispatch(4004);

        expect(logger.errors, contains(contains('Fatal gateway error')));
        expect(logger.errors.first, contains('4004'));
        expect(fakeClient.disconnected, isTrue);
      });

      test('logs fatal error and disconnects for code 4014', () {
        final fakeClient = FakeWebsocketClient();
        final shard = _createShard(logger: logger)..client = fakeClient;

        ShardNetworkError(shard).dispatch(4014);

        expect(logger.errors, contains(contains('Fatal gateway error')));
        expect(fakeClient.disconnected, isTrue);
      });

      test('logs fatal error and disconnects for code 4010 (invalidShard)', () {
        final fakeClient = FakeWebsocketClient();
        final shard = _createShard(logger: logger)..client = fakeClient;

        ShardNetworkError(shard).dispatch(4010);

        expect(logger.errors, contains(contains('Fatal gateway error')));
        expect(fakeClient.disconnected, isTrue);
      });
    });

    group('connect failure synthetic code (H3 fix)', () {
      // When WebsocketClientImpl.connect() catches a WebSocketException or
      // SocketException it calls _onClose(1006) — the same code that onDone
      // uses for an abnormal closure. This group asserts that code 1006
      // arriving through dispatch() triggers the reconnect path, not a no-op.

      test('code 1006 is not a no-op (does not leave warnings empty)', () {
        final shard = _createShard(logger: logger)
          ..client = FakeWebsocketClient();
        final networkError = ShardNetworkError(shard);

        _dispatchSilently(() => networkError.dispatch(1006));

        expect(logger.warnings, isNotEmpty,
            reason: 'A connect failure must not silently hang');
      });

      test('code 1006 invalidates session and triggers reconnect', () {
        final shard = _createShard(logger: logger)
          ..client = FakeWebsocketClient();
        shard.authentication.setupRequirements({
          'session_id': 'stale-session',
          'resume_gateway_url': 'wss://old-url',
        });
        final networkError = ShardNetworkError(shard);

        _dispatchSilently(() => networkError.dispatch(1006));

        expect(shard.authentication.sessionId, isNull,
            reason: 'Session must be invalidated on connect failure');
        expect(shard.authentication.resumeUrl, isNull,
            reason: 'Resume URL must be cleared on connect failure');
      });

      test('code 1006 disconnects the client before reconnecting', () {
        final fakeClient = FakeWebsocketClient();
        final shard = _createShard(logger: logger)..client = fakeClient;
        final networkError = ShardNetworkError(shard);

        _dispatchSilently(() => networkError.dispatch(1006));

        expect(fakeClient.disconnected, isTrue,
            reason: 'Client must be disconnected before reconnect attempt');
      });
    });

    group('unknown codes', () {
      test('logs warning about unknown code', () {
        final shard = _createShard(logger: logger)
          ..client = FakeWebsocketClient();
        final networkError = ShardNetworkError(shard);

        _dispatchSilently(() => networkError.dispatch(9999));

        expect(logger.warnings, contains(contains('unknown code: 9999')));
      });

      test('disconnects client for unknown code', () {
        final fakeClient = FakeWebsocketClient();
        final shard = _createShard(logger: logger)..client = fakeClient;
        final networkError = ShardNetworkError(shard);

        _dispatchSilently(() => networkError.dispatch(1234));

        expect(fakeClient.disconnected, isTrue);
      });
    });

    // ── H4 — supervised reconnection / fatal routed to hook ─────────────────

    group('H4 — reconnect/resume supervision', () {
      test(
          'resume() throwing FatalGatewayException calls onFatalDisconnect '
          'and no uncaught error escapes', () async {
        bool fatalCalled = false;
        final fakeClient = FakeWebsocketClient();
        final shard = _createShard(
          logger: logger,
          maxReconnect: 0, // ensures resume() throws FatalGatewayException
          onFatalDisconnect: () async {
            fatalCalled = true;
          },
        )..client = fakeClient;

        final uncaughtErrors = <Object>[];
        await runZonedGuarded(
          () async {
            ShardNetworkError(shard).dispatch(4000); // resume code
            // Give the fire-and-forget future time to complete.
            await Future<void>.delayed(Duration.zero);
          },
          (e, _) => uncaughtErrors.add(e),
        );

        expect(uncaughtErrors, isEmpty,
            reason: 'No error must escape the zone');
        expect(fatalCalled, isTrue,
            reason: 'onFatalDisconnect must be invoked');
        expect(fakeClient.disconnected, isTrue,
            reason: 'Client must be disconnected on fatal');
        expect(logger.errors, contains(contains('Fatal gateway error')));
      });

      test(
          'reconnect() throwing FatalGatewayException calls onFatalDisconnect '
          'and no uncaught error escapes', () async {
        bool fatalCalled = false;
        final fakeClient = FakeWebsocketClient();
        final shard = _createShard(
          logger: logger,
          maxReconnect: 0, // ensures reconnect() throws FatalGatewayException
          onFatalDisconnect: () async {
            fatalCalled = true;
          },
        )..client = fakeClient;

        final uncaughtErrors = <Object>[];
        await runZonedGuarded(
          () async {
            ShardNetworkError(shard).dispatch(1000); // reconnect code
            await Future<void>.delayed(Duration.zero);
          },
          (e, _) => uncaughtErrors.add(e),
        );

        expect(uncaughtErrors, isEmpty,
            reason: 'No error must escape the zone');
        expect(fatalCalled, isTrue,
            reason: 'onFatalDisconnect must be invoked');
        expect(fakeClient.disconnected, isTrue,
            reason: 'Client must be disconnected on fatal');
        expect(logger.errors, contains(contains('Fatal gateway error')));
      });

      test(
          'unknown-code reconnect() throwing FatalGatewayException calls '
          'onFatalDisconnect and no uncaught error escapes', () async {
        bool fatalCalled = false;
        final fakeClient = FakeWebsocketClient();
        final shard = _createShard(
          logger: logger,
          maxReconnect: 0,
          onFatalDisconnect: () async {
            fatalCalled = true;
          },
        )..client = fakeClient;

        final uncaughtErrors = <Object>[];
        await runZonedGuarded(
          () async {
            ShardNetworkError(shard).dispatch(9999); // unknown code
            await Future<void>.delayed(Duration.zero);
          },
          (e, _) => uncaughtErrors.add(e),
        );

        expect(uncaughtErrors, isEmpty,
            reason: 'No error must escape the zone');
        expect(fatalCalled, isTrue,
            reason: 'onFatalDisconnect must be invoked for unknown code');
        expect(fakeClient.disconnected, isTrue);
      });

      test(
          'DisconnectAction.fatal path calls onFatalDisconnect, disconnects '
          'client, cancels heartbeat, and does NOT throw', () async {
        bool fatalCalled = false;
        final fakeClient = FakeWebsocketClient();
        final shard = _createShard(
          logger: logger,
          onFatalDisconnect: () async {
            fatalCalled = true;
          },
        )..client = fakeClient;

        final uncaughtErrors = <Object>[];
        await runZonedGuarded(
          () async {
            // dispatch() must complete without throwing
            expect(
              () => ShardNetworkError(shard).dispatch(4004),
              returnsNormally,
            );
            await Future<void>.delayed(Duration.zero);
          },
          (e, _) => uncaughtErrors.add(e),
        );

        expect(uncaughtErrors, isEmpty,
            reason: 'Fatal path must not throw from a callback');
        expect(fatalCalled, isTrue,
            reason: 'onFatalDisconnect must be called on fatal code');
        expect(fakeClient.disconnected, isTrue,
            reason: 'Client must be disconnected');
        expect(logger.errors, contains(contains('Fatal gateway error')));
      });

      test(
          'DisconnectAction.fatal path invokes onFatalDisconnect '
          'even when it is null (no-op)', () {
        final fakeClient = FakeWebsocketClient();
        // onFatalDisconnect intentionally left null
        final shard = _createShard(logger: logger)..client = fakeClient;

        expect(
          () => ShardNetworkError(shard).dispatch(4004),
          returnsNormally,
        );
        expect(fakeClient.disconnected, isTrue);
        expect(logger.errors, contains(contains('Fatal gateway error')));
      });
    });
  });

  group('ShardDisconnectError enum', () {
    test('resume codes include all expected Discord resume codes', () {
      final resumeCodes = ShardDisconnectError.values
          .where((e) => e.action == DisconnectAction.resume)
          .map((e) => e.code)
          .toList();

      expect(
          resumeCodes, containsAll([4000, 4001, 4002, 4003, 4007, 4008, 4009]));
    });

    test('reconnect codes include all expected Discord reconnect codes', () {
      final reconnectCodes = ShardDisconnectError.values
          .where((e) => e.action == DisconnectAction.reconnect)
          .map((e) => e.code)
          .toList();

      expect(reconnectCodes,
          containsAll([1000, 1001, 1002, 1003, 1005, 1006, 4005]));
    });

    test('fatal codes include all expected Discord fatal codes', () {
      final fatalCodes = ShardDisconnectError.values
          .where((e) => e.action == DisconnectAction.fatal)
          .map((e) => e.code)
          .toList();

      expect(fatalCodes, containsAll([4004, 4010, 4011, 4012, 4013, 4014]));
    });

    test('every enum value has a non-empty message', () {
      for (final error in ShardDisconnectError.values) {
        expect(error.message, isNotEmpty,
            reason: '${error.name} should have a non-empty message');
      }
    });

    test('every enum value has a valid action', () {
      for (final error in ShardDisconnectError.values) {
        expect(
          error.action,
          isIn([
            DisconnectAction.resume,
            DisconnectAction.reconnect,
            DisconnectAction.fatal,
          ]),
        );
      }
    });
  });
}
