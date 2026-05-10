import 'dart:convert';

import 'package:mineral/src/domains/services/logger/logger_contract.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/wss/encoding_strategies/json_encoder.dart';
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
  group('JsonEncoderStrategy', () {
    late JsonEncoderStrategy strategy;

    setUp(() {
      strategy = JsonEncoderStrategy(logger: _TestLogger());
    });

    test('encoder returns WsEncoder.json', () {
      expect(strategy.encoder.value, 'json');
    });

    group('decode', () {
      test('parses JSON string into ShardMessage', () {
        final jsonString = jsonEncode({
          'op': 0,
          't': 'MESSAGE_CREATE',
          's': 1,
          'd': {'content': 'hello'},
        });

        final wsMessage = WebsocketMessageImpl<ShardMessage>(
          channelName: 'shard-0',
          originalContent: jsonString,
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

      test('parses HELLO message', () {
        final jsonString = jsonEncode({
          'op': 10,
          't': null,
          's': null,
          'd': {'heartbeat_interval': 41250},
        });

        final wsMessage = WebsocketMessageImpl<ShardMessage>(
          channelName: 'shard-0',
          originalContent: jsonString,
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

      test('throws SerializationException on invalid JSON', () {
        final wsMessage = WebsocketMessageImpl<ShardMessage>(
          channelName: 'shard-0',
          originalContent: 'not-valid-json{{{',
          content: ShardMessage(
              type: null,
              opCode: OpCode.unknown,
              sequence: null,
              payload: null),
        );

        expect(() => strategy.decode(wsMessage),
            throwsA(isA<SerializationException>()));
      });

      test('throws SerializationException when original content is not a string', () {
        final wsMessage = WebsocketMessageImpl<ShardMessage>(
          channelName: 'shard-0',
          originalContent: <int>[1, 2, 3],
          content: ShardMessage(
              type: null,
              opCode: OpCode.unknown,
              sequence: null,
              payload: null),
        );

        expect(() => strategy.decode(wsMessage),
            throwsA(isA<SerializationException>()));
      });

      test('throws SerializationException when JSON root is not an object', () {
        final wsMessage = WebsocketMessageImpl<ShardMessage>(
          channelName: 'shard-0',
          originalContent: '[1, 2, 3]',
          content: ShardMessage(
              type: null,
              opCode: OpCode.unknown,
              sequence: null,
              payload: null),
        );

        expect(() => strategy.decode(wsMessage),
            throwsA(isA<SerializationException>()));
      });
    });

    group('encode', () {
      test('returns message as-is (pass-through)', () {
        final message = WebsocketRequestedMessageImpl(
          channelName: 'shard-0',
          content: '{"op":1,"d":null}',
        );

        final result = strategy.encode(message);

        expect(result.content, '{"op":1,"d":null}');
        expect(result.channelName, 'shard-0');
        expect(identical(result, message), isTrue);
      });
    });
  });
}
