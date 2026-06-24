import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/api/guild/managers/threads_manager.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/message_reaction_remove_emoji_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../helpers/fake_websocket_orchestrator.dart';
import '../helpers/mocks.dart';
import 'helpers/packet_test_helpers.dart';

// ── Test IDs ─────────────────────────────────────────────────────────────────

const _channelId = '111222333444555666';
const _messageId = '777888999000111222';
const _guildId = '123456789012345678';

// ── Fake message part ─────────────────────────────────────────────────────────

class _FakeMessagePart extends Mock implements MessagePartContract {
  final Message _message;
  _FakeMessagePart(this._message);

  @override
  Future<T?> get<T extends BaseMessage>(
    Object channelId,
    Object messageId,
    bool force,
  ) async => _message as T?;
}

// ── Domain object builders ────────────────────────────────────────────────────

Message _buildMessage(EntityContext ctx) => Message(
  MessageProperties(
    id: Snowflake.parse(_messageId),
    content: 'test message',
    channelId: Snowflake.parse(_channelId),
    authorId: null,
    guildId: Snowflake.parse(_guildId),
    authorIsBot: false,
    embeds: [],
    createdAt: DateTime.now(),
    updatedAt: null,
  ),
  ctx: ctx,
);

GuildTextChannel _buildServerTextChannel(EntityContext ctx) => GuildTextChannel(
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

PrivateChannel _buildPrivateChannel(EntityContext ctx) => PrivateChannel(
  ChannelProperties(
    ctx: ctx,
    id: Snowflake.parse(_channelId),
    type: ChannelType.dm,
    name: 'dm',
    description: null,
    guildId: null,
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
    threads: ThreadsManager(null, null, ctx: ctx),
  ),
);

// ── Shard message factories ───────────────────────────────────────────────────

ShardMessage<dynamic> _guildShardMessage(Map<String, dynamic> emojiPayload) =>
    ShardMessage(
      type: 'MESSAGE_REACTION_REMOVE_EMOJI',
      opCode: OpCode.dispatch,
      sequence: 1,
      payload: {
        'channel_id': _channelId,
        'guild_id': _guildId,
        'message_id': _messageId,
        'emoji': emojiPayload,
      },
    );

ShardMessage<dynamic> _privateShardMessage(Map<String, dynamic> emojiPayload) =>
    ShardMessage(
      type: 'MESSAGE_REACTION_REMOVE_EMOJI',
      opCode: OpCode.dispatch,
      sequence: 1,
      payload: {
        'channel_id': _channelId,
        // no guild_id → private / DM
        'message_id': _messageId,
        'emoji': emojiPayload,
      },
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('MessageReactionRemoveEmojiPacket', () {
    // ── packetType identity ─────────────────────────────────────────────────

    test('packetType is messageReactionRemoveEmoji', () {
      final packet = MessageReactionRemoveEmojiPacket(dataStore: buildMockDs());
      expect(packet.packetType, equals(PacketType.messageReactionRemoveEmoji));
      expect(packet.packetType.name, equals('MESSAGE_REACTION_REMOVE_EMOJI'));
    });

    // ── guild branch ───────────────────────────────────────────────────────

    group('guild branch (guild_id present)', () {
      late MessageReactionRemoveEmojiPacket packet;

      setUp(() {
        final ds = MockDataStore();
        final ctx = buildCtx(dataStore: ds, wss: FakeWebsocketOrchestrator());
        final message = _buildMessage(ctx);
        final channel = _buildServerTextChannel(ctx);
        final guild = buildMinimalGuild(_guildId, ctx);

        when(() => ds.channel).thenReturn(FakeChannelPart(channel));
        when(() => ds.guild).thenReturn(FakeGuildPart(guild));
        when(() => ds.message).thenReturn(_FakeMessagePart(message));

        packet = MessageReactionRemoveEmojiPacket(dataStore: ds);
      });

      test('dispatches Event.guildMessageReactionRemoveEmoji', () async {
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

        await packet.listen(
          _guildShardMessage({'id': null, 'name': '👍', 'animated': false}),
          dispatch,
        );

        expect(capturedEvent, equals(Event.guildMessageReactionRemoveEmoji));
        expect(capturedPayload, isA<GuildMessageReactionRemoveEmojiArgs>());
      });

      test('payload carries correct unicode emoji', () async {
        GuildMessageReactionRemoveEmojiArgs? args;

        void dispatch<T extends Object>({
          required Event event,
          required T payload,
          bool Function(String?)? constraint,
        }) {
          if (event == Event.guildMessageReactionRemoveEmoji) {
            args = payload as GuildMessageReactionRemoveEmojiArgs;
          }
        }

        await packet.listen(
          _guildShardMessage({'id': null, 'name': '👍', 'animated': false}),
          dispatch,
        );

        expect(args, isNotNull);
        expect(args!.emoji, isA<PartialEmoji>());
        expect(args!.emoji.name, equals('👍'));
        expect(args!.emoji.id, isNull);
        expect(args!.emoji.animated, isFalse);
      });

      test('payload carries correct custom animated emoji', () async {
        GuildMessageReactionRemoveEmojiArgs? args;

        void dispatch<T extends Object>({
          required Event event,
          required T payload,
          bool Function(String?)? constraint,
        }) {
          if (event == Event.guildMessageReactionRemoveEmoji) {
            args = payload as GuildMessageReactionRemoveEmojiArgs;
          }
        }

        await packet.listen(
          _guildShardMessage({
            'id': '999888777666555444',
            'name': 'cool',
            'animated': true,
          }),
          dispatch,
        );

        expect(args, isNotNull);
        expect(args!.emoji.name, equals('cool'));
        expect(args!.emoji.id, equals(Snowflake.parse('999888777666555444')));
        expect(args!.emoji.animated, isTrue);
      });
    });

    // ── private branch ──────────────────────────────────────────────────────

    group('private branch (no guild_id)', () {
      late MessageReactionRemoveEmojiPacket packet;

      setUp(() {
        final ds = MockDataStore();
        final ctx = buildCtx(dataStore: ds, wss: FakeWebsocketOrchestrator());
        final message = _buildMessage(ctx);
        final channel = _buildPrivateChannel(ctx);

        when(() => ds.channel).thenReturn(FakeChannelPart(channel));
        when(() => ds.message).thenReturn(_FakeMessagePart(message));

        packet = MessageReactionRemoveEmojiPacket(dataStore: ds);
      });

      test('dispatches Event.privateMessageReactionRemoveEmoji', () async {
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

        await packet.listen(
          _privateShardMessage({'id': null, 'name': '🔥', 'animated': false}),
          dispatch,
        );

        expect(capturedEvent, equals(Event.privateMessageReactionRemoveEmoji));
        expect(capturedPayload, isA<PrivateMessageReactionRemoveEmojiArgs>());
      });

      test('payload carries correct unicode emoji', () async {
        PrivateMessageReactionRemoveEmojiArgs? args;

        void dispatch<T extends Object>({
          required Event event,
          required T payload,
          bool Function(String?)? constraint,
        }) {
          if (event == Event.privateMessageReactionRemoveEmoji) {
            args = payload as PrivateMessageReactionRemoveEmojiArgs;
          }
        }

        await packet.listen(
          _privateShardMessage({'id': null, 'name': '🔥', 'animated': false}),
          dispatch,
        );

        expect(args, isNotNull);
        expect(args!.emoji, isA<PartialEmoji>());
        expect(args!.emoji.name, equals('🔥'));
        expect(args!.emoji.id, isNull);
        expect(args!.emoji.animated, isFalse);
      });
    });
  });
}
