import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_member_add_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_member_chunk_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_member_remove_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_member_update_packet.dart';
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
    },
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

// ── Fake member part ──────────────────────────────────────────────────────────

class _FakeMemberPart extends Mock implements MemberPartContract {
  final Member _member;
  _FakeMemberPart(this._member);

  @override
  Future<Member?> get(Object guildId, Object memberId, bool force) async =>
      _member;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeWebsocketOrchestrator wss;
  late FakeCacheProvider cache;
  late FakeMarshaller marshaller;
  late Guild fakeGuild;
  late MockDataStore dataStore;

  setUp(() async {
    wss = FakeWebsocketOrchestrator();
    cache = FakeCacheProvider();

    dataStore = MockDataStore();

    marshaller = FakeMarshaller(
      cache: cache,
      entityContext: buildCtx(dataStore: dataStore, wss: wss),
    );

    fakeGuild = buildMinimalGuild(
      _guildId,
      buildCtx(dataStore: dataStore, wss: wss),
    );

    // Also pre-populate a normalized member in cache (needed for update test).
    final normalizedMember = await marshaller.serializers.member.normalize({
      ..._memberPayload(),
      'guild_id': _guildId,
    });

    final user = await marshaller.serializers.user.serialize(
      await marshaller.serializers.user.normalize({
        'id': _userId,
        'username': 'TestMember',
        'discriminator': '0001',
        'avatar': null,
        'bot': false,
        'global_name': null,
        'public_flags': 0,
      }),
    );

    final member = await marshaller.serializers.member.serialize(
      normalizedMember,
    );

    when(() => dataStore.guild).thenReturn(FakeGuildPart(fakeGuild));
    when(() => dataStore.user).thenReturn(FakeUserPart(user));
    when(() => dataStore.member).thenReturn(_FakeMemberPart(member));
  });

  // ── GUILD_MEMBER_ADD ───────────────────────────────────────────────────────

  group('GuildMemberAddPacket', () {
    test('packetType is PacketType.guildMemberAdd', () {
      final packet = GuildMemberAddPacket(
        marshaller: marshaller,
        dataStore: dataStore,
      );
      expect(packet.packetType, equals(PacketType.guildMemberAdd));
      expect(packet.packetType.name, equals('GUILD_MEMBER_ADD'));
    });

    test('dispatches Event.guildMemberAdd', () async {
      final packet = GuildMemberAddPacket(
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

      await packet.listen(_msg('GUILD_MEMBER_ADD', _memberPayload()), dispatch);

      expect(capturedEvent, equals(Event.guildMemberAdd));
    });

    test('payload carries guild and member', () async {
      final packet = GuildMemberAddPacket(
        marshaller: marshaller,
        dataStore: dataStore,
      );
      GuildMemberAddArgs? args;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
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
        marshaller: marshaller,
        dataStore: dataStore,
      );
      expect(packet.packetType, equals(PacketType.guildMemberRemove));
      expect(packet.packetType.name, equals('GUILD_MEMBER_REMOVE'));
    });

    test('dispatches Event.guildMemberRemove', () async {
      final packet = GuildMemberRemovePacket(
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
        _msg('GUILD_MEMBER_REMOVE', _memberRemovePayload()),
        dispatch,
      );

      expect(capturedEvent, equals(Event.guildMemberRemove));
    });

    test('payload carries guild and user', () async {
      final packet = GuildMemberRemovePacket(
        marshaller: marshaller,
        dataStore: dataStore,
      );
      GuildMemberRemoveArgs? args;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        if (event == Event.guildMemberRemove) {
          args = payload as GuildMemberRemoveArgs;
        }
      }

      await packet.listen(
        _msg('GUILD_MEMBER_REMOVE', _memberRemovePayload()),
        dispatch,
      );

      expect(args, isNotNull);
      expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
      expect(args!.user?.id, equals(Snowflake.parse(_userId)));
    });

    test('member is invalidated from cache on remove', () async {
      final memberKey = marshaller.cacheKey.member(_guildId, _userId);
      await cache.put(memberKey, {'id': _userId, 'username': 'TestMember'});

      final packet = GuildMemberRemovePacket(
        marshaller: marshaller,
        dataStore: dataStore,
      );

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {}

      await packet.listen(
        _msg('GUILD_MEMBER_REMOVE', _memberRemovePayload()),
        dispatch,
      );

      final cached = await cache.get(memberKey);
      expect(cached, isNull);
    });
  });

  // ── GUILD_MEMBER_UPDATE ────────────────────────────────────────────────────

  group('GuildMemberUpdatePacket', () {
    test('packetType is PacketType.guildMemberUpdate', () {
      final packet = GuildMemberUpdatePacket(
        marshaller: marshaller,
        dataStore: dataStore,
      );
      expect(packet.packetType, equals(PacketType.guildMemberUpdate));
      expect(packet.packetType.name, equals('GUILD_MEMBER_UPDATE'));
    });

    test('dispatches Event.guildMemberUpdate', () async {
      final packet = GuildMemberUpdatePacket(
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
        _msg('GUILD_MEMBER_UPDATE', _memberPayload()),
        dispatch,
      );

      expect(capturedEvent, equals(Event.guildMemberUpdate));
    });

    test('payload carries guild, before and after member', () async {
      final packet = GuildMemberUpdatePacket(
        marshaller: marshaller,
        dataStore: dataStore,
      );
      GuildMemberUpdateArgs? args;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        if (event == Event.guildMemberUpdate) {
          args = payload as GuildMemberUpdateArgs;
        }
      }

      await packet.listen(
        _msg('GUILD_MEMBER_UPDATE', _memberPayload()),
        dispatch,
      );

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
        marshaller: marshaller,
        dataStore: dataStore,
        wss: wss,
      );
      expect(packet.packetType, equals(PacketType.guildMemberChunk));
      expect(packet.packetType.name, equals('GUILD_MEMBERS_CHUNK'));
    });

    test('dispatches Event.guildMemberChunk', () async {
      final packet = GuildMemberChunkPacket(
        marshaller: marshaller,
        dataStore: dataStore,
        wss: wss,
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
        _msg('GUILD_MEMBERS_CHUNK', _chunkPayload()),
        dispatch,
      );

      expect(capturedEvent, equals(Event.guildMemberChunk));
    });

    test('payload carries guild and members list', () async {
      final packet = GuildMemberChunkPacket(
        marshaller: marshaller,
        dataStore: dataStore,
        wss: wss,
      );
      GuildMemberChunkArgs? args;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        if (event == Event.guildMemberChunk) {
          args = payload as GuildMemberChunkArgs;
        }
      }

      await packet.listen(
        _msg('GUILD_MEMBERS_CHUNK', _chunkPayload()),
        dispatch,
      );

      expect(args, isNotNull);
      expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
      expect(args!.members, hasLength(1));
    });
  });
}
