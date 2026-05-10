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
Shard _createShard({int maxReconnect = 0, required FakeLogger logger}) {
  return Shard(
    shardName: 'test-shard-0',
    shardIndex: 0,
    shardCount: 1,
    url: 'wss://fake',
    wss: FakeWebsocketOrchestrator(maxReconnectAttempts: maxReconnect),
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
  }, (_, __) {
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
      final shard = _createShard(logger: logger);
      shard.client = FakeWebsocketClient();
      final networkError = ShardNetworkError(shard);

      networkError.dispatch(null);

      expect(logger.warnings, isEmpty);
      expect(logger.errors, isEmpty);
      expect((shard.client as FakeWebsocketClient).disconnected, isFalse);
    });

    test('does nothing when intentionalDisconnect is true', () {
      final shard = _createShard(logger: logger);
      shard.client = FakeWebsocketClient();
      shard.authentication.intentionalDisconnect = true;
      final networkError = ShardNetworkError(shard);

      networkError.dispatch(4000);

      expect(logger.warnings, isEmpty);
      expect(logger.errors, isEmpty);
      expect((shard.client as FakeWebsocketClient).disconnected, isFalse);
    });

    group('resume codes', () {
      test('logs warning for code 4000 (unknownError)', () {
        final shard = _createShard(logger: logger);
        shard.client = FakeWebsocketClient();
        final networkError = ShardNetworkError(shard);

        _dispatchSilently(() => networkError.dispatch(4000));

        expect(logger.warnings, contains(contains('code 4000')));
      });

      test('logs warning for code 4009 (sessionTimeout)', () {
        final shard = _createShard(logger: logger);
        shard.client = FakeWebsocketClient();
        final networkError = ShardNetworkError(shard);

        _dispatchSilently(() => networkError.dispatch(4009));

        expect(logger.warnings, contains(contains('code 4009')));
      });

      test('disconnects client when resuming', () {
        final shard = _createShard(logger: logger);
        final fakeClient = FakeWebsocketClient();
        shard.client = fakeClient;
        final networkError = ShardNetworkError(shard);

        _dispatchSilently(() => networkError.dispatch(4000));

        expect(fakeClient.disconnected, isTrue);
      });
    });

    group('reconnect codes', () {
      test('logs warning for code 1000 (normal)', () {
        final shard = _createShard(logger: logger);
        shard.client = FakeWebsocketClient();
        final networkError = ShardNetworkError(shard);

        _dispatchSilently(() => networkError.dispatch(1000));

        expect(logger.warnings, contains(contains('code 1000')));
      });

      test('logs warning for code 1001 (goingAway)', () {
        final shard = _createShard(logger: logger);
        shard.client = FakeWebsocketClient();
        final networkError = ShardNetworkError(shard);

        _dispatchSilently(() => networkError.dispatch(1001));

        expect(logger.warnings, contains(contains('code 1001')));
      });

      test('logs warning for code 1006 (abnormalClosure)', () {
        final shard = _createShard(logger: logger);
        shard.client = FakeWebsocketClient();
        final networkError = ShardNetworkError(shard);

        _dispatchSilently(() => networkError.dispatch(1006));

        expect(logger.warnings, contains(contains('code 1006')));
      });

      test('disconnects client when reconnecting', () {
        final shard = _createShard(logger: logger);
        final fakeClient = FakeWebsocketClient();
        shard.client = fakeClient;
        final networkError = ShardNetworkError(shard);

        _dispatchSilently(() => networkError.dispatch(1000));

        expect(fakeClient.disconnected, isTrue);
      });

      test('invalidates session before reconnect on code 1000', () {
        final shard = _createShard(logger: logger);
        shard.client = FakeWebsocketClient();
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
      test('logs fatal error and disconnects for code 4004', () {
        final shard = _createShard(logger: logger);
        final fakeClient = FakeWebsocketClient();
        shard.client = fakeClient;
        final networkError = ShardNetworkError(shard);

        final error = _dispatchSilently(() => networkError.dispatch(4004));

        expect(error, isNotNull);
        expect(logger.errors, contains(contains('Fatal gateway error')));
        expect(logger.errors.first, contains('4004'));
        expect(fakeClient.disconnected, isTrue);
      });

      test('logs fatal error and disconnects for code 4014', () {
        final shard = _createShard(logger: logger);
        final fakeClient = FakeWebsocketClient();
        shard.client = fakeClient;
        final networkError = ShardNetworkError(shard);

        final error = _dispatchSilently(() => networkError.dispatch(4014));

        expect(error, isNotNull);
        expect(logger.errors, contains(contains('Fatal gateway error')));
        expect(fakeClient.disconnected, isTrue);
      });

      test('logs fatal error and disconnects for code 4010 (invalidShard)', () {
        final shard = _createShard(logger: logger);
        final fakeClient = FakeWebsocketClient();
        shard.client = fakeClient;
        final networkError = ShardNetworkError(shard);

        final error = _dispatchSilently(() => networkError.dispatch(4010));

        expect(error, isNotNull);
        expect(logger.errors, contains(contains('Fatal gateway error')));
        expect(fakeClient.disconnected, isTrue);
      });
    });

    group('unknown codes', () {
      test('logs warning about unknown code', () {
        final shard = _createShard(logger: logger);
        shard.client = FakeWebsocketClient();
        final networkError = ShardNetworkError(shard);

        _dispatchSilently(() => networkError.dispatch(9999));

        expect(logger.warnings, contains(contains('unknown code: 9999')));
      });

      test('disconnects client for unknown code', () {
        final shard = _createShard(logger: logger);
        final fakeClient = FakeWebsocketClient();
        shard.client = fakeClient;
        final networkError = ShardNetworkError(shard);

        _dispatchSilently(() => networkError.dispatch(1234));

        expect(fakeClient.disconnected, isTrue);
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
