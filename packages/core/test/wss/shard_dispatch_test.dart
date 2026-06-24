import 'dart:async';

import 'package:mineral/src/domains/services/packets/packet_dispatcher.dart';
import 'package:mineral/src/domains/services/packets/packet_type.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/domains/services/wss/running_strategy.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/wss/dispatchers/shard_authentication.dart';
import 'package:mineral/src/infrastructure/internals/wss/dispatchers/shard_data.dart';
import 'package:mineral/src/infrastructure/internals/wss/dispatchers/shard_network_error.dart';
import 'package:mineral/src/infrastructure/internals/wss/running_strategies/default_running_strategy.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:mineral/src/infrastructure/services/wss/websocket_message.dart';
import 'package:mineral/src/testing/fake_logger.dart';
import 'package:test/test.dart';

import '../helpers/fake_websocket_client.dart';
import '../helpers/fake_websocket_orchestrator.dart';
import '../helpers/mocks.dart';

// ── Helpers ────────────────────────────────────────────────────────────────

/// Minimal [PacketDispatcherContract] that records every payload dispatched.
final class _SpyPacketDispatcher implements PacketDispatcherContract {
  final List<dynamic> dispatched = [];

  @override
  void dispatch(dynamic payload) {
    dispatched.add(payload);
  }

  @override
  void listen(PacketTypeContract packet,
      Function(ShardMessage, DispatchEvent) listener) {}

  @override
  void dispose() {}
}

/// A [DefaultRunningStrategy] subclass that short-circuits the filesystem
/// pubspec read so tests do not need a real pubspec.yaml.
final class _NoPubspecStrategy extends DefaultRunningStrategy {
  _NoPubspecStrategy(super.packetDispatcher) : super(logger: FakeLogger());

  @override
  Future<Map> readPubspec(String location) async =>
      {'version': '5.0.0', 'dependencies': {}};
}

WebsocketMessage<ShardMessage> _message(ShardMessage content) =>
    WebsocketMessageImpl(
      channelName: 'test',
      originalContent: null,
      content: content,
    );

Shard _shard({required RunningStrategy strategy, FakeLogger? logger}) => Shard(
      shardName: 'test-shard-0',
      shardIndex: 0,
      shardCount: 1,
      url: 'wss://fake',
      wss: FakeWebsocketOrchestrator(),
      logger: logger ?? FakeLogger(),
      strategy: strategy,
    )..client = FakeWebsocketClient();

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  // ── DefaultRunningStrategy.dispatch ──────────────────────────────────────

  group('DefaultRunningStrategy.dispatch', () {
    late _SpyPacketDispatcher spy;
    late DefaultRunningStrategy strategy;

    setUp(() {
      spy = _SpyPacketDispatcher();
      strategy = _NoPubspecStrategy(spy);
    });

    test('forwards payload.content to packetDispatcher.dispatch', () {
      final msg = ShardMessage(
        type: 'GUILD_CREATE',
        opCode: OpCode.dispatch,
        sequence: 1,
        payload: {'id': '123'},
      );
      strategy.dispatch(_message(msg));

      expect(spy.dispatched, hasLength(1));
      expect(spy.dispatched.first, same(msg));
    });

    test('dispatches multiple messages in order', () {
      final messages = [
        ShardMessage(
            type: 'M1', opCode: OpCode.dispatch, sequence: 1, payload: {}),
        ShardMessage(
            type: 'M2', opCode: OpCode.dispatch, sequence: 2, payload: {}),
        ShardMessage(
            type: 'M3', opCode: OpCode.dispatch, sequence: 3, payload: {}),
      ];

      for (final m in messages) {
        strategy.dispatch(_message(m));
      }

      expect(spy.dispatched, hasLength(3));
      expect((spy.dispatched[0] as ShardMessage).type, equals('M1'));
      expect((spy.dispatched[1] as ShardMessage).type, equals('M2'));
      expect((spy.dispatched[2] as ShardMessage).type, equals('M3'));
    });

    test('dispatches messages with null type', () {
      final msg = ShardMessage(
        type: null,
        opCode: OpCode.heartbeatAck,
        sequence: null,
        payload: null,
      );
      strategy.dispatch(_message(msg));

      expect(spy.dispatched, hasLength(1));
    });
  });

  // ── DefaultRunningStrategy.init ───────────────────────────────────────────

  group('DefaultRunningStrategy.init', () {
    late _SpyPacketDispatcher spy;
    late _NoPubspecStrategy strategy;

    setUp(() {
      spy = _SpyPacketDispatcher();
      strategy = _NoPubspecStrategy(spy);
    });

    test('init calls createShards with the strategy itself', () async {
      RunningStrategy? received;
      await strategy.init((s) async {
        received = s;
      });

      expect(received, same(strategy));
    });

    test('init calls createShards exactly once', () async {
      var callCount = 0;
      await strategy.init((_) async {
        callCount++;
      });

      expect(callCount, equals(1));
    });

    test('init propagates exceptions from createShards', () async {
      expect(
        () => strategy.init((_) async => throw Exception('shard init failed')),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── Shard constructor wiring ──────────────────────────────────────────────

  group('Shard constructor wiring', () {
    test('creates ShardAuthentication linked to this shard', () {
      final shard = _shard(strategy: FakeRunningStrategy());
      shard.authentication.cancelHeartbeat();

      expect(shard.authentication, isA<ShardAuthentication>());
    });

    test('creates ShardNetworkError linked to this shard', () {
      final shard = _shard(strategy: FakeRunningStrategy());
      shard.authentication.cancelHeartbeat();

      expect(shard.networkError, isA<ShardNetworkError>());
    });

    test('creates ShardData (dispatchEvent) linked to this shard', () {
      final shard = _shard(strategy: FakeRunningStrategy());
      shard.authentication.cancelHeartbeat();

      expect(shard.dispatchEvent, isA<ShardData>());
    });

    test('exposes correct shardName', () {
      final shard = _shard(strategy: FakeRunningStrategy());
      shard.authentication.cancelHeartbeat();

      expect(shard.shardName, equals('test-shard-0'));
    });

    test('exposes correct shardIndex and shardCount', () {
      final shard = Shard(
        shardName: 'test-shard-2',
        shardIndex: 2,
        shardCount: 4,
        url: 'wss://fake',
        wss: FakeWebsocketOrchestrator(),
        logger: FakeLogger(),
        strategy: FakeRunningStrategy(),
      )..client = FakeWebsocketClient();
      shard.authentication.cancelHeartbeat();

      expect(shard.shardIndex, equals(2));
      expect(shard.shardCount, equals(4));
    });

    test('onceEventQueue starts empty', () {
      final shard = _shard(strategy: FakeRunningStrategy());
      shard.authentication.cancelHeartbeat();

      expect(shard.onceEventQueue, isEmpty);
    });
  });

  // ── Shard dispatch integration: ShardData → strategy ────────────────────

  group('Shard ShardData dispatch integration', () {
    late _SpyPacketDispatcher spy;
    late Shard shard;

    setUp(() {
      spy = _SpyPacketDispatcher();
      final strategy = _NoPubspecStrategy(spy);
      shard = Shard(
        shardName: 'test-shard-0',
        shardIndex: 0,
        shardCount: 1,
        url: 'wss://fake',
        wss: FakeWebsocketOrchestrator(),
        logger: FakeLogger(),
        strategy: strategy,
      )..client = FakeWebsocketClient();
    });

    tearDown(() {
      shard.authentication.cancelHeartbeat();
    });

    test('ShardData.dispatch delegates to the running strategy', () {
      final msg = _message(ShardMessage(
        type: 'MESSAGE_CREATE',
        opCode: OpCode.dispatch,
        sequence: 5,
        payload: {'content': 'hello'},
      ));

      shard.dispatchEvent.dispatch(msg);

      expect(spy.dispatched, hasLength(1));
      expect(
          (spy.dispatched.first as ShardMessage).type, equals('MESSAGE_CREATE'));
    });

    test('ShardData.dispatch updates shard sequence', () {
      shard.dispatchEvent.dispatch(_message(ShardMessage(
        type: 'CHANNEL_UPDATE',
        opCode: OpCode.dispatch,
        sequence: 77,
        payload: {},
      )));

      expect(shard.authentication.sequence, equals(77));
    });

    test('ShardData.dispatch stores READY payload in sessionId', () {
      shard.dispatchEvent.dispatch(_message(ShardMessage(
        type: 'READY',
        opCode: OpCode.dispatch,
        sequence: 1,
        payload: {
          'session_id': 'sess-abc',
          'resume_gateway_url': 'wss://resume.discord.gg',
        },
      )));

      expect(shard.authentication.sessionId, equals('sess-abc'));
      expect(
          shard.authentication.resumeUrl, equals('wss://resume.discord.gg'));
    });

    test('ShardData.dispatch handles null payload type gracefully', () {
      expect(
        () => shard.dispatchEvent.dispatch(_message(ShardMessage(
          type: null,
          opCode: OpCode.heartbeatAck,
          sequence: null,
          payload: null,
        ))),
        returnsNormally,
      );
    });
  });

  // ── Shard sequence tracking ───────────────────────────────────────────────

  group('Shard sequence tracking', () {
    late Shard shard;

    setUp(() {
      shard = _shard(strategy: FakeRunningStrategy());
    });

    tearDown(() {
      shard.authentication.cancelHeartbeat();
    });

    test('sequence starts null', () {
      expect(shard.authentication.sequence, isNull);
    });

    test('sequence is updated after each dispatch', () {
      shard.dispatchEvent.dispatch(_message(ShardMessage(
        type: 'EVT',
        opCode: OpCode.dispatch,
        sequence: 10,
        payload: {},
      )));

      expect(shard.authentication.sequence, equals(10));

      shard.dispatchEvent.dispatch(_message(ShardMessage(
        type: 'EVT',
        opCode: OpCode.dispatch,
        sequence: 20,
        payload: {},
      )));

      expect(shard.authentication.sequence, equals(20));
    });

    test('sequence is not overwritten by messages without a sequence', () {
      shard.authentication.sequence = 42;

      shard.dispatchEvent.dispatch(_message(ShardMessage(
        type: null,
        opCode: OpCode.heartbeatAck,
        sequence: null,
        payload: null,
      )));

      expect(shard.authentication.sequence, equals(42));
    });
  });
}
