import 'package:mineral/api.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/stage_instance_create_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/stage_instance_delete_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/stage_instance_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../helpers/fake_websocket_orchestrator.dart';
import '../helpers/mocks.dart';
import 'helpers/packet_test_helpers.dart';

// ── IDs ───────────────────────────────────────────────────────────────────────

const _guildId = '123456789012345678';
const _channelId = '111222333444555666';
const _instanceId = '999888777666555444';

// ── Stage instance payload ────────────────────────────────────────────────────

Map<String, dynamic> _stageInstancePayload({
  String topic = 'Test Stage',
  int privacyLevel = 2,
}) =>
    {
      'id': _instanceId,
      'guild_id': _guildId,
      'channel_id': _channelId,
      'topic': topic,
      'privacy_level': privacyLevel,
    };

ShardMessage<dynamic> _buildCreateMessage() => ShardMessage(
      type: 'STAGE_INSTANCE_CREATE',
      opCode: OpCode.dispatch,
      sequence: 1,
      payload: _stageInstancePayload(),
    );

ShardMessage<dynamic> _buildUpdateMessage() => ShardMessage(
      type: 'STAGE_INSTANCE_UPDATE',
      opCode: OpCode.dispatch,
      sequence: 2,
      payload: _stageInstancePayload(topic: 'Updated Topic'),
    );

ShardMessage<dynamic> _buildDeleteMessage() => ShardMessage(
      type: 'STAGE_INSTANCE_DELETE',
      opCode: OpCode.dispatch,
      sequence: 3,
      payload: _stageInstancePayload(),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── PacketType identity ────────────────────────────────────────────────────

  group('PacketType identity', () {
    test('StageInstanceCreatePacket has correct packetType', () {
      final packet = StageInstanceCreatePacket(
        dataStore: buildMockDs(),
      );
      expect(packet.packetType, equals(PacketType.stageInstanceCreate));
      expect(packet.packetType.name, equals('STAGE_INSTANCE_CREATE'));
    });

    test('StageInstanceUpdatePacket has correct packetType', () {
      final packet = StageInstanceUpdatePacket(
        dataStore: buildMockDs(),
      );
      expect(packet.packetType, equals(PacketType.stageInstanceUpdate));
      expect(packet.packetType.name, equals('STAGE_INSTANCE_UPDATE'));
    });

    test('StageInstanceDeletePacket has correct packetType', () {
      final packet = StageInstanceDeletePacket(
        dataStore: buildMockDs(),
      );
      expect(packet.packetType, equals(PacketType.stageInstanceDelete));
      expect(packet.packetType.name, equals('STAGE_INSTANCE_DELETE'));
    });
  });

  // ── STAGE_INSTANCE_CREATE ──────────────────────────────────────────────────

  group('StageInstanceCreatePacket', () {
    late MockDataStore ds;

    setUp(() {
      ds = MockDataStore();
      final guild = buildMinimalGuild(_guildId, buildCtx(dataStore: ds, wss: FakeWebsocketOrchestrator()));
      when(() => ds.guild).thenReturn(FakeGuildPart(guild));
    });

    test('dispatches Event.guildStageInstanceCreate', () async {
      final packet = StageInstanceCreatePacket(dataStore: ds);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_buildCreateMessage(), dispatch);
      expect(capturedEvent, equals(Event.guildStageInstanceCreate));
    });

    test('payload carries guild and correctly parsed StageInstance', () async {
      final packet = StageInstanceCreatePacket(dataStore: ds);
      GuildStageInstanceCreateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildStageInstanceCreate) {
          args = payload as GuildStageInstanceCreateArgs;
        }
      }

      await packet.listen(_buildCreateMessage(), dispatch);

      expect(args, isNotNull);
      expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
      expect(args!.guild.name, equals('Test Guild'));
      final instance = args!.instance;
      expect(instance.id, equals(Snowflake.parse(_instanceId)));
      expect(instance.guildId, equals(Snowflake.parse(_guildId)));
      expect(instance.channelId, equals(Snowflake.parse(_channelId)));
      expect(instance.topic, equals('Test Stage'));
      expect(instance.privacyLevel, equals(StagePrivacyLevel.guildOnly));
    });
  });

  // ── STAGE_INSTANCE_UPDATE ──────────────────────────────────────────────────

  group('StageInstanceUpdatePacket', () {
    late MockDataStore ds;

    setUp(() {
      ds = MockDataStore();
      final guild = buildMinimalGuild(_guildId, buildCtx(dataStore: ds, wss: FakeWebsocketOrchestrator()));
      when(() => ds.guild).thenReturn(FakeGuildPart(guild));
    });

    test('dispatches Event.guildStageInstanceUpdate', () async {
      final packet = StageInstanceUpdatePacket(dataStore: ds);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_buildUpdateMessage(), dispatch);
      expect(capturedEvent, equals(Event.guildStageInstanceUpdate));
    });

    test('payload carries guild and correctly parsed StageInstance', () async {
      final packet = StageInstanceUpdatePacket(dataStore: ds);
      GuildStageInstanceUpdateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildStageInstanceUpdate) {
          args = payload as GuildStageInstanceUpdateArgs;
        }
      }

      await packet.listen(_buildUpdateMessage(), dispatch);

      expect(args, isNotNull);
      expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
      final instance = args!.instance;
      expect(instance.id, equals(Snowflake.parse(_instanceId)));
      expect(instance.topic, equals('Updated Topic'));
    });
  });

  // ── STAGE_INSTANCE_DELETE ──────────────────────────────────────────────────

  group('StageInstanceDeletePacket', () {
    late MockDataStore ds;

    setUp(() {
      ds = MockDataStore();
      final guild = buildMinimalGuild(_guildId, buildCtx(dataStore: ds, wss: FakeWebsocketOrchestrator()));
      when(() => ds.guild).thenReturn(FakeGuildPart(guild));
    });

    test('dispatches Event.guildStageInstanceDelete', () async {
      final packet = StageInstanceDeletePacket(dataStore: ds);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_buildDeleteMessage(), dispatch);
      expect(capturedEvent, equals(Event.guildStageInstanceDelete));
    });

    test('payload carries guild and correctly parsed StageInstance', () async {
      final packet = StageInstanceDeletePacket(dataStore: ds);
      GuildStageInstanceDeleteArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildStageInstanceDelete) {
          args = payload as GuildStageInstanceDeleteArgs;
        }
      }

      await packet.listen(_buildDeleteMessage(), dispatch);

      expect(args, isNotNull);
      expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
      final instance = args!.instance;
      expect(instance.id, equals(Snowflake.parse(_instanceId)));
      expect(instance.topic, equals('Test Stage'));
    });
  });
}
