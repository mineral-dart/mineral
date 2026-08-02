import 'dart:async';
import 'dart:io';

import 'package:mineral/src/domains/services/packets/packet_dispatcher.dart';
import 'package:mineral/src/domains/services/packets/packet_type.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/domains/services/wss/running_strategy.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/wss/dispatchers/shard_authentication.dart';
import 'package:mineral/src/infrastructure/internals/wss/dispatchers/shard_data.dart';
import 'package:mineral/src/infrastructure/internals/wss/dispatchers/shard_network_error.dart';
import 'package:mineral/src/infrastructure/internals/wss/encoding_strategies/etf_encoder.dart';
import 'package:mineral/src/infrastructure/internals/wss/running_strategies/default_running_strategy.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:mineral/src/infrastructure/io/exceptions/serialization_exception.dart';
import 'package:mineral/src/infrastructure/services/wss/websocket_client.dart';
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
  void listen(
    PacketTypeContract packet,
    Function(ShardMessage, DispatchEvent) listener,
  ) {}

  @override
  void dispose() {}
}

/// A [DefaultRunningStrategy] subclass that short-circuits the filesystem
/// pubspec read so tests do not need a real pubspec.yaml.
final class _NoPubspecStrategy extends DefaultRunningStrategy {
  _NoPubspecStrategy(super.packetDispatcher) : super(logger: FakeLogger());

  @override
  Future<Map> readPubspec(String location) async => {
    'version': '5.0.0',
    'dependencies': {},
  };
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
          type: 'M1',
          opCode: OpCode.dispatch,
          sequence: 1,
          payload: {},
        ),
        ShardMessage(
          type: 'M2',
          opCode: OpCode.dispatch,
          sequence: 2,
          payload: {},
        ),
        ShardMessage(
          type: 'M3',
          opCode: OpCode.dispatch,
          sequence: 3,
          payload: {},
        ),
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
      final msg = _message(
        ShardMessage(
          type: 'MESSAGE_CREATE',
          opCode: OpCode.dispatch,
          sequence: 5,
          payload: {'content': 'hello'},
        ),
      );

      shard.dispatchEvent.dispatch(msg);

      expect(spy.dispatched, hasLength(1));
      expect(
        (spy.dispatched.first as ShardMessage).type,
        equals('MESSAGE_CREATE'),
      );
    });

    test('ShardData.dispatch updates shard sequence', () {
      shard.dispatchEvent.dispatch(
        _message(
          ShardMessage(
            type: 'CHANNEL_UPDATE',
            opCode: OpCode.dispatch,
            sequence: 77,
            payload: {},
          ),
        ),
      );

      expect(shard.authentication.sequence, equals(77));
    });

    test('ShardData.dispatch stores READY payload in sessionId', () {
      shard.dispatchEvent.dispatch(
        _message(
          ShardMessage(
            type: 'READY',
            opCode: OpCode.dispatch,
            sequence: 1,
            payload: {
              'session_id': 'sess-abc',
              'resume_gateway_url': 'wss://resume.discord.gg',
            },
          ),
        ),
      );

      expect(shard.authentication.sessionId, equals('sess-abc'));
      expect(shard.authentication.resumeUrl, equals('wss://resume.discord.gg'));
    });

    test('ShardData.dispatch handles null payload type gracefully', () {
      expect(
        () => shard.dispatchEvent.dispatch(
          _message(
            ShardMessage(
              type: null,
              opCode: OpCode.heartbeatAck,
              sequence: null,
              payload: null,
            ),
          ),
        ),
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
      shard.dispatchEvent.dispatch(
        _message(
          ShardMessage(
            type: 'EVT',
            opCode: OpCode.dispatch,
            sequence: 10,
            payload: {},
          ),
        ),
      );

      expect(shard.authentication.sequence, equals(10));

      shard.dispatchEvent.dispatch(
        _message(
          ShardMessage(
            type: 'EVT',
            opCode: OpCode.dispatch,
            sequence: 20,
            payload: {},
          ),
        ),
      );

      expect(shard.authentication.sequence, equals(20));
    });

    test('sequence is not overwritten by messages without a sequence', () {
      shard.authentication.sequence = 42;

      shard.dispatchEvent.dispatch(
        _message(
          ShardMessage(
            type: null,
            opCode: OpCode.heartbeatAck,
            sequence: null,
            payload: null,
          ),
        ),
      );

      expect(shard.authentication.sequence, equals(42));
    });
  });

  // ── A7 regression: opcode-triggered futures must not become unhandled ───

  group('Shard.handleGatewayMessage — A7 (opcode-triggered futures must not '
      'become unhandled)', () {
    Shard fatalShard({
      required FakeLogger logger,
      required Future<void> Function() onFatalDisconnect,
    }) {
      final wss = FakeWebsocketOrchestrator(maxReconnectAttempts: 0)
        ..onFatalDisconnect = onFatalDisconnect;
      return Shard(
        shardName: 'test-shard-0',
        shardIndex: 0,
        shardCount: 1,
        url: 'wss://fake',
        wss: wss,
        logger: logger,
        strategy: FakeRunningStrategy(),
      )..client = FakeWebsocketClient();
    }

    test(
      'OpCode.reconnect: a FatalGatewayException from reconnect() is '
      'routed to the fatal-shutdown handler instead of escaping the zone',
      () async {
        var fatalCalled = false;
        final shard = fatalShard(
          logger: FakeLogger(),
          onFatalDisconnect: () async {
            fatalCalled = true;
          },
        );

        final uncaughtErrors = <Object>[];
        await runZonedGuarded(() async {
          shard.handleGatewayMessage(
            _message(
              ShardMessage(
                type: null,
                opCode: OpCode.reconnect,
                sequence: null,
                payload: null,
              ),
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }, (e, _) => uncaughtErrors.add(e));

        expect(
          uncaughtErrors,
          isEmpty,
          reason:
              'Before the A7 fix, authentication.reconnect() was called '
              'bare (its Future discarded); once maxReconnectAttempts is '
              'exceeded it throws FatalGatewayException, which becomes an '
              'unhandled error in the root zone and kills the process.',
        );
        expect(
          fatalCalled,
          isTrue,
          reason:
              'the exception must reach the graceful fatal-shutdown '
              'path, not just avoid crashing',
        );

        shard.authentication.cancelHeartbeat();
      },
    );

    test('OpCode.invalidSession (payload=true): a FatalGatewayException from '
        'resume() is routed to the fatal-shutdown handler', () async {
      var fatalCalled = false;
      final shard = fatalShard(
        logger: FakeLogger(),
        onFatalDisconnect: () async {
          fatalCalled = true;
        },
      );

      final uncaughtErrors = <Object>[];
      await runZonedGuarded(() async {
        shard.handleGatewayMessage(
          _message(
            ShardMessage(
              type: null,
              opCode: OpCode.invalidSession,
              sequence: null,
              payload: true,
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }, (e, _) => uncaughtErrors.add(e));

      expect(uncaughtErrors, isEmpty);
      expect(fatalCalled, isTrue);

      shard.authentication.cancelHeartbeat();
    });

    test('OpCode.invalidSession (payload=false): a FatalGatewayException '
        'from reconnect() is routed to the fatal-shutdown handler', () async {
      var fatalCalled = false;
      final shard = fatalShard(
        logger: FakeLogger(),
        onFatalDisconnect: () async {
          fatalCalled = true;
        },
      );

      final uncaughtErrors = <Object>[];
      await runZonedGuarded(() async {
        shard.handleGatewayMessage(
          _message(
            ShardMessage(
              type: null,
              opCode: OpCode.invalidSession,
              sequence: null,
              payload: false,
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }, (e, _) => uncaughtErrors.add(e));

      expect(uncaughtErrors, isEmpty);
      expect(fatalCalled, isTrue);

      shard.authentication.cancelHeartbeat();
    });

    test('OpCode.heartbeat: a FatalGatewayException from '
        "heartbeat()'s resetConnection() (3 failed attempts) is routed to "
        'the fatal-shutdown handler', () async {
      var fatalCalled = false;
      final shard = fatalShard(
        logger: FakeLogger(),
        onFatalDisconnect: () async {
          fatalCalled = true;
        },
      );
      shard.authentication.attempts = 3;

      final uncaughtErrors = <Object>[];
      await runZonedGuarded(() async {
        shard.handleGatewayMessage(
          _message(
            ShardMessage(
              type: null,
              opCode: OpCode.heartbeat,
              sequence: null,
              payload: null,
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }, (e, _) => uncaughtErrors.add(e));

      expect(uncaughtErrors, isEmpty);
      expect(fatalCalled, isTrue);

      shard.authentication.cancelHeartbeat();
    });
  });

  // ── A16 regression: malformed ETF frames must not kill the isolate ──────

  group('EtfEncoderStrategy.decode — A16 (malformed ETF frames must not kill '
      'the isolate)', () {
    WebsocketMessage rawMessage(List<int> bytes) => WebsocketMessageImpl(
      channelName: 'test',
      originalContent: bytes,
      content: bytes,
    );

    test('a truncated frame (RangeError from eterl) is converted to '
        'SerializationException, not left as a raw Error', () {
      final strategy = EtfEncoderStrategy(logger: FakeLogger());
      // ETF version byte (131) + binaryExt tag (109) with no
      // length/payload bytes: eterl's Decoder._read32() reads past the
      // end of the 2-byte buffer and throws RangeError.
      final message = rawMessage([131, 109]);

      expect(
        () => strategy.decode(message),
        throwsA(isA<SerializationException>()),
        reason:
            "eterl 1.1.0's decoder has no bounds checking. Before the "
            'A16 fix, decode() only caught SerializationException/'
            'Exception, so this RangeError (an Error) escaped raw and '
            'would have killed the isolate at the caller.',
      );
    });

    test('a deeply nested frame (StackOverflowError from eterl) is '
        'converted to SerializationException', () {
      final strategy = EtfEncoderStrategy(logger: FakeLogger());
      // 200k levels of smallTupleExt(arity 1) nesting: decode()
      // recurses once per level with no depth limit, overflowing the
      // stack.
      final bytes = <int>[131];
      for (var i = 0; i < 200000; i++) {
        bytes.addAll([104, 1]);
      }
      bytes.addAll([97, 1]); // smallIntegerExt leaf
      final message = rawMessage(bytes);

      expect(
        () => strategy.decode(message),
        throwsA(isA<SerializationException>()),
      );
    });

    test('a well-formed frame still decodes normally', () {
      final strategy = EtfEncoderStrategy(logger: FakeLogger());
      // smallIntegerExt(1) wrapped in a 1-arity smallTupleExt is not a
      // map, so decode via a minimal valid map instead: mapExt with 0
      // entries -> {}.
      final message = rawMessage([131, 116, 0, 0, 0, 0]);

      final decoded = strategy.decode(message);

      expect(decoded.content, isA<ShardMessage>());
    });
  });

  // ── A16 regression: WebsocketClientImpl defense-in-depth ────────────────

  group('WebsocketClientImpl._handleMessage — A16 (a raw Error from an '
      'interceptor must not kill the isolate)', () {
    test('a frame is dropped (not delivered, not thrown) when a message '
        'interceptor throws a raw Error', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        final socket = await WebSocketTransformer.upgrade(request);
        socket.add('trigger');
      });

      final logger = FakeLogger();
      final client = WebsocketClientImpl(
        url: 'ws://127.0.0.1:${server.port}',
        logger: logger,
      );
      client.interceptor.message.add((message) {
        // Simulates an encoding strategy (or any other interceptor)
        // that slips a raw Error through instead of converting it to
        // SerializationException.
        throw RangeError('simulated malformed frame');
      });

      final received = <dynamic>[];
      final uncaughtErrors = <Object>[];
      await runZonedGuarded(() async {
        await client.listen(received.add);
        await client.connect();
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }, (e, _) => uncaughtErrors.add(e));

      expect(
        received,
        isEmpty,
        reason: 'the malformed frame must be dropped, not delivered',
      );
      expect(
        uncaughtErrors,
        isEmpty,
        reason:
            'Before the A16 fix, _handleMessage only caught '
            'SerializationException, so this raw RangeError would have '
            'escaped and killed the isolate instead of just dropping '
            'the one bad frame.',
      );
      expect(logger.warnings, contains(contains('malformed gateway frame')));

      await client.disconnect();
    });
  });
}
