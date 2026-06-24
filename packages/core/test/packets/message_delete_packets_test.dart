/// Tests for MESSAGE_DELETE and MESSAGE_DELETE_BULK.
library;

import 'package:mineral/api.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/api/guild/managers/threads_manager.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/message_delete_bulk_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/message_delete_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../helpers/fake_cache_provider.dart';
import '../helpers/fake_marshaller.dart';
import '../helpers/fake_websocket_orchestrator.dart';
import '../helpers/mocks.dart';
import 'helpers/packet_test_helpers.dart';

// ── IDs ───────────────────────────────────────────────────────────────────────

const _guildId = '123456789012345678';
const _channelId = '777888999000111222';
const _messageId = '111222333444555666';
const _messageId2 = '222333444555666777';

// ── Payloads ──────────────────────────────────────────────────────────────────

Map<String, dynamic> _deletePayload({bool includeGuild = true}) => {
  'id': _messageId,
  'channel_id': _channelId,
  if (includeGuild) 'guild_id': _guildId,
};

Map<String, dynamic> _deleteBulkPayload() => {
  'ids': [_messageId, _messageId2],
  'channel_id': _channelId,
  'guild_id': _guildId,
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
  late Guild fakeGuild;
  late GuildTextChannel fakeChannel;
  late MockDataStore dataStore;

  setUp(() {
    final wss = FakeWebsocketOrchestrator();
    cache = FakeCacheProvider();

    dataStore = MockDataStore();

    final ctx = buildCtx(dataStore: dataStore, wss: wss);
    fakeGuild = buildMinimalGuild(_guildId, ctx);
    fakeChannel = _buildGuildTextChannel(ctx);

    when(() => dataStore.guild).thenReturn(FakeGuildPart(fakeGuild));
    when(() => dataStore.channel).thenReturn(FakeChannelPart(fakeChannel));

    marshaller = FakeMarshaller(
      cache: cache,
      entityContext: buildCtx(dataStore: dataStore, wss: wss),
    );
  });

  // ── MESSAGE_DELETE ─────────────────────────────────────────────────────────

  group('MessageDeletePacket', () {
    test('packetType is PacketType.messageDelete', () {
      final packet = MessageDeletePacket(
        marshaller: marshaller,
        dataStore: dataStore,
      );
      expect(packet.packetType, equals(PacketType.messageDelete));
      expect(packet.packetType.name, equals('MESSAGE_DELETE'));
    });

    test('dispatches Event.guildMessageDelete for guild message', () async {
      final packet = MessageDeletePacket(
        marshaller: marshaller,
        dataStore: dataStore,
      );
      Event? capturedEvent;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        capturedEvent = event;
      }

      await packet.listen(
        _msg('MESSAGE_DELETE', _deletePayload(includeGuild: true)),
        dispatch,
      );

      expect(capturedEvent, equals(Event.guildMessageDelete));
    });

    test(
      'payload carries guild, channel and messageId for guild delete',
      () async {
        final packet = MessageDeletePacket(
          marshaller: marshaller,
          dataStore: dataStore,
        );
        GuildMessageDeleteArgs? args;

        void dispatch<T extends Object>({
          required Event event,
          required T payload,
          bool Function(String?)? constraint,
        }) {
          if (event == Event.guildMessageDelete) {
            args = payload as GuildMessageDeleteArgs;
          }
        }

        await packet.listen(
          _msg('MESSAGE_DELETE', _deletePayload(includeGuild: true)),
          dispatch,
        );

        expect(args, isNotNull);
        expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
        expect(args!.channel.id, equals(Snowflake.parse(_channelId)));
        expect(args!.messageId, equals(Snowflake.parse(_messageId)));
      },
    );

    test('message is null in payload on cache miss', () async {
      final packet = MessageDeletePacket(
        marshaller: marshaller,
        dataStore: dataStore,
      );
      GuildMessageDeleteArgs? args;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        if (event == Event.guildMessageDelete) {
          args = payload as GuildMessageDeleteArgs;
        }
      }

      await packet.listen(
        _msg('MESSAGE_DELETE', _deletePayload(includeGuild: true)),
        dispatch,
      );

      expect(args!.message, isNull);
    });

    test('message is invalidated from cache on delete', () async {
      final messageCacheKey = marshaller.cacheKey.message(
        _channelId,
        _messageId,
      );
      await cache.put(messageCacheKey, {
        'id': _messageId,
        'content': 'old content',
        'channel_id': _channelId,
        'guild_id': _guildId,
        'author_id': '987',
        'author_is_bot': false,
        'embeds': <dynamic>[],
        'timestamp': '2024-01-01T00:00:00.000Z',
        'edited_timestamp': null,
      });

      final packet = MessageDeletePacket(
        marshaller: marshaller,
        dataStore: dataStore,
      );

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {}

      await packet.listen(
        _msg('MESSAGE_DELETE', _deletePayload(includeGuild: true)),
        dispatch,
      );

      final cached = await cache.get(messageCacheKey);
      expect(cached, isNull);
    });
  });

  // ── MESSAGE_DELETE_BULK ────────────────────────────────────────────────────

  group('MessageDeleteBulkPacket', () {
    test('packetType is PacketType.messageDeleteBulk', () {
      final packet = MessageDeleteBulkPacket(
        marshaller: marshaller,
        dataStore: dataStore,
      );
      expect(packet.packetType, equals(PacketType.messageDeleteBulk));
      expect(packet.packetType.name, equals('MESSAGE_DELETE_BULK'));
    });

    test('dispatches Event.guildMessageDeleteBulk', () async {
      final packet = MessageDeleteBulkPacket(
        marshaller: marshaller,
        dataStore: dataStore,
      );
      Event? capturedEvent;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        capturedEvent = event;
      }

      await packet.listen(
        _msg('MESSAGE_DELETE_BULK', _deleteBulkPayload()),
        dispatch,
      );

      expect(capturedEvent, equals(Event.guildMessageDeleteBulk));
    });

    test('payload carries correct number of messageIds', () async {
      final packet = MessageDeleteBulkPacket(
        marshaller: marshaller,
        dataStore: dataStore,
      );
      GuildMessageDeleteBulkArgs? args;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        if (event == Event.guildMessageDeleteBulk) {
          args = payload as GuildMessageDeleteBulkArgs;
        }
      }

      await packet.listen(
        _msg('MESSAGE_DELETE_BULK', _deleteBulkPayload()),
        dispatch,
      );

      expect(args, isNotNull);
      expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
      expect(args!.channel.id, equals(Snowflake.parse(_channelId)));
      expect(args!.messageIds, hasLength(2));
    });

    test('does not dispatch when no guild_id in payload', () async {
      final packet = MessageDeleteBulkPacket(
        marshaller: marshaller,
        dataStore: dataStore,
      );
      bool dispatched = false;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        dispatched = true;
      }

      // No guild_id → should be silently dropped.
      await packet.listen(
        _msg('MESSAGE_DELETE_BULK', {
          'ids': [_messageId],
          'channel_id': _channelId,
        }),
        dispatch,
      );

      expect(dispatched, isFalse);
    });
  });
}

// ── Domain helpers ────────────────────────────────────────────────────────────

GuildTextChannel _buildGuildTextChannel(EntityContext ctx) => GuildTextChannel(
  ChannelProperties(
    ctx: ctx,
    id: Snowflake.parse(_channelId),
    type: ChannelType.guildText,
    name: 'general',
    description: null,
    guildId: Snowflake.parse(_guildId),
    categoryId: null,
    position: null,
    nsfw: false,
    lastMessageId: null,
    bitrate: null,
    userLimit: null,
    rateLimitPerUser: null,
    recipients: [],
    icon: null,
    ownerId: null,
    applicationId: null,
    lastPinTimestamp: null,
    rtcRegion: null,
    videoQualityMode: null,
    messageCount: null,
    memberCount: null,
    defaultAutoArchiveDuration: null,
    permissions: [],
    flags: null,
    totalMessageSent: null,
    available: null,
    appliedTags: [],
    defaultReactions: null,
    defaultSortOrder: null,
    defaultForumLayout: null,
    threads: ThreadsManager(
      Snowflake.parse(_guildId),
      Snowflake.parse(_channelId),
      ctx: ctx,
    ),
  ),
);
