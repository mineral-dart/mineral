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
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_member_add_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_member_chunk_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_member_remove_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_member_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:test/test.dart';

import '../helpers/fake_cache_provider.dart';
import '../helpers/fake_logger.dart';
import '../helpers/fake_marshaller.dart';
import '../helpers/fake_websocket_orchestrator.dart';

// ── IDs ───────────────────────────────────────────────────────────────────────

const _guildId = '123456789012345678';
const _userId = '111222333444555666';

// ── Minimal payloads ──────────────────────────────────────────────────────────

Map<String, dynamic> _memberPayload() => {
      'guild_id': _guildId,
      'user': {
        'id': _userId,
        'username': 'TestMember',
        'discriminator': '0001',
        'avatar': null,
        'bot': false,
        'global_name': null,
        'public_flags': 0,
      },
      'nick': null,
      'roles': <String>[],
      'joined_at': '2024-01-01T00:00:00.000Z',
      'deaf': false,
      'mute': false,
      'flags': 0,
      'pending': false,
    };

Map<String, dynamic> _memberRemovePayload() => {
      'guild_id': _guildId,
      'user': {
        'id': _userId,
        'username': 'TestMember',
        'discriminator': '0001',
        'avatar': null,
        'bot': false,
      },
    };

Map<String, dynamic> _chunkPayload() => {
      'guild_id': _guildId,
      'members': <Map<String, dynamic>>[
        {
          'user': {
            'id': _userId,
            'username': 'TestMember',
            'discriminator': '0001',
            'avatar': null,
            'bot': false,
            'global_name': null,
            'public_flags': 0,
          },
          'nick': null,
          'roles': <String>[],
          'joined_at': '2024-01-01T00:00:00.000Z',
          'deaf': false,
          'mute': false,
          'flags': 0,
          'pending': false,
        }
      ],
      'presences': <dynamic>[],
      'nonce': 'test-nonce-001',
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
  late FakeWebsocketOrchestrator wss;
  late FakeCacheProvider cache;
  late FakeMarshaller marshaller;
  late Guild fakeGuild;
  late _FakeDataStore dataStore;

  setUp(() async {
    wss = FakeWebsocketOrchestrator();
    cache = FakeCacheProvider();

    late _FakeDataStore dsFinal;
    marshaller = FakeMarshaller(
      cache: cache,
      entityContext: EntityContext(
        datastore: _LazyDataStore(() => dsFinal),
        wss: wss,
        logger: FakeLogger(),
        runtimeState: RuntimeState(),
      ),
    );

    // Build guild through the serializer so managers get correct context.
    final ctx = EntityContext(
      datastore: _LazyDataStore(() => dsFinal),
      wss: wss,
      logger: FakeLogger(),
      runtimeState: RuntimeState(),
    );
    fakeGuild = _minimalGuild(ctx);

    // Also pre-populate a normalized member in cache (needed for update test).
    final normalizedMember = await marshaller.serializers.member.normalize({
      ..._memberPayload(),
      'guild_id': _guildId,
    });

    dsFinal = _FakeDataStore(
      guildPart: _FakeGuildPart(fakeGuild),
      userPart: _FakeUserPart(
        await marshaller.serializers.user.serialize(
          await marshaller.serializers.user.normalize({
            'id': _userId,
            'username': 'TestMember',
            'discriminator': '0001',
            'avatar': null,
            'bot': false,
            'global_name': null,
            'public_flags': 0,
          }),
        ),
      ),
      memberPart: _FakeMemberPart(
        await marshaller.serializers.member.serialize(normalizedMember),
      ),
    );
    dataStore = dsFinal;
  });

  // ── GUILD_MEMBER_ADD ───────────────────────────────────────────────────────

  group('GuildMemberAddPacket', () {
    test('packetType is PacketType.guildMemberAdd', () {
      final packet =
          GuildMemberAddPacket(marshaller: marshaller, dataStore: dataStore);
      expect(packet.packetType, equals(PacketType.guildMemberAdd));
      expect(packet.packetType.name, equals('GUILD_MEMBER_ADD'));
    });

    test('dispatches Event.guildMemberAdd', () async {
      final packet =
          GuildMemberAddPacket(marshaller: marshaller, dataStore: dataStore);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_msg('GUILD_MEMBER_ADD', _memberPayload()), dispatch);

      expect(capturedEvent, equals(Event.guildMemberAdd));
    });

    test('payload carries guild and member', () async {
      final packet =
          GuildMemberAddPacket(marshaller: marshaller, dataStore: dataStore);
      GuildMemberAddArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildMemberAdd) {
          args = payload as GuildMemberAddArgs;
        }
      }

      await packet.listen(_msg('GUILD_MEMBER_ADD', _memberPayload()), dispatch);

      expect(args, isNotNull);
      expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
      expect(args!.member.id, equals(Snowflake.parse(_userId)));
    });
  });

  // ── GUILD_MEMBER_REMOVE ────────────────────────────────────────────────────

  group('GuildMemberRemovePacket', () {
    test('packetType is PacketType.guildMemberRemove', () {
      final packet = GuildMemberRemovePacket(
          marshaller: marshaller, dataStore: dataStore);
      expect(packet.packetType, equals(PacketType.guildMemberRemove));
      expect(packet.packetType.name, equals('GUILD_MEMBER_REMOVE'));
    });

    test('dispatches Event.guildMemberRemove', () async {
      final packet = GuildMemberRemovePacket(
          marshaller: marshaller, dataStore: dataStore);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(
          _msg('GUILD_MEMBER_REMOVE', _memberRemovePayload()), dispatch);

      expect(capturedEvent, equals(Event.guildMemberRemove));
    });

    test('payload carries guild and user', () async {
      final packet = GuildMemberRemovePacket(
          marshaller: marshaller, dataStore: dataStore);
      GuildMemberRemoveArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildMemberRemove) {
          args = payload as GuildMemberRemoveArgs;
        }
      }

      await packet.listen(
          _msg('GUILD_MEMBER_REMOVE', _memberRemovePayload()), dispatch);

      expect(args, isNotNull);
      expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
      expect(args!.user?.id, equals(Snowflake.parse(_userId)));
    });

    test('member is invalidated from cache on remove', () async {
      final memberKey = marshaller.cacheKey.member(_guildId, _userId);
      await cache.put(memberKey, {'id': _userId, 'username': 'TestMember'});

      final packet = GuildMemberRemovePacket(
          marshaller: marshaller, dataStore: dataStore);

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {}

      await packet.listen(
          _msg('GUILD_MEMBER_REMOVE', _memberRemovePayload()), dispatch);

      final cached = await cache.get(memberKey);
      expect(cached, isNull);
    });
  });

  // ── GUILD_MEMBER_UPDATE ────────────────────────────────────────────────────

  group('GuildMemberUpdatePacket', () {
    test('packetType is PacketType.guildMemberUpdate', () {
      final packet = GuildMemberUpdatePacket(
          marshaller: marshaller, dataStore: dataStore);
      expect(packet.packetType, equals(PacketType.guildMemberUpdate));
      expect(packet.packetType.name, equals('GUILD_MEMBER_UPDATE'));
    });

    test('dispatches Event.guildMemberUpdate', () async {
      final packet = GuildMemberUpdatePacket(
          marshaller: marshaller, dataStore: dataStore);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(
          _msg('GUILD_MEMBER_UPDATE', _memberPayload()), dispatch);

      expect(capturedEvent, equals(Event.guildMemberUpdate));
    });

    test('payload carries guild, before and after member', () async {
      final packet = GuildMemberUpdatePacket(
          marshaller: marshaller, dataStore: dataStore);
      GuildMemberUpdateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildMemberUpdate) {
          args = payload as GuildMemberUpdateArgs;
        }
      }

      await packet.listen(
          _msg('GUILD_MEMBER_UPDATE', _memberPayload()), dispatch);

      expect(args, isNotNull);
      expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
      expect(args!.after.id, equals(Snowflake.parse(_userId)));
      expect(args!.before.id, equals(Snowflake.parse(_userId)));
    });
  });

  // ── GUILD_MEMBERS_CHUNK ────────────────────────────────────────────────────

  group('GuildMemberChunkPacket', () {
    test('packetType is PacketType.guildMemberChunk', () {
      final packet = GuildMemberChunkPacket(
          marshaller: marshaller, dataStore: dataStore, wss: wss);
      expect(packet.packetType, equals(PacketType.guildMemberChunk));
      expect(packet.packetType.name, equals('GUILD_MEMBERS_CHUNK'));
    });

    test('dispatches Event.guildMemberChunk', () async {
      final packet = GuildMemberChunkPacket(
          marshaller: marshaller, dataStore: dataStore, wss: wss);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(
          _msg('GUILD_MEMBERS_CHUNK', _chunkPayload()), dispatch);

      expect(capturedEvent, equals(Event.guildMemberChunk));
    });

    test('payload carries guild and members list', () async {
      final packet = GuildMemberChunkPacket(
          marshaller: marshaller, dataStore: dataStore, wss: wss);
      GuildMemberChunkArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildMemberChunk) {
          args = payload as GuildMemberChunkArgs;
        }
      }

      await packet.listen(
          _msg('GUILD_MEMBERS_CHUNK', _chunkPayload()), dispatch);

      expect(args, isNotNull);
      expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
      expect(args!.members, hasLength(1));
    });
  });
}

// ── Domain object helpers ─────────────────────────────────────────────────────

Guild _minimalGuild(EntityContext ctx) {
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

// ── Shared fakes ──────────────────────────────────────────────────────────────

final class _FakeGuildPart implements GuildPartContract {
  final Guild _guild;
  _FakeGuildPart(this._guild);

  @override
  Future<Guild> get(Object id, bool force) async => _guild;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

final class _FakeUserPart implements UserPartContract {
  final User _user;
  _FakeUserPart(this._user);

  @override
  Future<User?> get(Object id, bool force) async => _user;
}

final class _FakeMemberPart implements MemberPartContract {
  final Member _member;
  _FakeMemberPart(this._member);

  @override
  Future<Member?> get(Object guildId, Object memberId, bool force) async =>
      _member;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

final class _FakeDataStore implements DataStoreContract {
  final GuildPartContract _guildPart;
  final UserPartContract _userPart;
  final MemberPartContract _memberPart;

  _FakeDataStore({
    required GuildPartContract guildPart,
    required UserPartContract userPart,
    required MemberPartContract memberPart,
  })  : _guildPart = guildPart,
        _userPart = userPart,
        _memberPart = memberPart;

  @override
  GuildPartContract get guild => _guildPart;
  @override
  UserPartContract get user => _userPart;
  @override
  MemberPartContract get member => _memberPart;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());

  @override
  ChannelPartContract get channel => throw UnimplementedError();
  @override
  MessagePartContract get message => throw UnimplementedError();
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

final class _LazyDataStore implements DataStoreContract {
  final DataStoreContract Function() _resolve;
  _LazyDataStore(this._resolve);

  @override
  GuildPartContract get guild => _resolve().guild;
  @override
  MemberPartContract get member => _resolve().member;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());

  @override
  ChannelPartContract get channel => throw UnimplementedError();
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
