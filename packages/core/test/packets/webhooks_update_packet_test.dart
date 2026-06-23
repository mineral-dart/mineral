import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/api/server/managers/rules_manager.dart';
import 'package:mineral/src/api/server/managers/threads_manager.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/common/runtime_state.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/thread_part.dart';
import 'package:mineral/src/infrastructure/internals/datastore/request_bucket.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/webhooks_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:test/test.dart';

import '../helpers/fake_logger.dart';
import '../helpers/fake_websocket_orchestrator.dart';

// ── Test IDs ──────────────────────────────────────────────────────────────────

const _channelId = '111222333444555666';
const _serverId = '123456789012345678';

// ── Fake data store helpers ───────────────────────────────────────────────────

/// Delegates every accessor to a lazily-resolved [DataStoreContract].
final class _DeferredDataStore implements DataStoreContract {
  final DataStoreContract Function() _resolve;

  _DeferredDataStore(this._resolve);

  @override
  ChannelPartContract get channel => _resolve().channel;
  @override
  ServerPartContract get server => _resolve().server;
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
  RequestBucket get requestBucket => _resolve().requestBucket;
  @override
  HttpClientContract get client => _resolve().client;
}

/// Minimal [DataStoreContract] that wires channel and server parts.
final class _FakeDataStore implements DataStoreContract {
  final ChannelPartContract _channelPart;
  final ServerPartContract _serverPart;

  _FakeDataStore({
    required ChannelPartContract channelPart,
    required ServerPartContract serverPart,
  })  : _channelPart = channelPart,
        _serverPart = serverPart;

  @override
  ChannelPartContract get channel => _channelPart;
  @override
  ServerPartContract get server => _serverPart;

  @override
  RequestBucket get requestBucket => throw UnimplementedError();
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
          Object serverId, bool force) async =>
      {};

  @override
  Future<T> create<T extends Channel>(
          Object? serverId, ChannelBuilderContract builder,
          {String? reason}) =>
      throw UnimplementedError();

  @override
  Future<PrivateChannel?> createPrivateChannel(
          Object id, String recipientId) async =>
      null;

  @override
  Future<T?> update<T extends Channel>(
          Object id, ChannelBuilderContract builder,
          {Object? serverId, String? reason}) =>
      throw UnimplementedError();

  @override
  Future<void> delete(Object id, String? reason) async {}
}

/// [ServerPartContract] that returns a pre-built [Server].
final class _FakeServerPart implements ServerPartContract {
  final Server _server;

  _FakeServerPart(this._server);

  @override
  Future<Server> get(Object id, bool force) async => _server;

  @override
  Future<Server> update(Object id, Map<String, dynamic> payload,
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

// ── Domain object builders ────────────────────────────────────────────────────

ServerTextChannel _buildServerTextChannel(EntityContext ctx) =>
    ServerTextChannel(
      ChannelProperties(
        ctx: ctx,
        id: Snowflake.parse(_channelId),
        type: ChannelType.guildText,
        name: 'general',
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

// ── Shard message factory ─────────────────────────────────────────────────────

ShardMessage<dynamic> _buildShardMessage() => ShardMessage(
      type: 'WEBHOOKS_UPDATE',
      opCode: OpCode.dispatch,
      sequence: 1,
      payload: {
        'guild_id': _serverId,
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

    // ── server branch ───────────────────────────────────────────────────────

    group('dispatches serverWebhooksUpdate with resolved server and channel',
        () {
      late WebhooksUpdatePacket packet;
      late Server server;
      late ServerTextChannel channel;

      setUp(() {
        late _FakeDataStore ds;

        final ctx = EntityContext(
          datastore: _DeferredDataStore(() => ds),
          wss: FakeWebsocketOrchestrator(),
          logger: FakeLogger(),
          runtimeState: RuntimeState(),
        );

        channel = _buildServerTextChannel(ctx);
        server = _buildServer(ctx);

        ds = _FakeDataStore(
          channelPart: _FakeChannelPart(channel),
          serverPart: _FakeServerPart(server),
        );

        packet = WebhooksUpdatePacket(dataStore: ds);
      });

      test('dispatches Event.serverWebhooksUpdate', () async {
        Event? capturedEvent;

        void dispatch<T extends Object>(
            {required Event event,
            required T payload,
            bool Function(String?)? constraint}) {
          capturedEvent = event;
        }

        await packet.listen(_buildShardMessage(), dispatch);

        expect(capturedEvent, equals(Event.serverWebhooksUpdate));
      });

      test('payload is ServerWebhooksUpdateArgs', () async {
        Object? capturedPayload;

        void dispatch<T extends Object>(
            {required Event event,
            required T payload,
            bool Function(String?)? constraint}) {
          capturedPayload = payload;
        }

        await packet.listen(_buildShardMessage(), dispatch);

        expect(capturedPayload, isA<ServerWebhooksUpdateArgs>());
      });

      test('payload carries the resolved server', () async {
        ServerWebhooksUpdateArgs? args;

        void dispatch<T extends Object>(
            {required Event event,
            required T payload,
            bool Function(String?)? constraint}) {
          if (event == Event.serverWebhooksUpdate) {
            args = payload as ServerWebhooksUpdateArgs;
          }
        }

        await packet.listen(_buildShardMessage(), dispatch);

        expect(args, isNotNull);
        expect(args!.server.id, equals(Snowflake.parse(_serverId)));
        expect(args!.server.name, equals('Test Server'));
      });

      test('payload carries the resolved channel', () async {
        ServerWebhooksUpdateArgs? args;

        void dispatch<T extends Object>(
            {required Event event,
            required T payload,
            bool Function(String?)? constraint}) {
          if (event == Event.serverWebhooksUpdate) {
            args = payload as ServerWebhooksUpdateArgs;
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
