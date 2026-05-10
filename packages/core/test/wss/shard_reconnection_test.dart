import 'dart:async';
import 'dart:convert';

import 'package:mineral/src/infrastructure/internals/wss/dispatchers/shard_authentication.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard.dart';
import 'package:mineral/src/infrastructure/io/exceptions/fatal_gateway_exception.dart';
import 'package:mineral/src/testing/fake_logger.dart';
import 'package:test/test.dart';

import '../helpers/fake_logger.dart';
import '../helpers/fake_websocket_client.dart';
import '../helpers/fake_websocket_orchestrator.dart';
import '../helpers/ioc_test_helper.dart';
import '../helpers/mocks.dart';


Shard _createShard({int maxReconnectAttempts = 3, required FakeLogger logger}) {
  return Shard(
    shardName: 'test-shard-0',
    shardIndex: 0,
    shardCount: 1,
    url: 'wss://fake',
    wss: FakeWebsocketOrchestrator(maxReconnectAttempts: maxReconnectAttempts),
    logger: logger,
    strategy: FakeRunningStrategy(),
  );
}

void main() {
  group('ShardAuthentication reconnection', () {
    late Shard shard;
    late ShardAuthentication auth;
    late FakeWebsocketClient fakeClient;
    late FakeLogger logger;
    late void Function() restoreIoc;

    setUp(() {
      final testIoc = createTestIoc();
      logger = testIoc.logger;
      restoreIoc = testIoc.restore;

      shard = _createShard(logger: logger);
      fakeClient = FakeWebsocketClient();
      shard.client = fakeClient;
      auth = shard.authentication;
    });

    tearDown(() {
      auth.cancelHeartbeat();
      restoreIoc();
    });

    group('reconnect()', () {
      test('disconnects with internal close code 4900', () {
        runZonedGuarded(() {
          auth.reconnect();
        }, (_, __) {});

        expect(fakeClient.disconnected, isTrue);
        expect(fakeClient.lastDisconnectCode, equals(4900));
      });

      test('cancels heartbeat and resets attempts', () {
        auth.createHeartbeatTimer(100000);
        auth.attempts = 5;

        runZonedGuarded(() {
          auth.reconnect();
        }, (_, __) {});

        expect(auth.attempts, equals(0));
      });

      test('sets intentionalDisconnect to true', () {
        runZonedGuarded(() {
          auth.reconnect();
        }, (_, __) {});

        expect(auth.intentionalDisconnect, isTrue);
      });

      test('logs reconnect warning with shard name', () async {
        runZonedGuarded(() {
          auth.reconnect();
        }, (_, __) {});

        await Future<void>.delayed(Duration.zero);

        expect(logger.warnings, contains(contains('Reconnecting')));
        expect(logger.warnings, contains(contains('test-shard-0')));
      });
    });

    group('resume()', () {
      test('disconnects with internal close code 4900', () {
        runZonedGuarded(() {
          auth.resume();
        }, (_, __) {});

        expect(fakeClient.disconnected, isTrue);
        expect(fakeClient.lastDisconnectCode, equals(4900));
      });

      test('sets pendingResume so next identify sends resume opcode', () async {
        auth.setupRequirements({
          'session_id': 'session-abc',
          'resume_gateway_url': 'wss://resume.discord.gg',
        });
        auth.sequence = 42;

        // resume() sets _pendingResume = true synchronously before awaiting
        // disconnect/init. We trigger it and absorb the async error from
        // shard.init(), then simulate the identify call that would follow.
        runZonedGuarded(() {
          auth.resume();
        }, (_, __) {});

        await Future<void>.delayed(Duration.zero);

        // Simulate the identify call that shard.init() would trigger.
        // Because _pendingResume is true, identify() should send OpCode.resume.
        fakeClient.sentMessages.clear();
        auth.identify({'heartbeat_interval': 45000});

        expect(fakeClient.sentMessages, hasLength(1));
        final decoded = Map<String, dynamic>.from(
          jsonDecode(fakeClient.sentMessages.first) as Map,
        );
        // OpCode.resume = 6
        expect(decoded['op'], equals(6));
        expect(decoded['d']['session_id'], equals('session-abc'));
        expect(decoded['d']['seq'], equals(42));
      });

      test('sets intentionalDisconnect to true', () {
        runZonedGuarded(() {
          auth.resume();
        }, (_, __) {});

        expect(auth.intentionalDisconnect, isTrue);
      });

      test('logs resuming warning with shard name', () async {
        runZonedGuarded(() {
          auth.resume();
        }, (_, __) {});

        await Future<void>.delayed(Duration.zero);

        expect(logger.warnings, contains(contains('Resuming')));
        expect(logger.warnings, contains(contains('test-shard-0')));
      });
    });

    group('FatalGatewayException on max attempts exceeded', () {
      test('throws FatalGatewayException after exceeding maxReconnectAttempts',
          () async {
        // Create a shard with maxReconnectAttempts = 1
        shard = _createShard(maxReconnectAttempts: 1, logger: logger);
        fakeClient = FakeWebsocketClient();
        shard.client = fakeClient;
        auth = shard.authentication;

        // First reconnect attempt (attempt 1) should succeed (log warning)
        final errors = <Object>[];
        runZonedGuarded(() {
          auth.reconnect();
        }, (error, _) {
          errors.add(error);
        });

        await Future<void>.delayed(Duration.zero);

        // Second reconnect attempt (attempt 2) exceeds max of 1
        runZonedGuarded(() {
          auth.reconnect();
        }, (error, _) {
          errors.add(error);
        });

        await Future<void>.delayed(Duration.zero);

        expect(errors.whereType<FatalGatewayException>(), isNotEmpty);
        expect(logger.errors, contains(contains('Max reconnect attempts')));
      });

      test('throws FatalGatewayException with correct message', () async {
        shard = _createShard(maxReconnectAttempts: 0, logger: logger);
        fakeClient = FakeWebsocketClient();
        shard.client = fakeClient;
        auth = shard.authentication;

        FatalGatewayException? caught;
        runZonedGuarded(() {
          auth.reconnect();
        }, (error, _) {
          if (error is FatalGatewayException) caught = error;
        });

        await Future<void>.delayed(Duration.zero);

        expect(caught, isNotNull);
        expect(caught!.message, contains('Max reconnect attempts'));
        expect(caught!.code, equals(-1));
      });
    });

    group('setupRequirements()', () {
      test('stores sessionId and resumeUrl from payload', () {
        auth.setupRequirements({
          'session_id': 'session-abc',
          'resume_gateway_url': 'wss://resume.discord.gg',
        });

        expect(auth.sessionId, equals('session-abc'));
        expect(auth.resumeUrl, equals('wss://resume.discord.gg'));
      });

      test('resets reconnect attempts counter', () async {
        // Increment reconnect attempts first
        runZonedGuarded(() {
          auth.reconnect();
        }, (_, __) {});

        await Future<void>.delayed(Duration.zero);

        // setupRequirements should reset _reconnectAttempts to 0
        auth.setupRequirements({
          'session_id': 'session-abc',
          'resume_gateway_url': 'wss://resume.discord.gg',
        });

        // After reset, reconnect should work without hitting max
        // (if _reconnectAttempts was not reset, this could fail with max=3)
        runZonedGuarded(() {
          auth.reconnect();
        }, (_, __) {});

        await Future<void>.delayed(Duration.zero);

        final reconnectWarnings =
            logger.warnings.where((w) => w.contains('Reconnecting')).toList();
        expect(reconnectWarnings, hasLength(2));
      });

      test('handles null values in payload', () {
        auth.setupRequirements({
          'session_id': null,
          'resume_gateway_url': null,
        });

        expect(auth.sessionId, isNull);
        expect(auth.resumeUrl, isNull);
      });
    });

    group('resetReconnectAttempts()', () {
      test('resets the reconnect attempts counter to zero', () async {
        // Trigger a reconnect to increment _reconnectAttempts
        runZonedGuarded(() {
          auth.reconnect();
        }, (_, __) {});

        await Future<void>.delayed(Duration.zero);

        // Reset the counter
        auth.resetReconnectAttempts();

        // Should be able to reconnect again from attempt 1
        runZonedGuarded(() {
          auth.reconnect();
        }, (_, __) {});

        await Future<void>.delayed(Duration.zero);

        // Both reconnect attempts should have logged "attempt 1/3"
        final attemptLogs =
            logger.warnings.where((w) => w.contains('attempt 1/')).toList();
        expect(attemptLogs, hasLength(2));
      });

      test('allows reconnection after previously hitting max attempts',
          () async {
        shard = _createShard(maxReconnectAttempts: 1, logger: logger);
        fakeClient = FakeWebsocketClient();
        shard.client = fakeClient;
        auth = shard.authentication;

        // First reconnect is allowed (attempt 1)
        runZonedGuarded(() {
          auth.reconnect();
        }, (_, __) {});

        await Future<void>.delayed(Duration.zero);

        // Second would throw FatalGatewayException
        runZonedGuarded(() {
          auth.reconnect();
        }, (_, __) {});

        await Future<void>.delayed(Duration.zero);

        // Reset counter
        auth.resetReconnectAttempts();

        // Should be able to reconnect again
        final errors = <Object>[];
        runZonedGuarded(() {
          auth.reconnect();
        }, (error, _) {
          errors.add(error);
        });

        await Future<void>.delayed(Duration.zero);

        // After reset, the reconnect should succeed (log a warning, not throw)
        final postResetWarnings =
            logger.warnings.where((w) => w.contains('Reconnecting')).toList();
        expect(postResetWarnings.length, greaterThanOrEqualTo(2));
        expect(errors.whereType<FatalGatewayException>(), isEmpty);
      });
    });
  });
}
