import 'package:mineral/api.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_soundboard_sound_create_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_soundboard_sound_delete_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_soundboard_sound_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_soundboard_sounds_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/soundboard_sounds_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../helpers/fake_websocket_orchestrator.dart';
import '../helpers/mocks.dart';
import 'helpers/packet_test_helpers.dart';

// ── IDs ───────────────────────────────────────────────────────────────────────

const _guildId = '123456789012345678';
const _soundId = '111222333444555666';
const _soundId2 = '222333444555666777';

// ── Payload builders ──────────────────────────────────────────────────────────

Map<String, dynamic> _soundPayload({
  String? soundId,
  String name = 'Bloop',
  double volume = 1.0,
  bool available = true,
}) =>
    {
      'sound_id': soundId ?? _soundId,
      'name': name,
      'volume': volume,
      'available': available,
      'guild_id': _guildId,
    };

ShardMessage<dynamic> _buildCreateMessage() => ShardMessage(
      type: 'GUILD_SOUNDBOARD_SOUND_CREATE',
      opCode: OpCode.dispatch,
      sequence: 1,
      payload: _soundPayload(name: 'Created Sound'),
    );

ShardMessage<dynamic> _buildUpdateMessage() => ShardMessage(
      type: 'GUILD_SOUNDBOARD_SOUND_UPDATE',
      opCode: OpCode.dispatch,
      sequence: 2,
      payload: _soundPayload(name: 'Updated Sound'),
    );

ShardMessage<dynamic> _buildDeleteMessage() => ShardMessage(
      type: 'GUILD_SOUNDBOARD_SOUND_DELETE',
      opCode: OpCode.dispatch,
      sequence: 3,
      payload: {
        'sound_id': _soundId,
        'guild_id': _guildId,
      },
    );

ShardMessage<dynamic> _buildSoundsUpdateMessage() => ShardMessage(
      type: 'GUILD_SOUNDBOARD_SOUNDS_UPDATE',
      opCode: OpCode.dispatch,
      sequence: 4,
      payload: {
        'guild_id': _guildId,
        'soundboard_sounds': [
          _soundPayload(soundId: _soundId, name: 'Alpha'),
          _soundPayload(soundId: _soundId2, name: 'Beta'),
        ],
      },
    );

ShardMessage<dynamic> _buildSoundboardSoundsMessage() => ShardMessage(
      type: 'SOUNDBOARD_SOUNDS',
      opCode: OpCode.dispatch,
      sequence: 5,
      payload: {
        'guild_id': _guildId,
        'soundboard_sounds': [
          _soundPayload(soundId: _soundId, name: 'Gamma'),
        ],
      },
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── PacketType identity ────────────────────────────────────────────────────

  group('PacketType identity', () {
    test('GuildSoundboardSoundCreatePacket has correct packetType', () {
      final packet = GuildSoundboardSoundCreatePacket(
        dataStore: buildMockDs(),
      );
      expect(packet.packetType, equals(PacketType.guildSoundboardSoundCreate));
      expect(packet.packetType.name, equals('GUILD_SOUNDBOARD_SOUND_CREATE'));
    });

    test('GuildSoundboardSoundUpdatePacket has correct packetType', () {
      final packet = GuildSoundboardSoundUpdatePacket(
        dataStore: buildMockDs(),
      );
      expect(packet.packetType, equals(PacketType.guildSoundboardSoundUpdate));
      expect(packet.packetType.name, equals('GUILD_SOUNDBOARD_SOUND_UPDATE'));
    });

    test('GuildSoundboardSoundDeletePacket has correct packetType', () {
      final packet = GuildSoundboardSoundDeletePacket(
        dataStore: buildMockDs(),
      );
      expect(packet.packetType, equals(PacketType.guildSoundboardSoundDelete));
      expect(packet.packetType.name, equals('GUILD_SOUNDBOARD_SOUND_DELETE'));
    });

    test('GuildSoundboardSoundsUpdatePacket has correct packetType', () {
      final packet = GuildSoundboardSoundsUpdatePacket(
        dataStore: buildMockDs(),
      );
      expect(
          packet.packetType, equals(PacketType.guildSoundboardSoundsUpdate));
      expect(
          packet.packetType.name, equals('GUILD_SOUNDBOARD_SOUNDS_UPDATE'));
    });

    test('SoundboardSoundsPacket has correct packetType', () {
      final packet = SoundboardSoundsPacket(
        dataStore: buildMockDs(),
      );
      expect(packet.packetType, equals(PacketType.soundboardSounds));
      expect(packet.packetType.name, equals('SOUNDBOARD_SOUNDS'));
    });
  });

  // ── GUILD_SOUNDBOARD_SOUND_CREATE ─────────────────────────────────────────

  group('GuildSoundboardSoundCreatePacket', () {
    late MockDataStore ds;

    setUp(() {
      ds = MockDataStore();
      final guild = buildMinimalGuild(_guildId, buildCtx(dataStore: ds, wss: FakeWebsocketOrchestrator()));
      when(() => ds.guild).thenReturn(FakeGuildPart(guild));
    });

    test('dispatches Event.guildSoundboardSoundCreate', () async {
      final packet = GuildSoundboardSoundCreatePacket(dataStore: ds);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_buildCreateMessage(), dispatch);
      expect(capturedEvent, equals(Event.guildSoundboardSoundCreate));
    });

    test('payload carries guild and correctly parsed SoundboardSound',
        () async {
      final packet = GuildSoundboardSoundCreatePacket(dataStore: ds);
      GuildSoundboardSoundCreateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildSoundboardSoundCreate) {
          args = payload as GuildSoundboardSoundCreateArgs;
        }
      }

      await packet.listen(_buildCreateMessage(), dispatch);

      expect(args, isNotNull);
      expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
      expect(args!.guild.name, equals('Test Guild'));
      final sound = args!.sound;
      expect(sound.soundId, equals(Snowflake.parse(_soundId)));
      expect(sound.name, equals('Created Sound'));
      expect(sound.guildId, equals(Snowflake.parse(_guildId)));
    });
  });

  // ── GUILD_SOUNDBOARD_SOUND_UPDATE ─────────────────────────────────────────

  group('GuildSoundboardSoundUpdatePacket', () {
    late MockDataStore ds;

    setUp(() {
      ds = MockDataStore();
      final guild = buildMinimalGuild(_guildId, buildCtx(dataStore: ds, wss: FakeWebsocketOrchestrator()));
      when(() => ds.guild).thenReturn(FakeGuildPart(guild));
    });

    test('dispatches Event.guildSoundboardSoundUpdate', () async {
      final packet = GuildSoundboardSoundUpdatePacket(dataStore: ds);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_buildUpdateMessage(), dispatch);
      expect(capturedEvent, equals(Event.guildSoundboardSoundUpdate));
    });

    test('payload carries guild and correctly parsed SoundboardSound',
        () async {
      final packet = GuildSoundboardSoundUpdatePacket(dataStore: ds);
      GuildSoundboardSoundUpdateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildSoundboardSoundUpdate) {
          args = payload as GuildSoundboardSoundUpdateArgs;
        }
      }

      await packet.listen(_buildUpdateMessage(), dispatch);

      expect(args, isNotNull);
      expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
      final sound = args!.sound;
      expect(sound.soundId, equals(Snowflake.parse(_soundId)));
      expect(sound.name, equals('Updated Sound'));
    });
  });

  // ── GUILD_SOUNDBOARD_SOUND_DELETE ─────────────────────────────────────────

  group('GuildSoundboardSoundDeletePacket', () {
    late MockDataStore ds;

    setUp(() {
      ds = MockDataStore();
      final guild = buildMinimalGuild(_guildId, buildCtx(dataStore: ds, wss: FakeWebsocketOrchestrator()));
      when(() => ds.guild).thenReturn(FakeGuildPart(guild));
    });

    test('dispatches Event.guildSoundboardSoundDelete', () async {
      final packet = GuildSoundboardSoundDeletePacket(dataStore: ds);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_buildDeleteMessage(), dispatch);
      expect(capturedEvent, equals(Event.guildSoundboardSoundDelete));
    });

    test('payload carries guild and soundId (not a full sound)', () async {
      final packet = GuildSoundboardSoundDeletePacket(dataStore: ds);
      GuildSoundboardSoundDeleteArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildSoundboardSoundDelete) {
          args = payload as GuildSoundboardSoundDeleteArgs;
        }
      }

      await packet.listen(_buildDeleteMessage(), dispatch);

      expect(args, isNotNull);
      expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
      expect(args!.soundId, equals(Snowflake.parse(_soundId)));
    });
  });

  // ── GUILD_SOUNDBOARD_SOUNDS_UPDATE ────────────────────────────────────────

  group('GuildSoundboardSoundsUpdatePacket', () {
    late MockDataStore ds;

    setUp(() {
      ds = MockDataStore();
      final guild = buildMinimalGuild(_guildId, buildCtx(dataStore: ds, wss: FakeWebsocketOrchestrator()));
      when(() => ds.guild).thenReturn(FakeGuildPart(guild));
    });

    test('dispatches Event.guildSoundboardSoundsUpdate', () async {
      final packet = GuildSoundboardSoundsUpdatePacket(dataStore: ds);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_buildSoundsUpdateMessage(), dispatch);
      expect(capturedEvent, equals(Event.guildSoundboardSoundsUpdate));
    });

    test('payload carries guild and a list of SoundboardSounds', () async {
      final packet = GuildSoundboardSoundsUpdatePacket(dataStore: ds);
      GuildSoundboardSoundsUpdateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildSoundboardSoundsUpdate) {
          args = payload as GuildSoundboardSoundsUpdateArgs;
        }
      }

      await packet.listen(_buildSoundsUpdateMessage(), dispatch);

      expect(args, isNotNull);
      expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
      expect(args!.sounds, hasLength(2));
      expect(args!.sounds[0].name, equals('Alpha'));
      expect(args!.sounds[1].name, equals('Beta'));
    });
  });

  // ── SOUNDBOARD_SOUNDS ─────────────────────────────────────────────────────

  group('SoundboardSoundsPacket', () {
    late MockDataStore ds;

    setUp(() {
      ds = MockDataStore();
      final guild = buildMinimalGuild(_guildId, buildCtx(dataStore: ds, wss: FakeWebsocketOrchestrator()));
      when(() => ds.guild).thenReturn(FakeGuildPart(guild));
    });

    test('dispatches Event.guildSoundboardSounds', () async {
      final packet = SoundboardSoundsPacket(dataStore: ds);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_buildSoundboardSoundsMessage(), dispatch);
      expect(capturedEvent, equals(Event.guildSoundboardSounds));
    });

    test('payload carries guild and a list of SoundboardSounds', () async {
      final packet = SoundboardSoundsPacket(dataStore: ds);
      GuildSoundboardSoundsArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildSoundboardSounds) {
          args = payload as GuildSoundboardSoundsArgs;
        }
      }

      await packet.listen(_buildSoundboardSoundsMessage(), dispatch);

      expect(args, isNotNull);
      expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
      expect(args!.sounds, hasLength(1));
      expect(args!.sounds[0].name, equals('Gamma'));
      expect(args!.sounds[0].soundId, equals(Snowflake.parse(_soundId)));
    });
  });
}
