import 'dart:async';
import 'dart:convert';

import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/services/wss/running_strategy.dart';
import 'package:mineral/src/infrastructure/internals/wss/dispatchers/shard_authentication.dart';
import 'package:mineral/src/infrastructure/internals/wss/encoding_strategies/json_encoder.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard.dart';
import 'package:mineral/src/infrastructure/internals/wss/websocket_isolate_message_transfert.dart';
import 'package:mineral/src/testing/fake_logger.dart';
import 'package:test/test.dart';

import '../helpers/fake_logger.dart';
import '../helpers/fake_websocket_client.dart';
import '../helpers/fake_websocket_orchestrator.dart';
import '../helpers/ioc_test_helper.dart';
import '../helpers/mocks.dart';

Shard _createShard({required FakeLogger logger, int maxReconnectAttempts = 3}) {
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

// ── A5/A6 regression helpers ─────────────────────────────────────────────
//
// `FakeShardingConfig.encoding` throws `UnimplementedError`, which is fine
// for every other test in this file because none of them let a reconnect
// attempt run far enough to reach `Shard.init()` (they only ever observe
// the synchronous prelude within a `Duration.zero` window). The two tests
// below deliberately let a reconnect/resume attempt run to completion —
// `Shard.init()` *always* constructs a brand-new, real `WebsocketClientImpl`
// regardless of what fake was previously assigned to `shard.client`, so
// this is the only way to reproduce the real A5/A6 failure modes — which
// means they need a working `encoding`.

/// A [ShardingConfigContract] with a real, working [encoding] (unlike
/// [FakeShardingConfig]), so `Shard.init()` can build its interceptor chain
/// without throwing before ever attempting to connect.
final class _WorkingShardingConfig implements ShardingConfigContract {
  final int _maxReconnectAttempts;

  @override
  final EncodingStrategy encoding;

  _WorkingShardingConfig({
    required LoggerContract logger,
    int maxReconnectAttempts = 5,
  }) : _maxReconnectAttempts = maxReconnectAttempts,
       encoding = JsonEncoderStrategy(logger: logger);

  @override
  String get token => 'fake-token';
  @override
  int get intent => 513;
  @override
  bool get compress => false;
  @override
  int get version => 10;
  @override
  int get largeThreshold => 50;
  @override
  int? get shardCount => 1;
  @override
  int get maxReconnectAttempts => _maxReconnectAttempts;
  @override
  Duration get maxReconnectDelay => Duration.zero;
}

/// A minimal [WebsocketOrchestratorContract] whose `config` is
/// [_WorkingShardingConfig] instead of the throwing default from
/// [FakeWebsocketOrchestrator] (which is `final` and cannot be extended),
/// so a reconnect/resume attempt can run through a real (failing)
/// `WebsocketClientImpl.connect()` call. Everything besides `config` mirrors
/// [FakeWebsocketOrchestrator]'s own no-op behaviour.
final class _RealConnectOrchestrator implements WebsocketOrchestratorContract {
  _RealConnectOrchestrator({
    required LoggerContract logger,
    int maxReconnectAttempts = 5,
  }) : config = _WorkingShardingConfig(
         logger: logger,
         maxReconnectAttempts: maxReconnectAttempts,
       );

  @override
  final ShardingConfigContract config;

  @override
  final List<RequestQueueEntry> requestQueue = [];
  @override
  void addToRequestQueue(RequestQueueEntry entry) => requestQueue.add(entry);
  @override
  RequestQueueEntry? findInRequestQueue(String uid) {
    for (final entry in requestQueue) {
      if (entry.uid == uid) {
        return entry;
      }
    }
    return null;
  }

  @override
  void removeFromRequestQueue(RequestQueueEntry entry) =>
      requestQueue.remove(entry);
  @override
  Map<int, ShardContract> get shards => {};
  @override
  Future<void> Function()? onFatalDisconnect;
  @override
  void send(WebsocketIsolateMessageTransfert message) {}
  @override
  void setBotPresence(
    List<BotActivity>? activity,
    StatusType? status,
    bool? afk,
  ) {}
  @override
  Future<Map<String, dynamic>> getWebsocketEndpoint() async => {};
  @override
  Future<void> createShards(RunningStrategy strategy) async {}
  @override
  Future<Presence> getMemberPresence(String guildId, String id) =>
      throw UnimplementedError();
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
        }, (_, _) {});

        expect(fakeClient.disconnected, isTrue);
        expect(fakeClient.lastDisconnectCode, equals(4900));
      });

      test('cancels heartbeat and resets attempts', () {
        auth
          ..createHeartbeatTimer(100000)
          ..attempts = 5;

        runZonedGuarded(() {
          auth.reconnect();
        }, (_, _) {});

        expect(auth.attempts, equals(0));
      });

      test('sets intentionalDisconnect to true', () {
        runZonedGuarded(() {
          auth.reconnect();
        }, (_, _) {});

        expect(auth.intentionalDisconnect, isTrue);
      });

      test('logs reconnect warning with shard name', () async {
        runZonedGuarded(() {
          auth.reconnect();
        }, (_, _) {});

        await Future<void>.delayed(Duration.zero);

        expect(logger.warnings, contains(contains('Reconnecting')));
        expect(logger.warnings, contains(contains('test-shard-0')));
      });
    });

    group('resume()', () {
      test('disconnects with internal close code 4900', () {
        runZonedGuarded(() {
          auth.resume();
        }, (_, _) {});

        expect(fakeClient.disconnected, isTrue);
        expect(fakeClient.lastDisconnectCode, equals(4900));
      });

      test('sets pendingResume so next identify sends resume opcode', () async {
        auth
          ..setupRequirements({
            'session_id': 'session-abc',
            'resume_gateway_url': 'wss://resume.discord.gg',
          })
          ..sequence = 42;

        // resume() sets _pendingResume = true synchronously before awaiting
        // disconnect/init. We trigger it and absorb the async error from
        // shard.init(), then simulate the identify call that would follow.
        runZonedGuarded(() {
          auth.resume();
        }, (_, _) {});

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
        }, (_, _) {});

        expect(auth.intentionalDisconnect, isTrue);
      });

      test('logs resuming warning with shard name', () async {
        runZonedGuarded(() {
          auth.resume();
        }, (_, _) {});

        await Future<void>.delayed(Duration.zero);

        expect(logger.warnings, contains(contains('Resuming')));
        expect(logger.warnings, contains(contains('test-shard-0')));
      });
    });

    group('FatalGatewayException on max attempts exceeded', () {
      test(
        'throws FatalGatewayException after exceeding maxReconnectAttempts',
        () async {
          // Create a shard with maxReconnectAttempts = 1
          shard = _createShard(maxReconnectAttempts: 1, logger: logger);
          fakeClient = FakeWebsocketClient();
          shard.client = fakeClient;
          auth = shard.authentication;

          // First reconnect attempt (attempt 1) should succeed (log warning)
          final errors = <Object>[];
          runZonedGuarded(
            () {
              auth.reconnect();
            },
            (error, _) {
              errors.add(error);
            },
          );

          await Future<void>.delayed(Duration.zero);

          // Second reconnect attempt (attempt 2) exceeds max of 1
          runZonedGuarded(
            () {
              auth.reconnect();
            },
            (error, _) {
              errors.add(error);
            },
          );

          await Future<void>.delayed(Duration.zero);

          expect(errors.whereType<FatalGatewayException>(), isNotEmpty);
          expect(logger.errors, contains(contains('Max reconnect attempts')));
        },
      );

      test('throws FatalGatewayException with correct message', () async {
        shard = _createShard(maxReconnectAttempts: 0, logger: logger);
        fakeClient = FakeWebsocketClient();
        shard.client = fakeClient;
        auth = shard.authentication;

        FatalGatewayException? caught;
        runZonedGuarded(
          () {
            auth.reconnect();
          },
          (error, _) {
            if (error is FatalGatewayException) {
              caught = error;
            }
          },
        );

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
        }, (_, _) {});

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
        }, (_, _) {});

        await Future<void>.delayed(Duration.zero);

        final reconnectWarnings = logger.warnings
            .where((w) => w.contains('Reconnecting'))
            .toList();
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
        }, (_, _) {});

        await Future<void>.delayed(Duration.zero);

        // Reset the counter
        auth.resetReconnectAttempts();

        // Should be able to reconnect again from attempt 1
        runZonedGuarded(() {
          auth.reconnect();
        }, (_, _) {});

        await Future<void>.delayed(Duration.zero);

        // Both reconnect attempts should have logged "attempt 1/3"
        final attemptLogs = logger.warnings
            .where((w) => w.contains('attempt 1/'))
            .toList();
        expect(attemptLogs, hasLength(2));
      });

      test(
        'allows reconnection after previously hitting max attempts',
        () async {
          shard = _createShard(maxReconnectAttempts: 1, logger: logger);
          fakeClient = FakeWebsocketClient();
          shard.client = fakeClient;
          auth = shard.authentication;

          // First reconnect is allowed (attempt 1)
          runZonedGuarded(() {
            auth.reconnect();
          }, (_, _) {});

          await Future<void>.delayed(Duration.zero);

          // Second would throw FatalGatewayException
          runZonedGuarded(() {
            auth.reconnect();
          }, (_, _) {});

          await Future<void>.delayed(Duration.zero);

          // Reset counter
          auth.resetReconnectAttempts();

          // Should be able to reconnect again
          final errors = <Object>[];
          runZonedGuarded(
            () {
              auth.reconnect();
            },
            (error, _) {
              errors.add(error);
            },
          );

          await Future<void>.delayed(Duration.zero);

          // After reset, the reconnect should succeed (log a warning, not throw)
          final postResetWarnings = logger.warnings
              .where((w) => w.contains('Reconnecting'))
              .toList();
          expect(postResetWarnings.length, greaterThanOrEqualTo(2));
          expect(errors.whereType<FatalGatewayException>(), isEmpty);
        },
      );
    });

    // ── A5/A6 regression ────────────────────────────────────────────────

    group('A5 — a failed reconnect must not kill the shard for good', () {
      test(
        'a reconnect whose new connect() fails still schedules the next '
        'backoff attempt instead of leaving the shard permanently dead',
        () async {
          final orchestrator = _RealConnectOrchestrator(
            logger: logger,
            maxReconnectAttempts: 5,
          );
          final testShard = Shard(
            shardName: 'test-shard-0',
            shardIndex: 0,
            shardCount: 1,
            // Fails DNS resolution near-instantly (~tens of ms), so
            // WebsocketClientImpl.connect() reliably swallows the failure
            // and reports it via _onClose?.call(1006) — reproducing the
            // exact repro path from the bug report.
            url: 'wss://fake',
            wss: orchestrator,
            logger: logger,
            strategy: FakeRunningStrategy(),
          )..client = FakeWebsocketClient();

          final uncaughtErrors = <Object>[];
          await runZonedGuarded(() async {
            unawaited(testShard.authentication.reconnect());
            // Enough real time for: the first backoff (jitter <1s;
            // maxReconnectDelay is 0) + WebsocketClientImpl.connect() to
            // fail DNS lookup for the bogus host + the resulting
            // dispatch(1006) to schedule and log a SECOND reconnect
            // attempt's own "Reconnecting" warning before its own backoff.
            await Future<void>.delayed(const Duration(seconds: 2));
          }, (e, _) => uncaughtErrors.add(e));

          final reconnectWarnings = logger.warnings
              .where((w) => w.contains('Reconnecting'))
              .toList();

          expect(
            reconnectWarnings.length,
            greaterThanOrEqualTo(2),
            reason:
                'A connect() failure during a reconnect attempt must still '
                'result in a second reconnect being scheduled. Before the '
                'A5 fix, intentionalDisconnect stayed true for the whole '
                'reconnect attempt (cleared only by a successful IDENTIFY, '
                'which never arrives), so ShardNetworkError.dispatch(1006) '
                'silently no-opped and the shard went dead after exactly '
                'one log line.',
          );
          expect(
            uncaughtErrors,
            isEmpty,
            reason:
                'The connect failure must be fully handled, not leak '
                'into the zone',
          );

          testShard.authentication.cancelHeartbeat();
        },
      );
    });

    group('A6 — resume() must not drop the version/encoding query params', () {
      test(
        'resume() rebuilds the bare resume_gateway_url with ?v= and '
        'encoding= so shard.url keeps them for every later reconnect',
        () async {
          final orchestrator = _RealConnectOrchestrator(
            logger: logger,
            maxReconnectAttempts: 5,
          );
          final testShard = Shard(
            shardName: 'test-shard-0',
            shardIndex: 0,
            shardCount: 1,
            url: 'wss://fake',
            wss: orchestrator,
            logger: logger,
            strategy: FakeRunningStrategy(),
          )..client = FakeWebsocketClient();

          testShard.authentication.setupRequirements({
            'session_id': 'session-abc',
            // Discord returns this WITHOUT a query string, unlike the
            // initial /gateway/bot endpoint URL.
            'resume_gateway_url': 'wss://resume-host-does-not-exist',
          });

          final uncaughtErrors = <Object>[];
          await runZonedGuarded(() async {
            unawaited(testShard.authentication.resume());
            // Only needs to get past the first backoff delay to reach
            // shard.init(), which sets shard.url synchronously before ever
            // attempting to connect — the generous window also lets the
            // subsequent (harmless) connect failure and follow-up
            // reconnect play out without racing the assertions below.
            await Future<void>.delayed(const Duration(seconds: 2));
          }, (e, _) => uncaughtErrors.add(e));

          expect(testShard.url, startsWith('wss://resume-host-does-not-exist'));
          expect(
            testShard.url,
            contains('?v=10'),
            reason:
                'resume() must carry the version param forward, '
                'exactly like the initial connection URL',
          );
          expect(
            testShard.url,
            contains('encoding=json'),
            reason:
                'resume() must carry the encoding param forward — '
                'with encoding=etf this is what prevents Discord falling '
                'back to JSON text frames that EtfEncoderStrategy cannot '
                'decode',
          );

          testShard.authentication.cancelHeartbeat();
        },
      );
    });
  });
}
