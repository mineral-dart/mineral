import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:test/test.dart';

void main() {
  group('ShardMessage', () {
    group('ShardMessage.of', () {
      test('parses a DISPATCH message', () {
        final message = ShardMessage.of({
          'op': 0,
          't': 'MESSAGE_CREATE',
          's': 42,
          'd': {'content': 'hello'},
        });

        expect(message.opCode, OpCode.dispatch);
        expect(message.type, 'MESSAGE_CREATE');
        expect(message.sequence, 42);
        expect(message.payload, {'content': 'hello'});
      });

      test('parses a HELLO message', () {
        final message = ShardMessage.of({
          'op': 10,
          't': null,
          's': null,
          'd': {'heartbeat_interval': 41250},
        });

        expect(message.opCode, OpCode.hello);
        expect(message.type, isNull);
        expect(message.sequence, isNull);
        expect(message.payload['heartbeat_interval'], 41250);
      });

      test('parses a HEARTBEAT_ACK message', () {
        final message = ShardMessage.of({
          'op': 11,
          't': null,
          's': null,
          'd': null,
        });

        expect(message.opCode, OpCode.heartbeatAck);
        expect(message.payload, isNull);
      });

      test('parses an IDENTIFY message', () {
        final message = ShardMessage.of({
          'op': 2,
          't': null,
          's': null,
          'd': {'token': 'test'},
        });

        expect(message.opCode, OpCode.identify);
      });

      test('parses a RECONNECT message', () {
        final message = ShardMessage.of({
          'op': 7,
          't': null,
          's': null,
          'd': null,
        });

        expect(message.opCode, OpCode.reconnect);
      });

      test('parses an INVALID_SESSION message', () {
        final message = ShardMessage.of({
          'op': 9,
          't': null,
          's': null,
          'd': false,
        });

        expect(message.opCode, OpCode.invalidSession);
        expect(message.payload, false);
      });

      test('maps unknown opcode to OpCode.unknown', () {
        final message = ShardMessage.of({
          'op': 999,
          't': null,
          's': null,
          'd': null,
        });

        expect(message.opCode, OpCode.unknown);
      });

      test('handles READY dispatch event', () {
        final message = ShardMessage.of({
          'op': 0,
          't': 'READY',
          's': 1,
          'd': {
            'v': 10,
            'user': {'id': '123', 'username': 'TestBot'},
            'session_id': 'abc',
            'resume_gateway_url': 'wss://gateway.discord.gg',
          },
        });

        expect(message.opCode, OpCode.dispatch);
        expect(message.type, 'READY');
        expect(message.sequence, 1);
        expect(message.payload['session_id'], 'abc');
      });

      test('handles GUILD_CREATE dispatch event', () {
        final message = ShardMessage.of({
          'op': 0,
          't': 'GUILD_CREATE',
          's': 2,
          'd': {'id': '456', 'name': 'Test Guild'},
        });

        expect(message.type, 'GUILD_CREATE');
        expect(message.payload['name'], 'Test Guild');
      });
    });

    group('serialize', () {
      test('returns map with correct keys', () {
        final message = ShardMessage(
          type: 'MESSAGE_CREATE',
          opCode: OpCode.dispatch,
          sequence: 5,
          payload: {'content': 'test'},
        );

        final serialized = message.serialize() as Map<String, dynamic>;

        expect(serialized['t'], 'MESSAGE_CREATE');
        expect(serialized['op'], 0);
        expect(serialized['s'], 5);
        expect(serialized['d'], {'content': 'test'});
      });

      test('handles null values', () {
        final message = ShardMessage(
          type: null,
          opCode: OpCode.heartbeatAck,
          sequence: null,
          payload: null,
        );

        final serialized = message.serialize() as Map<String, dynamic>;

        expect(serialized['t'], isNull);
        expect(serialized['op'], 11);
        expect(serialized['s'], isNull);
        expect(serialized['d'], isNull);
      });

      test('roundtrip: of then serialize preserves data', () {
        final original = {
          'op': 0,
          't': 'TYPING_START',
          's': 10,
          'd': {'channel_id': '789', 'user_id': '123'},
        };

        final message = ShardMessage.of(original);
        final serialized = message.serialize() as Map<String, dynamic>;

        expect(serialized['op'], original['op']);
        expect(serialized['t'], original['t']);
        expect(serialized['s'], original['s']);
        expect(serialized['d'], original['d']);
      });
    });
  });
}
