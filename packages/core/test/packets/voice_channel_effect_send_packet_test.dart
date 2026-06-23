import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/api/common/permissions.dart';
import 'package:mineral/src/api/server/managers/rules_manager.dart';
import 'package:mineral/src/api/server/managers/threads_manager.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/common/runtime_state.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/thread_part.dart';
import 'package:mineral/src/infrastructure/internals/datastore/request_bucket.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/voice_channel_effect_send_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:test/test.dart';

import '../helpers/fake_logger.dart';
import '../helpers/fake_websocket_orchestrator.dart';

// ── Test IDs ─────────────────────────────────────────────────────────────────

const _serverId = '123456789012345678';
const _channelId = '234567890123456789';
const _userId = '345678901234567890';
const _emojiId = '999888777666555444';
const _soundId = '111222333444555666';

// ── No-op stubs ───────────────────────────────────────────────────────────────

final class _NoopDs implements DataStoreContract {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());

  @override
  ChannelPartContract get channel => throw UnimplementedError();
  @override
  ServerPartContract get server => throw UnimplementedError();
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

// ── Fake DataStore ────────────────────────────────────────────────────────────

/// Delegates every accessor to a lazily-resolved [DataStoreContract].
/// Breaks circular dependency: EntityContext → DataStoreContract → domain
/// objects built with EntityContext.
final class _DeferredDataStore implements DataStoreContract {
  final DataStoreContract Function() _resolve;

  _DeferredDataStore(this._resolve);

  @override
  ChannelPartContract get channel => _resolve().channel;
  @override
  ServerPartContract get server => _resolve().server;
  @override
  MemberPartContract get member => _resolve().member;
  @override
  MessagePartContract get message => throw UnimplementedError();
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

final class _FakeDataStore implements DataStoreContract {
  final ChannelPartContract _channelPart;
  final ServerPartContract _serverPart;
  final MemberPartContract _memberPart;

  _FakeDataStore({
    required ChannelPartContract channelPart,
    required ServerPartContract serverPart,
    required MemberPartContract memberPart,
  })  : _channelPart = channelPart,
        _serverPart = serverPart,
        _memberPart = memberPart;

  @override
  ChannelPartContract get channel => _channelPart;
  @override
  ServerPartContract get server => _serverPart;
  @override
  MemberPartContract get member => _memberPart;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());

  @override
  MessagePartContract get message => throw UnimplementedError();
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
  ApplicationEmojiPartContract get applicationEmoji =>
      throw UnimplementedError();
  @override
  WelcomeScreenPartContract get welcomeScreen => throw UnimplementedError();
  @override
  OnboardingPartContract get onboarding => throw UnimplementedError();
  @override
  TemplatePartContract get template => throw UnimplementedError();
  @override
  GuildScheduledEventPartContract get scheduledEvent =>
      throw UnimplementedError();
  @override
  StageInstancePartContract get stageInstance => throw UnimplementedError();
  @override
  RequestBucket get requestBucket => throw UnimplementedError();
  @override
  HttpClientContract get client => throw UnimplementedError();
}

// ── Fake parts ────────────────────────────────────────────────────────────────

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
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

final class _FakeServerPart implements ServerPartContract {
  final Server _server;

  _FakeServerPart(this._server);

  @override
  Future<Server> get(Object id, bool force) async => _server;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

final class _FakeMemberPart implements MemberPartContract {
  final Member _member;

  _FakeMemberPart(this._member);

  @override
  Future<Member?> get(Object serverId, Object id, bool force) async => _member;

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

Server _buildServer(EntityContext ctx) {
  final id = Snowflake.parse(_serverId);
  return Server(
    ctx: ctx,
    id: id,
    name: 'Test Server',
    ownerId: Snowflake.parse('000000000000000001'),
    description: null,
    applicationId: null,
    members: MemberManager(id, ctx: ctx),
    settings: ServerSettings(
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
      subscription: ServerSubscription(
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
    assets: ServerAsset(
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

ServerVoiceChannel _buildVoiceChannel(EntityContext ctx) => ServerVoiceChannel(
      ChannelProperties(
        ctx: ctx,
        id: Snowflake.parse(_channelId),
        type: ChannelType.guildVoice,
        name: 'general-voice',
        description: null,
        serverId: Snowflake.parse(_serverId),
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
          Snowflake.parse(_serverId),
          Snowflake.parse(_channelId),
          ctx: ctx,
        ),
      ),
    );

Member _buildMember(EntityContext ctx) {
  final memberId = Snowflake.parse(_userId);
  final serverId = Snowflake.parse(_serverId);
  return Member(
    ctx: ctx,
    id: memberId,
    username: 'testuser',
    nickname: null,
    globalName: null,
    discriminator: null,
    assets: MemberAssets(
      avatar: null,
      avatarDecoration: null,
      banner: null,
    ),
    flags: MemberFlagsManager([], ctx: ctx),
    premiumSince: null,
    publicFlags: null,
    roles: MemberRoleManager([], serverId, memberId, ctx: ctx),
    isBot: false,
    isPending: false,
    timeout: MemberTimeout(duration: null),
    mfaEnabled: false,
    locale: null,
    premiumType: PremiumTier.none,
    joinedAt: null,
    permissions: Permissions.fromInt(0),
    accentColor: null,
    serverId: serverId,
  );
}

// ── Shard message factories ───────────────────────────────────────────────────

ShardMessage<dynamic> _shardMessage(Map<String, dynamic> payload) =>
    ShardMessage(
      type: 'VOICE_CHANNEL_EFFECT_SEND',
      opCode: OpCode.dispatch,
      sequence: 1,
      payload: {
        'channel_id': _channelId,
        'guild_id': _serverId,
        'user_id': _userId,
        ...payload,
      },
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('VoiceChannelEffectSendPacket', () {
    // ── packetType identity ─────────────────────────────────────────────────

    test('packetType is voiceChannelEffectSend', () {
      final ds = _FakeDataStore(
        channelPart: _FakeChannelPart(
          _buildVoiceChannel(
            _buildCtx(_NoopDs()),
          ),
        ),
        serverPart: _FakeServerPart(
          _buildServer(
            _buildCtx(_NoopDs()),
          ),
        ),
        memberPart: _FakeMemberPart(
          _buildMember(
            _buildCtx(_NoopDs()),
          ),
        ),
      );
      final packet = VoiceChannelEffectSendPacket(dataStore: ds);

      expect(packet.packetType, equals(PacketType.voiceChannelEffectSend));
      expect(packet.packetType.name, equals('VOICE_CHANNEL_EFFECT_SEND'));
    });

    // ── emoji effect dispatch ───────────────────────────────────────────────

    group('emoji effect (animation_type set, no sound)', () {
      late VoiceChannelEffectSendPacket packet;
      late EntityContext ctx;

      setUp(() {
        late _FakeDataStore ds;

        ctx = EntityContext(
          datastore: _DeferredDataStore(() => ds),
          wss: FakeWebsocketOrchestrator(),
          logger: FakeLogger(),
          runtimeState: RuntimeState(),
        );

        final server = _buildServer(ctx);
        final channel = _buildVoiceChannel(ctx);
        final member = _buildMember(ctx);

        ds = _FakeDataStore(
          channelPart: _FakeChannelPart(channel),
          serverPart: _FakeServerPart(server),
          memberPart: _FakeMemberPart(member),
        );

        packet = VoiceChannelEffectSendPacket(dataStore: ds);
      });

      test('dispatches Event.serverVoiceChannelEffectSend', () async {
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
          _shardMessage({
            'emoji': {'id': _emojiId, 'name': 'cool_emoji', 'animated': true},
            'animation_type': 0,
            'animation_id': 42,
          }),
          dispatch,
        );

        expect(capturedEvent, equals(Event.serverVoiceChannelEffectSend));
        expect(capturedPayload, isA<ServerVoiceChannelEffectSendArgs>());
      });

      test('payload carries emoji, animationType=premium, animationId', () async {
        ServerVoiceChannelEffectSendArgs? args;

        void dispatch<T extends Object>(
            {required Event event,
            required T payload,
            bool Function(String?)? constraint}) {
          if (event == Event.serverVoiceChannelEffectSend) {
            args = payload as ServerVoiceChannelEffectSendArgs;
          }
        }

        await packet.listen(
          _shardMessage({
            'emoji': {'id': _emojiId, 'name': 'cool_emoji', 'animated': true},
            'animation_type': 0,
            'animation_id': 42,
          }),
          dispatch,
        );

        expect(args, isNotNull);
        expect(args!.emoji, isNotNull);
        expect(args!.emoji!.name, equals('cool_emoji'));
        expect(args!.emoji!.id, equals(Snowflake.parse(_emojiId)));
        expect(args!.emoji!.animated, isTrue);
        expect(args!.animationType,
            equals(VoiceChannelEffectAnimationType.premium));
        expect(args!.animationId, equals(42));
        expect(args!.soundId, isNull);
        expect(args!.soundVolume, isNull);
      });

      test('payload carries unicode emoji and basic animationType', () async {
        ServerVoiceChannelEffectSendArgs? args;

        void dispatch<T extends Object>(
            {required Event event,
            required T payload,
            bool Function(String?)? constraint}) {
          if (event == Event.serverVoiceChannelEffectSend) {
            args = payload as ServerVoiceChannelEffectSendArgs;
          }
        }

        await packet.listen(
          _shardMessage({
            'emoji': {'id': null, 'name': '🔥', 'animated': false},
            'animation_type': 1,
            'animation_id': 7,
          }),
          dispatch,
        );

        expect(args, isNotNull);
        expect(args!.emoji!.name, equals('🔥'));
        expect(args!.emoji!.id, isNull);
        expect(args!.animationType,
            equals(VoiceChannelEffectAnimationType.basic));
      });

      test('channel is ServerVoiceChannel (ServerChannel subtype)', () async {
        ServerVoiceChannelEffectSendArgs? args;

        void dispatch<T extends Object>(
            {required Event event,
            required T payload,
            bool Function(String?)? constraint}) {
          if (event == Event.serverVoiceChannelEffectSend) {
            args = payload as ServerVoiceChannelEffectSendArgs;
          }
        }

        await packet.listen(
          _shardMessage({
            'emoji': {'id': null, 'name': '👍', 'animated': false},
            'animation_type': 1,
            'animation_id': 1,
          }),
          dispatch,
        );

        expect(args!.channel, isA<ServerVoiceChannel>());
        expect(args!.member, isA<Member>());
        expect(args!.server, isA<Server>());
      });
    });

    // ── soundboard effect dispatch ──────────────────────────────────────────

    group('soundboard effect (sound_id set, no emoji)', () {
      late VoiceChannelEffectSendPacket packet;

      setUp(() {
        late _FakeDataStore ds;

        final ctx = EntityContext(
          datastore: _DeferredDataStore(() => ds),
          wss: FakeWebsocketOrchestrator(),
          logger: FakeLogger(),
          runtimeState: RuntimeState(),
        );

        final server = _buildServer(ctx);
        final channel = _buildVoiceChannel(ctx);
        final member = _buildMember(ctx);

        ds = _FakeDataStore(
          channelPart: _FakeChannelPart(channel),
          serverPart: _FakeServerPart(server),
          memberPart: _FakeMemberPart(member),
        );

        packet = VoiceChannelEffectSendPacket(dataStore: ds);
      });

      test('dispatches Event.serverVoiceChannelEffectSend with sound payload',
          () async {
        ServerVoiceChannelEffectSendArgs? args;

        void dispatch<T extends Object>(
            {required Event event,
            required T payload,
            bool Function(String?)? constraint}) {
          if (event == Event.serverVoiceChannelEffectSend) {
            args = payload as ServerVoiceChannelEffectSendArgs;
          }
        }

        await packet.listen(
          _shardMessage({
            'sound_id': _soundId,
            'sound_volume': 0.5,
          }),
          dispatch,
        );

        expect(args, isNotNull);
        expect(args!.soundId, equals(Snowflake.parse(_soundId)));
        expect(args!.soundVolume, equals(0.5));
        expect(args!.emoji, isNull);
        expect(args!.animationType, isNull);
        expect(args!.animationId, isNull);
      });
    });

    // ── null/absent optional fields ─────────────────────────────────────────

    group('null/absent optional fields', () {
      late VoiceChannelEffectSendPacket packet;

      setUp(() {
        late _FakeDataStore ds;

        final ctx = EntityContext(
          datastore: _DeferredDataStore(() => ds),
          wss: FakeWebsocketOrchestrator(),
          logger: FakeLogger(),
          runtimeState: RuntimeState(),
        );

        final server = _buildServer(ctx);
        final channel = _buildVoiceChannel(ctx);
        final member = _buildMember(ctx);

        ds = _FakeDataStore(
          channelPart: _FakeChannelPart(channel),
          serverPart: _FakeServerPart(server),
          memberPart: _FakeMemberPart(member),
        );

        packet = VoiceChannelEffectSendPacket(dataStore: ds);
      });

      test('all optional fields null when absent from payload', () async {
        ServerVoiceChannelEffectSendArgs? args;

        void dispatch<T extends Object>(
            {required Event event,
            required T payload,
            bool Function(String?)? constraint}) {
          if (event == Event.serverVoiceChannelEffectSend) {
            args = payload as ServerVoiceChannelEffectSendArgs;
          }
        }

        await packet.listen(_shardMessage({}), dispatch);

        expect(args, isNotNull);
        expect(args!.emoji, isNull);
        expect(args!.animationType, isNull);
        expect(args!.animationId, isNull);
        expect(args!.soundId, isNull);
        expect(args!.soundVolume, isNull);
      });
    });
  });
}
