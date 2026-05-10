import 'dart:convert';

import 'package:eterl/eterl.dart';
import 'package:mineral/src/domains/services/logger/logger_contract.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/wss/encoding_strategies/etf_encoder.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:mineral/src/infrastructure/io/exceptions/serialization_exception.dart';
import 'package:mineral/src/infrastructure/services/wss/websocket_message.dart';
import 'package:mineral/src/infrastructure/services/wss/websocket_requested_message.dart';
import 'package:test/test.dart';

final class _TestLogger implements LoggerContract {
  @override
  void trace(Object message) {}
  @override
  void fatal(Exception message) {}
  @override
  void error(String message) {}
  @override
  void warn(String message) {}
  @override
  void info(String message) {}
}

void main() {
  group('EtfEncoderStrategy', () {
    late EtfEncoderStrategy strategy;

    setUp(() {
      strategy = EtfEncoderStrategy(logger: _TestLogger());
    });

    test('encoder returns WsEncoder.etf', () {
      expect(strategy.encoder.value, 'etf');
    });

    group('decode', () {
      test('decodes ETF binary into ShardMessage', () {
        final data = {
          'op': 0,
          't': 'MESSAGE_CREATE',
          's': 1,
          'd': {'content': 'hello'},
        };

        final packed = eterl.pack(data);

        final wsMessage = WebsocketMessageImpl<ShardMessage>(
          channelName: 'shard-0',
          originalContent: packed,
          content: ShardMessage(
              type: null,
              opCode: OpCode.unknown,
              sequence: null,
              payload: null),
        );

        final result = strategy.decode(wsMessage);
        final content = result.content as ShardMessage;

        expect(content.opCode, OpCode.dispatch);
        expect(content.type, 'MESSAGE_CREATE');
        expect(content.sequence, 1);
        expect(content.payload['content'], 'hello');
      });

      test('throws SerializationException when original content is not bytes', () {
        final wsMessage = WebsocketMessageImpl<ShardMessage>(
          channelName: 'shard-0',
          originalContent: 'a plain string is not etf bytes',
          content: ShardMessage(
              type: null,
              opCode: OpCode.unknown,
              sequence: null,
              payload: null),
        );

        expect(() => strategy.decode(wsMessage),
            throwsA(isA<SerializationException>()));
      });

      test('decodes HELLO ETF message', () {
        final data = {
          'op': 10,
          't': null,
          's': null,
          'd': {'heartbeat_interval': 41250},
        };

        final packed = eterl.pack(data);

        final wsMessage = WebsocketMessageImpl<ShardMessage>(
          channelName: 'shard-0',
          originalContent: packed,
          content: ShardMessage(
              type: null,
              opCode: OpCode.unknown,
              sequence: null,
              payload: null),
        );

        final result = strategy.decode(wsMessage);
        final content = result.content as ShardMessage;

        expect(content.opCode, OpCode.hello);
        expect(content.payload['heartbeat_interval'], 41250);
      });
    });

    group('encode', () {
      test('encodes JSON string content to ETF binary', () {
        final jsonContent = jsonEncode({'op': 1, 'd': null});

        final message = WebsocketRequestedMessageImpl(
          channelName: 'shard-0',
          content: jsonContent,
        );

        final result = strategy.encode(message);

        // Content should now be binary (ETF packed)
        expect(result.content, isNotNull);

        // Verify we can unpack it back
        final unpacked = eterl.unpack<Map<String, dynamic>>(result.content as List<int>);
        expect(unpacked['op'], 1);
        expect(unpacked['d'], isNull);
      });

      test('roundtrip: encode then decode preserves data', () {
        final original = {
          'op': 0,
          't': 'TEST',
          's': 5,
          'd': {'key': 'value'}
        };
        final jsonString = jsonEncode(original);

        // Encode
        final requestMessage = WebsocketRequestedMessageImpl(
          channelName: 'shard-0',
          content: jsonString,
        );
        final encoded = strategy.encode(requestMessage);

        // Decode
        final wsMessage = WebsocketMessageImpl<ShardMessage>(
          channelName: 'shard-0',
          originalContent: encoded.content,
          content: ShardMessage(
              type: null,
              opCode: OpCode.unknown,
              sequence: null,
              payload: null),
        );
        final decoded = strategy.decode(wsMessage);
        final content = decoded.content as ShardMessage;

        expect(content.opCode, OpCode.dispatch);
        expect(content.type, 'TEST');
        expect(content.sequence, 5);
        expect(content.payload['key'], 'value');
      });
    });
  });
}
