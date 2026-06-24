import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/common/runtime_state.dart';
import 'package:mineral/src/domains/services/datastore/request_bucket_contract.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_role_create_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_role_delete_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_role_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:test/test.dart';

import '../helpers/fake_cache_provider.dart';
import '../helpers/fake_logger.dart';
import '../helpers/fake_marshaller.dart';
import '../helpers/fake_websocket_orchestrator.dart';
import 'helpers/packet_test_helpers.dart';

// ── IDs ───────────────────────────────────────────────────────────────────────

const _guildId = '123456789012345678';
const _roleId = '111222333444555666';

// ── Minimal role payload ──────────────────────────────────────────────────────

Map<String, dynamic> _rolePayload() => {
      'id': _roleId,
      'name': 'TestRole',
      'color': 0,
      'hoist': false,
      'position': 1,
      'permissions': '0',
      'managed': false,
      'mentionable': true,
      'flags': 0,
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
  late FakeWebsocketOrchestrator wss;
  late FakeCacheProvider cache;
  late FakeMarshaller marshaller;
  late Guild fakeGuild;
  late _FakeDataStore dataStore;

  setUp(() {
    wss = FakeWebsocketOrchestrator();
    cache = FakeCacheProvider();

    late _FakeDataStore dsFinal;
    marshaller = FakeMarshaller(
      cache: cache,
      entityContext: EntityContext(
        datastore: LazyDataStore(() => dsFinal),
        wss: wss,
        logger: FakeLogger(),
        runtimeState: RuntimeState(),
      ),
    );

    final ctx = EntityContext(
      datastore: LazyDataStore(() => dsFinal),
      wss: wss,
      logger: FakeLogger(),
      runtimeState: RuntimeState(),
    );

    fakeGuild = buildMinimalGuild(_guildId, ctx);
    dsFinal = _FakeDataStore(FakeGuildPart(fakeGuild));
    dataStore = dsFinal;
  });

  // ── GUILD_ROLE_CREATE ──────────────────────────────────────────────────────

  group('GuildRoleCreatePacket', () {
    test('packetType is PacketType.guildRoleCreate', () {
      final packet =
          GuildRoleCreatePacket(marshaller: marshaller, dataStore: dataStore);
      expect(packet.packetType, equals(PacketType.guildRoleCreate));
      expect(packet.packetType.name, equals('GUILD_ROLE_CREATE'));
    });

    test('dispatches Event.guildRoleCreate', () async {
      final packet =
          GuildRoleCreatePacket(marshaller: marshaller, dataStore: dataStore);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(
          _msg('GUILD_ROLE_CREATE', {'guild_id': _guildId, 'role': _rolePayload()}),
          dispatch);

      expect(capturedEvent, equals(Event.guildRoleCreate));
    });

    test('payload carries guild and role', () async {
      final packet =
          GuildRoleCreatePacket(marshaller: marshaller, dataStore: dataStore);
      GuildRoleCreateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildRoleCreate) {
          args = payload as GuildRoleCreateArgs;
        }
      }

      await packet.listen(
          _msg('GUILD_ROLE_CREATE', {'guild_id': _guildId, 'role': _rolePayload()}),
          dispatch);

      expect(args, isNotNull);
      expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
      expect(args!.role.id, equals(Snowflake.parse(_roleId)));
      expect(args!.role.name, equals('TestRole'));
    });
  });

  // ── GUILD_ROLE_UPDATE ──────────────────────────────────────────────────────

  group('GuildRoleUpdatePacket', () {
    test('packetType is PacketType.guildRoleUpdate', () {
      final packet =
          GuildRoleUpdatePacket(marshaller: marshaller, dataStore: dataStore);
      expect(packet.packetType, equals(PacketType.guildRoleUpdate));
      expect(packet.packetType.name, equals('GUILD_ROLE_UPDATE'));
    });

    test('dispatches Event.guildRoleUpdate', () async {
      final packet =
          GuildRoleUpdatePacket(marshaller: marshaller, dataStore: dataStore);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(
          _msg('GUILD_ROLE_UPDATE', {'guild_id': _guildId, 'role': _rolePayload()}),
          dispatch);

      expect(capturedEvent, equals(Event.guildRoleUpdate));
    });

    test('before is null when role not in cache', () async {
      final packet =
          GuildRoleUpdatePacket(marshaller: marshaller, dataStore: dataStore);
      GuildRoleUpdateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildRoleUpdate) {
          args = payload as GuildRoleUpdateArgs;
        }
      }

      await packet.listen(
          _msg('GUILD_ROLE_UPDATE', {'guild_id': _guildId, 'role': _rolePayload()}),
          dispatch);

      expect(args, isNotNull);
      expect(args!.before, isNull);
      expect(args!.after.id, equals(Snowflake.parse(_roleId)));
    });

    test('before is populated when role is in cache', () async {
      // Pre-seed old role data into cache.
      final roleCacheKey = marshaller.cacheKey.guildRole(_guildId, _roleId);
      final oldRole = Map<String, dynamic>.from(_rolePayload())
        ..['name'] = 'OldRoleName';
      await cache.put(roleCacheKey, oldRole);

      final packet =
          GuildRoleUpdatePacket(marshaller: marshaller, dataStore: dataStore);
      GuildRoleUpdateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildRoleUpdate) {
          args = payload as GuildRoleUpdateArgs;
        }
      }

      final updatedRole = Map<String, dynamic>.from(_rolePayload())
        ..['name'] = 'NewRoleName';

      await packet.listen(
          _msg('GUILD_ROLE_UPDATE', {'guild_id': _guildId, 'role': updatedRole}),
          dispatch);

      expect(args, isNotNull);
      expect(args!.before, isNotNull);
      expect(args!.before!.name, equals('OldRoleName'));
      expect(args!.after.name, equals('NewRoleName'));
    });
  });

  // ── GUILD_ROLE_DELETE ──────────────────────────────────────────────────────

  group('GuildRoleDeletePacket', () {
    test('packetType is PacketType.guildRoleDelete', () {
      final packet =
          GuildRoleDeletePacket(marshaller: marshaller, dataStore: dataStore);
      expect(packet.packetType, equals(PacketType.guildRoleDelete));
      expect(packet.packetType.name, equals('GUILD_ROLE_DELETE'));
    });

    test('dispatches Event.guildRoleDelete', () async {
      final packet =
          GuildRoleDeletePacket(marshaller: marshaller, dataStore: dataStore);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(
          _msg('GUILD_ROLE_DELETE', {'guild_id': _guildId, 'role_id': _roleId}),
          dispatch);

      expect(capturedEvent, equals(Event.guildRoleDelete));
    });

    test('role is invalidated from cache on delete', () async {
      final roleCacheKey = marshaller.cacheKey.guildRole(_guildId, _roleId);
      await cache.put(roleCacheKey, _rolePayload());

      final packet =
          GuildRoleDeletePacket(marshaller: marshaller, dataStore: dataStore);

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {}

      await packet.listen(
          _msg('GUILD_ROLE_DELETE', {'guild_id': _guildId, 'role_id': _roleId}),
          dispatch);

      final cached = await cache.get(roleCacheKey);
      expect(cached, isNull);
    });

    test('payload carries guild and role from cache when present', () async {
      final roleCacheKey = marshaller.cacheKey.guildRole(_guildId, _roleId);
      await cache.put(roleCacheKey, _rolePayload());

      final packet =
          GuildRoleDeletePacket(marshaller: marshaller, dataStore: dataStore);
      GuildRoleDeleteArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildRoleDelete) {
          args = payload as GuildRoleDeleteArgs;
        }
      }

      await packet.listen(
          _msg('GUILD_ROLE_DELETE', {'guild_id': _guildId, 'role_id': _roleId}),
          dispatch);

      expect(args, isNotNull);
      expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
      expect(args!.role?.id, equals(Snowflake.parse(_roleId)));
    });

    test('role is null in payload on cache miss', () async {
      final packet =
          GuildRoleDeletePacket(marshaller: marshaller, dataStore: dataStore);
      GuildRoleDeleteArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildRoleDelete) {
          args = payload as GuildRoleDeleteArgs;
        }
      }

      await packet.listen(
          _msg('GUILD_ROLE_DELETE', {'guild_id': _guildId, 'role_id': _roleId}),
          dispatch);

      expect(args, isNotNull);
      expect(args!.role, isNull);
    });
  });
}

// ── Fake DataStore ────────────────────────────────────────────────────────────

final class _FakeDataStore implements DataStoreContract {
  final GuildPartContract _guildPart;
  _FakeDataStore(this._guildPart);

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
  MonetizationPartContract get monetization => throw UnimplementedError();
  @override
  SoundboardPartContract get soundboard => throw UnimplementedError();
  @override
  RequestBucketContract get requestBucket => throw UnimplementedError();
  @override
  HttpClientContract get client => throw UnimplementedError();
}
