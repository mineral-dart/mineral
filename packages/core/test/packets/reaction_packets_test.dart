/// Tests for MESSAGE_REACTION_ADD, MESSAGE_REACTION_REMOVE, and
/// MESSAGE_REACTION_REMOVE_ALL.
library;

import 'package:mineral/api.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/message_reaction_add_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/message_reaction_remove_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:test/test.dart';

import '../helpers/fake_cache_provider.dart';
import '../helpers/fake_marshaller.dart';

// ── IDs ───────────────────────────────────────────────────────────────────────

const _guildId = '123456789012345678';
const _channelId = '777888999000111222';
const _messageId = '111222333444555666';
const _userId = '999888777666555444';

// ── Payloads ──────────────────────────────────────────────────────────────────

Map<String, dynamic> _reactionPayload({bool includeGuild = true}) => {
      'user_id': _userId,
      'channel_id': _channelId,
      'message_id': _messageId,
      if (includeGuild) 'guild_id': _guildId,
      'emoji': {'id': null, 'name': '👍', 'animated': false},
      'burst': false,
      'type': 0, // NORMAL
    };


ShardMessage<dynamic> _msg(String type, Map<String, dynamic> payload) =>
    ShardMessage(
      type: type,
      opCode: OpCode.dispatch,
      sequence: 1,
      payload: payload,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeCacheProvider cache;
  late FakeMarshaller marshaller;

  setUp(() {
    cache = FakeCacheProvider();
    marshaller = FakeMarshaller(cache: cache);
  });

  // ── MESSAGE_REACTION_ADD ───────────────────────────────────────────────────

  group('MessageReactionAddPacket', () {
    test('packetType is PacketType.messageReactionAdd', () {
      final packet = MessageReactionAddPacket(marshaller: marshaller);
      expect(packet.packetType, equals(PacketType.messageReactionAdd));
      expect(packet.packetType.name, equals('MESSAGE_REACTION_ADD'));
    });

    test('dispatches Event.guildMessageReactionAdd for guild reaction', () async {
      final packet = MessageReactionAddPacket(marshaller: marshaller);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(
          _msg('MESSAGE_REACTION_ADD', _reactionPayload(includeGuild: true)),
          dispatch);

      expect(capturedEvent, equals(Event.guildMessageReactionAdd));
    });

    test('payload is GuildMessageReactionAddArgs with reaction', () async {
      final packet = MessageReactionAddPacket(marshaller: marshaller);
      GuildMessageReactionAddArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildMessageReactionAdd) {
          args = payload as GuildMessageReactionAddArgs;
        }
      }

      await packet.listen(
          _msg('MESSAGE_REACTION_ADD', _reactionPayload(includeGuild: true)),
          dispatch);

      expect(args, isNotNull);
      expect(args!.reaction, isA<MessageReaction>());
    });

    test('dispatches Event.privateMessageReactionAdd for DM reaction', () async {
      final packet = MessageReactionAddPacket(marshaller: marshaller);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(
          _msg('MESSAGE_REACTION_ADD', _reactionPayload(includeGuild: false)),
          dispatch);

      expect(capturedEvent, equals(Event.privateMessageReactionAdd));
    });
  });

  // ── MESSAGE_REACTION_REMOVE ────────────────────────────────────────────────

  group('MessageReactionRemovePacket', () {
    test('packetType is PacketType.messageReactionRemove', () {
      final packet = MessageReactionRemovePacket(marshaller: marshaller);
      expect(packet.packetType, equals(PacketType.messageReactionRemove));
      expect(packet.packetType.name, equals('MESSAGE_REACTION_REMOVE'));
    });

    test('dispatches Event.guildMessageReactionRemove for guild reaction',
        () async {
      final packet = MessageReactionRemovePacket(marshaller: marshaller);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(
          _msg('MESSAGE_REACTION_REMOVE', _reactionPayload(includeGuild: true)),
          dispatch);

      expect(capturedEvent, equals(Event.guildMessageReactionRemove));
    });

    test('dispatches Event.privateMessageReactionRemove for DM reaction',
        () async {
      final packet = MessageReactionRemovePacket(marshaller: marshaller);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(
          _msg('MESSAGE_REACTION_REMOVE', _reactionPayload(includeGuild: false)),
          dispatch);

      expect(capturedEvent, equals(Event.privateMessageReactionRemove));
    });
  });
}
