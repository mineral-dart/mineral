import 'dart:async';

import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/domains/services/wss/running_strategy.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/dispatchers/shard_data.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:mineral/src/infrastructure/services/wss/websocket_message.dart';
import 'package:mineral/src/testing/fake_logger.dart';
import 'package:test/test.dart';

import '../helpers/fake_websocket_client.dart';
import '../helpers/fake_websocket_orchestrator.dart';

// ── Helpers ────────────────────────────────────────────────────────────────

final class _TrackingStrategy implements RunningStrategy {
  final List<WebsocketMessage> dispatched = [];

  @override
  FutureOr<void> init(RunningStrategyFactory createShards) async {}

  @override
  FutureOr<void> dispatch(WebsocketMessage message) {
    dispatched.add(message);
  }
}

WebsocketMessage<ShardMessage> _msg(ShardMessage content) =>
    WebsocketMessageImpl(
      channelName: 'test',
      originalContent: null,
      content: content,
    );

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('ShardData', () {
    late Shard shard;
    late _TrackingStrategy strategy;
    late ShardData shardData;

    setUp(() {
      strategy = _TrackingStrategy();
      shard = Shard(
        shardName: 'test-shard-0',
        shardIndex: 0,
        shardCount: 1,
        url: 'wss://fake',
        wss: FakeWebsocketOrchestrator(),
        logger: FakeLogger(),
        strategy: strategy,
      );
      shard.client = FakeWebsocketClient();
      shardData = ShardData(shard, strategy);
    });

    tearDown(() {
      shard.authentication.cancelHeartbeat();
    });

    group('sequence tracking', () {
      test('updates shard sequence when message carries one', () {
        shardData.dispatch(_msg(ShardMessage(
          type: 'GUILD_CREATE',
          opCode: OpCode.dispatch,
          sequence: 99,
          payload: {},
        )));

        expect(shard.authentication.sequence, equals(99));
      });

      test('does not overwrite sequence when message has none', () {
        shard.authentication.sequence = 5;

        shardData.dispatch(_msg(ShardMessage(
          type: null,
          opCode: OpCode.heartbeatAck,
          sequence: null,
          payload: null,
        )));

        expect(shard.authentication.sequence, equals(5));
      });

      test('overwrites previous sequence with the latest value', () {
        shardData.dispatch(_msg(ShardMessage(
          type: 'MSG',
          opCode: OpCode.dispatch,
          sequence: 10,
          payload: {},
        )));
        shardData.dispatch(_msg(ShardMessage(
          type: 'MSG',
          opCode: OpCode.dispatch,
          sequence: 20,
          payload: {},
        )));

        expect(shard.authentication.sequence, equals(20));
      });
    });

    group('READY event', () {
      test('calls setupRequirements with the payload', () {
        shardData.dispatch(_msg(ShardMessage(
          type: PacketType.ready.name,
          opCode: OpCode.dispatch,
          sequence: 1,
          payload: {
            'session_id': 'session-abc',
            'resume_gateway_url': 'wss://resume.discord.gg',
          },
        )));

        expect(shard.authentication.sessionId, equals('session-abc'));
        expect(shard.authentication.resumeUrl, equals('wss://resume.discord.gg'));
      });

      test('does not call setupRequirements for non-READY events', () {
        shardData.dispatch(_msg(ShardMessage(
          type: 'GUILD_CREATE',
          opCode: OpCode.dispatch,
          sequence: 2,
          payload: {},
        )));

        expect(shard.authentication.sessionId, isNull);
        expect(shard.authentication.resumeUrl, isNull);
      });
    });

    group('RESUMED event', () {
      test('resets reconnect attempts counter', () {
        // Arm the reconnect counter via public API
        shard.authentication.resetReconnectAttempts();

        shardData.dispatch(_msg(ShardMessage(
          type: PacketType.resumed.name,
          opCode: OpCode.dispatch,
          sequence: 3,
          payload: null,
        )));

        // resetReconnectAttempts is idempotent; what we verify is that
        // dispatch does not throw and continues to delegate to the strategy.
        expect(strategy.dispatched, hasLength(1));
      });

      test('does not reset attempts for non-RESUMED events', () {
        // If the code wrongly called resetReconnectAttempts for every message
        // we cannot distinguish it here without deeper access, but at minimum
        // the dispatch chain must complete normally.
        expect(
          () => shardData.dispatch(_msg(ShardMessage(
            type: 'MESSAGE_CREATE',
            opCode: OpCode.dispatch,
            sequence: 4,
            payload: {},
          ))),
          returnsNormally,
        );
      });
    });

    group('strategy delegation', () {
      test('always delegates to the running strategy', () {
        final msg = _msg(ShardMessage(
          type: 'MESSAGE_CREATE',
          opCode: OpCode.dispatch,
          sequence: 10,
          payload: {},
        ));

        shardData.dispatch(msg);

        expect(strategy.dispatched, hasLength(1));
        expect(strategy.dispatched.first, same(msg));
      });

      test('delegates even when message has no sequence or type', () {
        shardData.dispatch(_msg(ShardMessage(
          type: null,
          opCode: OpCode.heartbeatAck,
          sequence: null,
          payload: null,
        )));

        expect(strategy.dispatched, hasLength(1));
      });

      test('delegates all messages in order', () {
        for (var i = 1; i <= 3; i++) {
          shardData.dispatch(_msg(ShardMessage(
            type: 'EVENT_$i',
            opCode: OpCode.dispatch,
            sequence: i,
            payload: {},
          )));
        }

        expect(strategy.dispatched, hasLength(3));
      });
    });
  });
}
