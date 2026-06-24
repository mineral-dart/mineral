import 'package:mineral/api.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/message_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:test/test.dart';

import '../helpers/fake_cache_provider.dart';
import '../helpers/fake_marshaller.dart';

void main() {
  group('MessageUpdatePacket', () {
    late FakeCacheProvider cache;
    late FakeMarshaller marshaller;
    late MessageUpdatePacket packet;

    /// A minimal raw Discord MESSAGE_UPDATE payload for a guild (guild) message.
    Map<String, dynamic> rawServerPayload() => {
      'id': '111222333444555666',
      'channel_id': '777888999000111222',
      'guild_id': '123456789012345678',
      'author': {'id': '987654321098765432', 'bot': false},
      'content': 'edited content',
      'embeds': <Map<String, dynamic>>[],
      'timestamp': '2024-06-01T12:00:00.000Z',
      'edited_timestamp': '2024-06-01T12:05:00.000Z',
    };

    /// A minimal raw Discord MESSAGE_UPDATE payload for a private (DM) message.
    Map<String, dynamic> rawPrivatePayload() => {
      'id': '111222333444555666',
      'channel_id': '777888999000111222',
      // no guild_id → private message
      'author': {'id': '987654321098765432', 'bot': false},
      'content': 'edited DM content',
      'embeds': <Map<String, dynamic>>[],
      'timestamp': '2024-06-01T12:00:00.000Z',
      'edited_timestamp': '2024-06-01T12:05:00.000Z',
    };

    ShardMessage<dynamic> buildMessage(Map<String, dynamic> payload) =>
        ShardMessage(
          type: 'MESSAGE_UPDATE',
          opCode: OpCode.dispatch,
          sequence: 1,
          payload: payload,
        );

    setUp(() {
      cache = FakeCacheProvider();
      marshaller = FakeMarshaller(cache: cache);
      packet = MessageUpdatePacket(marshaller: marshaller);
    });

    // ── packetType identity ──────────────────────────────────────────────────

    test('packetType is PacketType.messageUpdate', () {
      expect(packet.packetType, equals(PacketType.messageUpdate));
      expect(packet.packetType.name, equals('MESSAGE_UPDATE'));
    });

    // ── guild branch ────────────────────────────────────────────────────────

    test('dispatches Event.guildMessageUpdate for guild messages', () async {
      Event? capturedEvent;
      Object? capturedPayload;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        capturedEvent = event;
        capturedPayload = payload;
      }

      await packet.listen(buildMessage(rawServerPayload()), dispatch);

      expect(capturedEvent, equals(Event.guildMessageUpdate));
      expect(capturedPayload, isA<GuildMessageUpdateArgs>());

      final args = capturedPayload as GuildMessageUpdateArgs;
      expect(args.after.id, equals(Snowflake('111222333444555666')));
      expect(args.after.content, equals('edited content'));
    });

    test('before is null on cache miss (guild message)', () async {
      GuildMessageUpdateArgs? capturedArgs;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        if (event == Event.guildMessageUpdate) {
          capturedArgs = payload as GuildMessageUpdateArgs;
        }
      }

      await packet.listen(buildMessage(rawServerPayload()), dispatch);

      expect(capturedArgs, isNotNull);
      expect(capturedArgs!.before, isNull);
    });

    test('before is populated when guild message is already in cache', () async {
      // Pre-populate the cache with the old message state (normalized format).
      final messageCacheKey = marshaller.cacheKey.message(
        '777888999000111222',
        '111222333444555666',
      );
      await cache.put(messageCacheKey, {
        'id': '111222333444555666',
        'author_id': '987654321098765432',
        'content': 'original content',
        'embeds': <Map<String, dynamic>>[],
        'channel_id': '777888999000111222',
        'guild_id': '123456789012345678',
        'author_is_bot': false,
        'timestamp': '2024-06-01T12:00:00.000Z',
        'edited_timestamp': null,
      });

      GuildMessageUpdateArgs? capturedArgs;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        if (event == Event.guildMessageUpdate) {
          capturedArgs = payload as GuildMessageUpdateArgs;
        }
      }

      await packet.listen(buildMessage(rawServerPayload()), dispatch);

      expect(capturedArgs, isNotNull);
      expect(capturedArgs!.before, isNotNull);
      expect(capturedArgs!.before!.content, equals('original content'));
      expect(capturedArgs!.after.content, equals('edited content'));
    });

    // ── private branch ───────────────────────────────────────────────────────

    test('dispatches Event.privateMessageUpdate for DM messages', () async {
      Event? capturedEvent;
      Object? capturedPayload;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        capturedEvent = event;
        capturedPayload = payload;
      }

      await packet.listen(buildMessage(rawPrivatePayload()), dispatch);

      expect(capturedEvent, equals(Event.privateMessageUpdate));
      expect(capturedPayload, isA<PrivateMessageUpdateArgs>());

      final args = capturedPayload as PrivateMessageUpdateArgs;
      expect(args.after.id, equals(Snowflake('111222333444555666')));
      expect(args.after.content, equals('edited DM content'));
    });

    test('before is null on cache miss (private message)', () async {
      PrivateMessageUpdateArgs? capturedArgs;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        if (event == Event.privateMessageUpdate) {
          capturedArgs = payload as PrivateMessageUpdateArgs;
        }
      }

      await packet.listen(buildMessage(rawPrivatePayload()), dispatch);

      expect(capturedArgs, isNotNull);
      expect(capturedArgs!.before, isNull);
    });

    test(
      'before is populated when private message is already in cache',
      () async {
        final messageCacheKey = marshaller.cacheKey.message(
          '777888999000111222',
          '111222333444555666',
        );
        await cache.put(messageCacheKey, {
          'id': '111222333444555666',
          'author_id': '987654321098765432',
          'content': 'original DM content',
          'embeds': <Map<String, dynamic>>[],
          'channel_id': '777888999000111222',
          'guild_id': null,
          'author_is_bot': false,
          'timestamp': '2024-06-01T12:00:00.000Z',
          'edited_timestamp': null,
        });

        PrivateMessageUpdateArgs? capturedArgs;

        void dispatch<T extends Object>({
          required Event event,
          required T payload,
          bool Function(String?)? constraint,
        }) {
          if (event == Event.privateMessageUpdate) {
            capturedArgs = payload as PrivateMessageUpdateArgs;
          }
        }

        await packet.listen(buildMessage(rawPrivatePayload()), dispatch);

        expect(capturedArgs, isNotNull);
        expect(capturedArgs!.before, isNotNull);
        expect(capturedArgs!.before!.content, equals('original DM content'));
        expect(capturedArgs!.after.content, equals('edited DM content'));
      },
    );

    // ── cache updated after dispatch ─────────────────────────────────────────

    test('cache is updated with new message data after dispatch', () async {
      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {}

      await packet.listen(buildMessage(rawServerPayload()), dispatch);

      final messageCacheKey = marshaller.cacheKey.message(
        '777888999000111222',
        '111222333444555666',
      );
      final cached = await cache.get(messageCacheKey);

      expect(cached, isNotNull);
      expect(cached!['content'], equals('edited content'));
    });
  });
}
