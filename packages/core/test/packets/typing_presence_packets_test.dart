/// Tests for TYPING_START and PRESENCE_UPDATE.
library;

import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/presence_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/typing_packet.dart';
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
const _channelId = '777888999000111222';

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

// ── Helper: build a wired MockDataStore with guild + member ───────────────────

Future<MockDataStore> _buildDs(FakeWebsocketOrchestrator wss) async {
  final ds = MockDataStore();
  final cache = FakeCacheProvider();
  final marshaller = FakeMarshaller(
    cache: cache,
    entityContext: buildCtx(dataStore: ds, wss: wss),
  );

  final guild = buildMinimalGuild(_guildId, buildCtx(dataStore: ds, wss: wss));
  final member = await marshaller.serializers.member.serialize(
    await marshaller.serializers.member.normalize({
      'guild_id': _guildId,
      'user': {
        'id': _userId,
        'username': 'TypingUser',
        'discriminator': '0000',
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
    }),
  );

  when(() => ds.guild).thenReturn(FakeGuildPart(guild));
  when(() => ds.member).thenReturn(_FakeMemberPart(member));
  return ds;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeWebsocketOrchestrator wss;
  late MockDataStore ds;

  setUp(() async {
    wss = FakeWebsocketOrchestrator();
    ds = await _buildDs(wss);
  });

  // ── TYPING_START ───────────────────────────────────────────────────────────

  group('TypingPacket', () {
    test('packetType is PacketType.typingStart', () {
      final packet = TypingPacket(
        ctx: buildCtx(dataStore: ds, wss: wss),
      );
      expect(packet.packetType, equals(PacketType.typingStart));
      expect(packet.packetType.name, equals('TYPING_START'));
    });

    test('dispatches Event.typing', () async {
      final packet = TypingPacket(
        ctx: buildCtx(dataStore: ds, wss: wss),
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
        _msg('TYPING_START', {
          'channel_id': _channelId,
          'guild_id': _guildId,
          'user_id': _userId,
          'timestamp': 1700000000,
        }),
        dispatch,
      );

      expect(capturedEvent, equals(Event.typing));
    });

    test('payload is TypingArgs with correct Typing object', () async {
      final packet = TypingPacket(
        ctx: buildCtx(dataStore: ds, wss: wss),
      );
      TypingArgs? args;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        if (event == Event.typing) {
          args = payload as TypingArgs;
        }
      }

      await packet.listen(
        _msg('TYPING_START', {
          'channel_id': _channelId,
          'guild_id': _guildId,
          'user_id': _userId,
          'timestamp': 1700000000,
        }),
        dispatch,
      );

      expect(args, isNotNull);
      final typing = args!.typing;
      expect(typing.channelId, equals(Snowflake.parse(_channelId)));
      expect(typing.userId, equals(Snowflake.parse(_userId)));
      expect(typing.guildId, equals(Snowflake.parse(_guildId)));
    });

    test('typing has no guild for DM typing', () async {
      final packet = TypingPacket(
        ctx: buildCtx(dataStore: ds, wss: wss),
      );
      TypingArgs? args;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        if (event == Event.typing) {
          args = payload as TypingArgs;
        }
      }

      await packet.listen(
        _msg('TYPING_START', {
          'channel_id': _channelId,
          'user_id': _userId,
          'timestamp': 1700000000,
          // no guild_id
        }),
        dispatch,
      );

      expect(args, isNotNull);
      expect(args!.typing.guildId, isNull);
    });
  });

  // ── PRESENCE_UPDATE ────────────────────────────────────────────────────────

  group('PresenceUpdatePacket', () {
    late MockDataStore presenceDs;

    setUp(() async {
      final wss2 = FakeWebsocketOrchestrator();
      presenceDs = await _buildDs(wss2);
    });

    test('packetType is PacketType.presenceUpdate', () {
      final packet = PresenceUpdatePacket(dataStore: presenceDs);
      expect(packet.packetType, equals(PacketType.presenceUpdate));
      expect(packet.packetType.name, equals('PRESENCE_UPDATE'));
    });

    test('dispatches Event.guildPresenceUpdate', () async {
      final packet = PresenceUpdatePacket(dataStore: presenceDs);
      Event? capturedEvent;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        capturedEvent = event;
      }

      await packet.listen(
        _msg('PRESENCE_UPDATE', {
          'guild_id': _guildId,
          'user': {'id': _userId},
          'status': 'online',
          'activities': <dynamic>[],
          'client_status': {'desktop': 'online', 'mobile': null, 'web': null},
        }),
        dispatch,
      );

      expect(capturedEvent, equals(Event.guildPresenceUpdate));
    });

    test(
      'payload is GuildPresenceUpdateArgs with member and presence',
      () async {
        final packet = PresenceUpdatePacket(dataStore: presenceDs);
        GuildPresenceUpdateArgs? args;

        void dispatch<T extends Object>({
          required Event event,
          required T payload,
          bool Function(String?)? constraint,
        }) {
          if (event == Event.guildPresenceUpdate) {
            args = payload as GuildPresenceUpdateArgs;
          }
        }

        await packet.listen(
          _msg('PRESENCE_UPDATE', {
            'guild_id': _guildId,
            'user': {'id': _userId},
            'status': 'online',
            'activities': <dynamic>[],
            'client_status': {'desktop': 'online', 'mobile': null, 'web': null},
          }),
          dispatch,
        );

        expect(args, isNotNull);
        expect(args!.member.id, equals(Snowflake.parse(_userId)));
        expect(args!.presence, isNotNull);
      },
    );
  });
}
