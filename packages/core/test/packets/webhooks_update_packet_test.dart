import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/api/guild/managers/rules_manager.dart';
import 'package:mineral/src/api/guild/managers/threads_manager.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/common/runtime_state.dart';
import 'package:mineral/src/domains/services/datastore/request_bucket_contract.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/webhooks_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:test/test.dart';

import '../helpers/fake_logger.dart';
import '../helpers/fake_websocket_orchestrator.dart';

// ── Test IDs ──────────────────────────────────────────────────────────────────

const _channelId = '111222333444555666';
const _guildId = '123456789012345678';

// ── Fake data store helpers ───────────────────────────────────────────────────

/// Delegates every accessor to a lazily-resolved [DataStoreContract].
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
  ThreadPartContract get thread => _resolve().thread;
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
  RequestBucketContract get requestBucket => _resolve().requestBucket;
  @override
  HttpClientContract get client => _resolve().client;
}

/// Minimal [DataStoreContract] that wires channel and guild parts.
final class _FakeDataStore implements DataStoreContract {
  final ChannelPartContract _channelPart;
  final GuildPartContract _guildPart;

  _FakeDataStore({
    required ChannelPartContract channelPart,
    required GuildPartContract guildPart,
  })  : _channelPart = channelPart,
        _guildPart = guildPart;

  @override
  ChannelPartContract get channel => _channelPart;
  @override
  GuildPartContract get guild => _guildPart;

  @override
  RequestBucketContract get requestBucket => throw UnimplementedError();
  @override
  HttpClientContract get client => throw UnimplementedError();
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
  ThreadPartContract get thread => throw UnimplementedError();
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
  final Channel? _channel;

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

// ── No-op stubs ───────────────────────────────────────────────────────────────

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
  ThreadPartContract get thread => throw UnimplementedError();
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
  RequestBucketContract get requestBucket => throw UnimplementedError();
  @override
  HttpClientContract get client => throw UnimplementedError();
}

// ── Domain object builders ────────────────────────────────────────────────────

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

// ── Shard message factory ─────────────────────────────────────────────────────

ShardMessage<dynamic> _buildShardMessage() => ShardMessage(
      type: 'WEBHOOKS_UPDATE',
      opCode: OpCode.dispatch,
      sequence: 1,
      payload: {
        'guild_id': _guildId,
        'channel_id': _channelId,
      },
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('WebhooksUpdatePacket', () {
    // ── packetType identity ─────────────────────────────────────────────────

    test('packetType is PacketType.webhooksUpdate', () {
      final packet = WebhooksUpdatePacket(dataStore: _NoopDs());
      expect(packet.packetType, equals(PacketType.webhooksUpdate));
      expect(packet.packetType.name, equals('WEBHOOKS_UPDATE'));
    });

    // ── guild branch ───────────────────────────────────────────────────────

    group('dispatches guildWebhooksUpdate with resolved guild and channel',
        () {
      late WebhooksUpdatePacket packet;
      late Guild guild;
      late GuildTextChannel channel;

      setUp(() {
        late _FakeDataStore ds;

        final ctx = EntityContext(
          datastore: _DeferredDataStore(() => ds),
          wss: FakeWebsocketOrchestrator(),
          logger: FakeLogger(),
          runtimeState: RuntimeState(),
        );

        channel = _buildServerTextChannel(ctx);
        guild = _buildServer(ctx);

        ds = _FakeDataStore(
          channelPart: _FakeChannelPart(channel),
          guildPart: _FakeServerPart(guild),
        );

        packet = WebhooksUpdatePacket(dataStore: ds);
      });

      test('dispatches Event.guildWebhooksUpdate', () async {
        Event? capturedEvent;

        void dispatch<T extends Object>(
            {required Event event,
            required T payload,
            bool Function(String?)? constraint}) {
          capturedEvent = event;
        }

        await packet.listen(_buildShardMessage(), dispatch);

        expect(capturedEvent, equals(Event.guildWebhooksUpdate));
      });

      test('payload is GuildWebhooksUpdateArgs', () async {
        Object? capturedPayload;

        void dispatch<T extends Object>(
            {required Event event,
            required T payload,
            bool Function(String?)? constraint}) {
          capturedPayload = payload;
        }

        await packet.listen(_buildShardMessage(), dispatch);

        expect(capturedPayload, isA<GuildWebhooksUpdateArgs>());
      });

      test('payload carries the resolved guild', () async {
        GuildWebhooksUpdateArgs? args;

        void dispatch<T extends Object>(
            {required Event event,
            required T payload,
            bool Function(String?)? constraint}) {
          if (event == Event.guildWebhooksUpdate) {
            args = payload as GuildWebhooksUpdateArgs;
          }
        }

        await packet.listen(_buildShardMessage(), dispatch);

        expect(args, isNotNull);
        expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
        expect(args!.guild.name, equals('Test Guild'));
      });

      test('payload carries the resolved channel', () async {
        GuildWebhooksUpdateArgs? args;

        void dispatch<T extends Object>(
            {required Event event,
            required T payload,
            bool Function(String?)? constraint}) {
          if (event == Event.guildWebhooksUpdate) {
            args = payload as GuildWebhooksUpdateArgs;
          }
        }

        await packet.listen(_buildShardMessage(), dispatch);

        expect(args, isNotNull);
        expect(args!.channel, isNotNull);
        expect(args!.channel!.id, equals(Snowflake.parse(_channelId)));
      });
    });
  });
}
