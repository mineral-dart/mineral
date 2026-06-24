import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/api/guild/managers/rules_manager.dart';
import 'package:mineral/src/api/guild/managers/threads_manager.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/common/runtime_state.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/thread_part.dart';
import 'package:mineral/src/infrastructure/internals/datastore/request_bucket.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/message_reaction_remove_emoji_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:test/test.dart';

import '../helpers/fake_logger.dart';
import '../helpers/fake_websocket_orchestrator.dart';

// ── Test IDs ─────────────────────────────────────────────────────────────────

const _channelId = '111222333444555666';
const _messageId = '777888999000111222';
const _guildId = '123456789012345678';

// ── Fake data store helpers ───────────────────────────────────────────────────

/// Delegates every accessor to a lazily-resolved [DataStoreContract].
/// Used to break the circular dependency: EntityContext → DataStoreContract →
/// channels/messages built with EntityContext.
final class _DeferredDataStore implements DataStoreContract {
  final DataStoreContract Function() _resolve;

  _DeferredDataStore(this._resolve);

  @override
  ChannelPartContract get channel => _resolve().channel;
  @override
  GuildPartContract get guild => _resolve().guild;
  @override
  MessagePartContract get message => _resolve().message;
  @override
  MemberPartContract get member => _resolve().member;
  @override
  UserPartContract get user => _resolve().user;
  @override
  RolePartContract get role => _resolve().role;
  @override
  InteractionPartContract get interaction => _resolve().interaction;
  @override
  StickerPartContract get sticker => _resolve().sticker;
  @override
  EmojiPartContract get emoji => _resolve().emoji;
  @override
  RulesPartContract get rules => _resolve().rules;
  @override
  ReactionPartContract get reaction => _resolve().reaction;
  @override
  ThreadPart get thread => _resolve().thread;
  @override
  InvitePartContract get invite => _resolve().invite;
  @override
  WebhookPartContract get webhook => _resolve().webhook;
  @override
  GuildScheduledEventPartContract get scheduledEvent =>
      _resolve().scheduledEvent;
  @override
  ApplicationEmojiPartContract get applicationEmoji =>
      _resolve().applicationEmoji;
  @override
  WelcomeScreenPartContract get welcomeScreen => _resolve().welcomeScreen;
  @override
  OnboardingPartContract get onboarding => _resolve().onboarding;
  @override
  TemplatePartContract get template => _resolve().template;
  @override
  StageInstancePartContract get stageInstance => _resolve().stageInstance;
  @override
  MonetizationPartContract get monetization => _resolve().monetization;
  @override
  SoundboardPartContract get soundboard => _resolve().soundboard;
  @override
  RequestBucket get requestBucket => _resolve().requestBucket;
  @override
  HttpClientContract get client => _resolve().client;
}

/// Minimal [DataStoreContract] that wires channel, guild, and message parts.
final class _FakeDataStore implements DataStoreContract {
  final ChannelPartContract _channelPart;
  final GuildPartContract _guildPart;
  final MessagePartContract _messagePart;

  _FakeDataStore({
    required ChannelPartContract channelPart,
    required GuildPartContract guildPart,
    required MessagePartContract messagePart,
  })  : _channelPart = channelPart,
        _guildPart = guildPart,
        _messagePart = messagePart;

  @override
  ChannelPartContract get channel => _channelPart;
  @override
  GuildPartContract get guild => _guildPart;
  @override
  MessagePartContract get message => _messagePart;

  @override
  RequestBucket get requestBucket => throw UnimplementedError();
  @override
  HttpClientContract get client => throw UnimplementedError();
  @override
  MemberPartContract get member => throw UnimplementedError();
  @override
  UserPartContract get user => throw UnimplementedError();
  @override
  RolePartContract get role => throw UnimplementedError();
  @override
  InteractionPartContract get interaction => throw UnimplementedError();
  @override
  StickerPartContract get sticker => throw UnimplementedError();
  @override
  EmojiPartContract get emoji => throw UnimplementedError();
  @override
  RulesPartContract get rules => throw UnimplementedError();
  @override
  ReactionPartContract get reaction => throw UnimplementedError();
  @override
  ThreadPart get thread => throw UnimplementedError();
  @override
  InvitePartContract get invite => throw UnimplementedError();
  @override
  WebhookPartContract get webhook => throw UnimplementedError();
  @override
  GuildScheduledEventPartContract get scheduledEvent =>
      throw UnimplementedError();
  @override
  ApplicationEmojiPartContract get applicationEmoji =>
      throw UnimplementedError();
  @override
  WelcomeScreenPartContract get welcomeScreen => throw UnimplementedError();
  @override
  OnboardingPartContract get onboarding => throw UnimplementedError();
  @override
  TemplatePartContract get template => throw UnimplementedError();
  @override
  StageInstancePartContract get stageInstance => throw UnimplementedError();
  @override
  MonetizationPartContract get monetization => throw UnimplementedError();
  @override
  SoundboardPartContract get soundboard => throw UnimplementedError();
}

/// [ChannelPartContract] that returns a pre-built [Channel].
final class _FakeChannelPart implements ChannelPartContract {
  final Channel _channel;

  _FakeChannelPart(this._channel);

  @override
  Future<T?> get<T extends Channel>(Object id, bool force) async {
    if (_channel is T) {
      // ignore: unnecessary_cast
      return _channel as T;
    }
    return null;
  }

  @override
  Future<Map<Snowflake, T>> fetch<T extends Channel>(
          Object guildId, bool force) async =>
      {};

  @override
  Future<T> create<T extends Channel>(
          Object? guildId, ChannelBuilderContract builder,
          {String? reason}) =>
      throw UnimplementedError();

  @override
  Future<PrivateChannel?> createPrivateChannel(
          Object id, String recipientId) async =>
      null;

  @override
  Future<T?> update<T extends Channel>(
          Object id, ChannelBuilderContract builder,
          {Object? guildId, String? reason}) =>
      throw UnimplementedError();

  @override
  Future<void> delete(Object id, String? reason) async {}
}

/// [GuildPartContract] that returns a pre-built [Guild].
final class _FakeServerPart implements GuildPartContract {
  final Guild _guild;

  _FakeServerPart(this._guild);

  @override
  Future<Guild> get(Object id, bool force) async => _guild;

  @override
  Future<Guild> update(Object id, Map<String, dynamic> payload,
          [String? reason]) =>
      throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

/// [MessagePartContract] that returns a pre-built [Message].
final class _FakeMessagePart implements MessagePartContract {
  final Message _message;

  _FakeMessagePart(this._message);

  @override
  Future<T?> get<T extends BaseMessage>(
          Object channelId, Object messageId, bool force) async =>
      _message as T?;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

/// Stub [GuildPartContract] for tests that never hit the guild branch.
final class _NoopServerPart implements GuildPartContract {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

/// Stub [MessagePartContract] for tests that skip message resolution.
final class _NoopMessagePart implements MessagePartContract {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

// ── Domain object builders ────────────────────────────────────────────────────

EntityContext _buildCtx(DataStoreContract dataStore) => EntityContext(
      datastore: dataStore,
      wss: FakeWebsocketOrchestrator(),
      logger: FakeLogger(),
      runtimeState: RuntimeState(),
    );

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

GuildTextChannel _buildServerTextChannel(EntityContext ctx) =>
    GuildTextChannel(
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

Guild _buildServer(EntityContext ctx) {
  final id = Snowflake.parse(_guildId);
  return Guild(
    ctx: ctx,
    id: id,
    name: 'Test Guild',
    ownerId: Snowflake.parse('000000000000000001'),
    description: null,
    applicationId: null,
    members: MemberManager(id, ctx: ctx),
    settings: GuildSettings(
      bitfieldPermission: null,
      afkTimeout: null,
      hasWidgetEnabled: false,
      verificationLevel: VerificationLevel.none,
      defaultMessageNotifications: DefaultMessageNotification.allMessages,
      explicitContentFilter: ExplicitContentFilter.disabled,
      features: [],
      mfaLevel: MfaLevel.none,
      systemChannelFlags: [],
      vanityUrlCode: null,
      subscription: GuildSubscription(
        tier: PremiumTier.none,
        subscriptionCount: null,
        hasEnabledProgressBar: false,
      ),
      preferredLocale: 'en-US',
      maxVideoChannelUsers: null,
      nsfwLevel: NsfwLevel.none,
      rulesManager: RulesManager(id, ctx: ctx),
    ),
    roles: RoleManager(id, ctx: ctx),
    channels: ChannelManager(
      id,
      ctx: ctx,
      afkChannelId: null,
      systemChannelId: null,
      rulesChannelId: null,
      publicUpdatesChannelId: null,
      safetyAlertsChannelId: null,
    ),
    threads: ThreadsManager(id, null, ctx: ctx),
    assets: GuildAsset(
      id,
      ctx: ctx,
      emojis: EmojiManager(id, ctx: ctx),
      stickers: StickerManager(id, ctx: ctx),
      icon: null,
      splash: null,
      banner: null,
      discoverySplash: null,
    ),
  );
}

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

ShardMessage<dynamic> _privateShardMessage(
        Map<String, dynamic> emojiPayload) =>
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
      // Construct the packet with a do-nothing dataStore; we only check identity.
      final ds = _FakeDataStore(
        channelPart: _FakeChannelPart(
            _buildPrivateChannel(_buildCtx(_FakeDataStore(
          channelPart: _FakeChannelPart(PrivateChannel(ChannelProperties(
            ctx: EntityContext(
              datastore: _FakeDataStore(
                channelPart: _FakeChannelPart(PrivateChannel(
                    ChannelProperties(
                        ctx: EntityContext(
                          datastore: _NoopDs(),
                          wss: FakeWebsocketOrchestrator(),
                          logger: FakeLogger(),
                          runtimeState: RuntimeState(),
                        ),
                        id: Snowflake.parse(_channelId),
                        type: ChannelType.dm,
                        name: null,
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
                        threads: ThreadsManager(null, null,
                            ctx: EntityContext(
                              datastore: _NoopDs(),
                              wss: FakeWebsocketOrchestrator(),
                              logger: FakeLogger(),
                              runtimeState: RuntimeState(),
                            ))))),
                guildPart: _NoopServerPart(),
                messagePart: _NoopMessagePart(),
              ),
              wss: FakeWebsocketOrchestrator(),
              logger: FakeLogger(),
              runtimeState: RuntimeState(),
            ),
            id: Snowflake.parse(_channelId),
            type: ChannelType.dm,
            name: null,
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
            threads: ThreadsManager(null, null,
                ctx: EntityContext(
                  datastore: _NoopDs(),
                  wss: FakeWebsocketOrchestrator(),
                  logger: FakeLogger(),
                  runtimeState: RuntimeState(),
                )),
          ))),
          guildPart: _NoopServerPart(),
          messagePart: _NoopMessagePart(),
        )))),
        guildPart: _NoopServerPart(),
        messagePart: _NoopMessagePart(),
      );
      final packet = MessageReactionRemoveEmojiPacket(dataStore: ds);

      expect(packet.packetType,
          equals(PacketType.messageReactionRemoveEmoji));
      expect(packet.packetType.name,
          equals('MESSAGE_REACTION_REMOVE_EMOJI'));
    });

    // ── guild branch ───────────────────────────────────────────────────────

    group('guild branch (guild_id present)', () {
      late MessageReactionRemoveEmojiPacket packet;

      setUp(() {
        // Use a deferred dataStore so that the EntityContext used to build
        // domain objects can reference the same dataStore that the packet uses.
        late _FakeDataStore ds;

        final ctx = EntityContext(
          datastore: _DeferredDataStore(() => ds),
          wss: FakeWebsocketOrchestrator(),
          logger: FakeLogger(),
          runtimeState: RuntimeState(),
        );

        final message = _buildMessage(ctx);
        final channel = _buildServerTextChannel(ctx);
        final guild = _buildServer(ctx);

        ds = _FakeDataStore(
          channelPart: _FakeChannelPart(channel),
          guildPart: _FakeServerPart(guild),
          messagePart: _FakeMessagePart(message),
        );

        packet = MessageReactionRemoveEmojiPacket(dataStore: ds);
      });

      test('dispatches Event.guildMessageReactionRemoveEmoji', () async {
        Event? capturedEvent;
        Object? capturedPayload;

        void dispatch<T extends Object>(
            {required Event event,
            required T payload,
            bool Function(String?)? constraint}) {
          capturedEvent = event;
          capturedPayload = payload;
        }

        await packet.listen(
            _guildShardMessage({'id': null, 'name': '👍', 'animated': false}),
            dispatch);

        expect(capturedEvent,
            equals(Event.guildMessageReactionRemoveEmoji));
        expect(capturedPayload,
            isA<GuildMessageReactionRemoveEmojiArgs>());
      });

      test('payload carries correct unicode emoji', () async {
        GuildMessageReactionRemoveEmojiArgs? args;

        void dispatch<T extends Object>(
            {required Event event,
            required T payload,
            bool Function(String?)? constraint}) {
          if (event == Event.guildMessageReactionRemoveEmoji) {
            args = payload as GuildMessageReactionRemoveEmojiArgs;
          }
        }

        await packet.listen(
            _guildShardMessage({'id': null, 'name': '👍', 'animated': false}),
            dispatch);

        expect(args, isNotNull);
        expect(args!.emoji, isA<PartialEmoji>());
        expect(args!.emoji.name, equals('👍'));
        expect(args!.emoji.id, isNull);
        expect(args!.emoji.animated, isFalse);
      });

      test('payload carries correct custom animated emoji', () async {
        GuildMessageReactionRemoveEmojiArgs? args;

        void dispatch<T extends Object>(
            {required Event event,
            required T payload,
            bool Function(String?)? constraint}) {
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
            dispatch);

        expect(args, isNotNull);
        expect(args!.emoji.name, equals('cool'));
        expect(args!.emoji.id,
            equals(Snowflake.parse('999888777666555444')));
        expect(args!.emoji.animated, isTrue);
      });
    });

    // ── private branch ──────────────────────────────────────────────────────

    group('private branch (no guild_id)', () {
      late MessageReactionRemoveEmojiPacket packet;

      setUp(() {
        late _FakeDataStore ds;

        final ctx = EntityContext(
          datastore: _DeferredDataStore(() => ds),
          wss: FakeWebsocketOrchestrator(),
          logger: FakeLogger(),
          runtimeState: RuntimeState(),
        );

        final message = _buildMessage(ctx);
        final channel = _buildPrivateChannel(ctx);

        ds = _FakeDataStore(
          channelPart: _FakeChannelPart(channel),
          guildPart: _NoopServerPart(),
          messagePart: _FakeMessagePart(message),
        );

        packet = MessageReactionRemoveEmojiPacket(dataStore: ds);
      });

      test('dispatches Event.privateMessageReactionRemoveEmoji', () async {
        Event? capturedEvent;
        Object? capturedPayload;

        void dispatch<T extends Object>(
            {required Event event,
            required T payload,
            bool Function(String?)? constraint}) {
          capturedEvent = event;
          capturedPayload = payload;
        }

        await packet.listen(
            _privateShardMessage(
                {'id': null, 'name': '🔥', 'animated': false}),
            dispatch);

        expect(capturedEvent,
            equals(Event.privateMessageReactionRemoveEmoji));
        expect(capturedPayload,
            isA<PrivateMessageReactionRemoveEmojiArgs>());
      });

      test('payload carries correct unicode emoji', () async {
        PrivateMessageReactionRemoveEmojiArgs? args;

        void dispatch<T extends Object>(
            {required Event event,
            required T payload,
            bool Function(String?)? constraint}) {
          if (event == Event.privateMessageReactionRemoveEmoji) {
            args = payload as PrivateMessageReactionRemoveEmojiArgs;
          }
        }

        await packet.listen(
            _privateShardMessage(
                {'id': null, 'name': '🔥', 'animated': false}),
            dispatch);

        expect(args, isNotNull);
        expect(args!.emoji, isA<PartialEmoji>());
        expect(args!.emoji.name, equals('🔥'));
        expect(args!.emoji.id, isNull);
        expect(args!.emoji.animated, isFalse);
      });
    });
  });
}

// ── No-op stubs used in packetType identity test ──────────────────────────────

final class _NoopDs implements DataStoreContract {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());

  @override
  ChannelPartContract get channel => throw UnimplementedError();
  @override
  GuildPartContract get guild => throw UnimplementedError();
  @override
  MessagePartContract get message => throw UnimplementedError();
  @override
  MemberPartContract get member => throw UnimplementedError();
  @override
  UserPartContract get user => throw UnimplementedError();
  @override
  RolePartContract get role => throw UnimplementedError();
  @override
  InteractionPartContract get interaction => throw UnimplementedError();
  @override
  StickerPartContract get sticker => throw UnimplementedError();
  @override
  EmojiPartContract get emoji => throw UnimplementedError();
  @override
  RulesPartContract get rules => throw UnimplementedError();
  @override
  ReactionPartContract get reaction => throw UnimplementedError();
  @override
  ThreadPart get thread => throw UnimplementedError();
  @override
  InvitePartContract get invite => throw UnimplementedError();
  @override
  WebhookPartContract get webhook => throw UnimplementedError();
  @override
  GuildScheduledEventPartContract get scheduledEvent =>
      throw UnimplementedError();
  @override
  ApplicationEmojiPartContract get applicationEmoji =>
      throw UnimplementedError();
  @override
  WelcomeScreenPartContract get welcomeScreen => throw UnimplementedError();
  @override
  OnboardingPartContract get onboarding => throw UnimplementedError();
  @override
  TemplatePartContract get template => throw UnimplementedError();
  @override
  StageInstancePartContract get stageInstance => throw UnimplementedError();
  @override
  RequestBucket get requestBucket => throw UnimplementedError();
  @override
  HttpClientContract get client => throw UnimplementedError();
}
