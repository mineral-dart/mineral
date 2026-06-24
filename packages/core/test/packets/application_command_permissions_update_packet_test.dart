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
import 'package:mineral/src/infrastructure/internals/packets/listeners/application_command_permissions_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:test/test.dart';

import '../helpers/fake_logger.dart';
import '../helpers/fake_websocket_orchestrator.dart';

// ── Test IDs ──────────────────────────────────────────────────────────────────

const _guildId = '123456789012345678';
const _applicationId = '222333444555666777';
const _commandId = '111000111000111000';
const _roleId = '333444555666777888';
const _userId = '444555666777888999';
const _channelId = '555666777888999000';

// ── No-op stub ────────────────────────────────────────────────────────────────

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
  SoundboardPartContract get soundboard => throw UnimplementedError();
  @override
  RequestBucketContract get requestBucket => throw UnimplementedError();
  @override
  HttpClientContract get client => throw UnimplementedError();
}

// ── Deferred data store ───────────────────────────────────────────────────────

final class _DeferredDataStore implements DataStoreContract {
  final DataStoreContract Function() _resolve;

  _DeferredDataStore(this._resolve);

  @override
  GuildPartContract get guild => _resolve().guild;
  @override
  ChannelPartContract get channel => _resolve().channel;
  @override
  MemberPartContract get member => throw UnimplementedError();
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
  @override
  RequestBucketContract get requestBucket => throw UnimplementedError();
  @override
  HttpClientContract get client => throw UnimplementedError();
}

// ── Fake data store ───────────────────────────────────────────────────────────

final class _FakeDataStore implements DataStoreContract {
  final GuildPartContract _guildPart;

  _FakeDataStore({required GuildPartContract guildPart})
      : _guildPart = guildPart;

  @override
  GuildPartContract get guild => _guildPart;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());

  @override
  ChannelPartContract get channel => throw UnimplementedError();
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
  SoundboardPartContract get soundboard => throw UnimplementedError();
  @override
  RequestBucketContract get requestBucket => throw UnimplementedError();
  @override
  HttpClientContract get client => throw UnimplementedError();
}

// ── Fake guild part ──────────────────────────────────────────────────────────

final class _FakeServerPart implements GuildPartContract {
  final Guild _guild;

  _FakeServerPart(this._guild);

  @override
  Future<Guild> get(Object id, bool force) async => _guild;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

// ── Domain object builder ─────────────────────────────────────────────────────

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
      type: 'APPLICATION_COMMAND_PERMISSIONS_UPDATE',
      opCode: OpCode.dispatch,
      sequence: 1,
      payload: {
        'id': _commandId,
        'application_id': _applicationId,
        'guild_id': _guildId,
        'permissions': [
          {'id': _roleId, 'type': 1, 'permission': true},
          {'id': _userId, 'type': 2, 'permission': false},
          {'id': _channelId, 'type': 3, 'permission': true},
        ],
      },
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('ApplicationCommandPermissionsUpdatePacket', () {
    // ── packetType identity ─────────────────────────────────────────────────

    test('packetType is applicationCommandPermissionsUpdate', () {
      final packet =
          ApplicationCommandPermissionsUpdatePacket(dataStore: _NoopDs());
      expect(packet.packetType,
          equals(PacketType.applicationCommandPermissionsUpdate));
      expect(packet.packetType.name,
          equals('APPLICATION_COMMAND_PERMISSIONS_UPDATE'));
    });

    // ── dispatch ────────────────────────────────────────────────────────────

    group('dispatches guildApplicationCommandPermissionsUpdate', () {
      late ApplicationCommandPermissionsUpdatePacket packet;
      late Guild guild;

      setUp(() {
        late _FakeDataStore ds;

        final ctx = EntityContext(
          datastore: _DeferredDataStore(() => ds),
          wss: FakeWebsocketOrchestrator(),
          logger: FakeLogger(),
          runtimeState: RuntimeState(),
        );

        guild = _buildServer(ctx);

        ds = _FakeDataStore(guildPart: _FakeServerPart(guild));

        packet = ApplicationCommandPermissionsUpdatePacket(dataStore: ds);
      });

      test('dispatches Event.guildApplicationCommandPermissionsUpdate',
          () async {
        Event? capturedEvent;

        void dispatch<T extends Object>(
            {required Event event,
            required T payload,
            bool Function(String?)? constraint}) {
          capturedEvent = event;
        }

        await packet.listen(_buildShardMessage(), dispatch);

        expect(capturedEvent,
            equals(Event.guildApplicationCommandPermissionsUpdate));
      });

      test('payload is GuildApplicationCommandPermissionsUpdateArgs', () async {
        Object? capturedPayload;

        void dispatch<T extends Object>(
            {required Event event,
            required T payload,
            bool Function(String?)? constraint}) {
          capturedPayload = payload;
        }

        await packet.listen(_buildShardMessage(), dispatch);

        expect(capturedPayload,
            isA<GuildApplicationCommandPermissionsUpdateArgs>());
      });

      test('payload carries the resolved guild', () async {
        GuildApplicationCommandPermissionsUpdateArgs? args;

        void dispatch<T extends Object>(
            {required Event event,
            required T payload,
            bool Function(String?)? constraint}) {
          if (event == Event.guildApplicationCommandPermissionsUpdate) {
            args = payload as GuildApplicationCommandPermissionsUpdateArgs;
          }
        }

        await packet.listen(_buildShardMessage(), dispatch);

        expect(args, isNotNull);
        expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
        expect(args!.guild.name, equals('Test Guild'));
      });

      test('GuildApplicationCommandPermissions has correct ids', () async {
        GuildApplicationCommandPermissionsUpdateArgs? args;

        void dispatch<T extends Object>(
            {required Event event,
            required T payload,
            bool Function(String?)? constraint}) {
          if (event == Event.guildApplicationCommandPermissionsUpdate) {
            args = payload as GuildApplicationCommandPermissionsUpdateArgs;
          }
        }

        await packet.listen(_buildShardMessage(), dispatch);

        expect(args, isNotNull);
        final perms = args!.permissions;
        expect(perms.id, equals(Snowflake.parse(_commandId)));
        expect(perms.applicationId, equals(Snowflake.parse(_applicationId)));
        expect(perms.guildId, equals(Snowflake.parse(_guildId)));
      });

      test('permissions list has correct entries with correct types', () async {
        GuildApplicationCommandPermissionsUpdateArgs? args;

        void dispatch<T extends Object>(
            {required Event event,
            required T payload,
            bool Function(String?)? constraint}) {
          if (event == Event.guildApplicationCommandPermissionsUpdate) {
            args = payload as GuildApplicationCommandPermissionsUpdateArgs;
          }
        }

        await packet.listen(_buildShardMessage(), dispatch);

        expect(args, isNotNull);
        final entries = args!.permissions.permissions;
        expect(entries, hasLength(3));

        // role entry
        expect(entries[0].id, equals(Snowflake.parse(_roleId)));
        expect(entries[0].type, equals(ApplicationCommandPermissionType.role));
        expect(entries[0].permission, isTrue);

        // user entry
        expect(entries[1].id, equals(Snowflake.parse(_userId)));
        expect(entries[1].type, equals(ApplicationCommandPermissionType.user));
        expect(entries[1].permission, isFalse);

        // channel entry
        expect(entries[2].id, equals(Snowflake.parse(_channelId)));
        expect(
            entries[2].type, equals(ApplicationCommandPermissionType.channel));
        expect(entries[2].permission, isTrue);
      });
    });
  });
}
