import 'package:mineral/api.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_integrations_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/integration_create_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/integration_delete_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/integration_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../helpers/fake_websocket_orchestrator.dart';
import '../helpers/mocks.dart';
import 'helpers/packet_test_helpers.dart';

// ── Test IDs ──────────────────────────────────────────────────────────────────

const _guildId = '123456789012345678';
const _integrationId = '111222333444555666';
const _applicationId = '999888777666555444';
const _roleId = '333444555666777888';
const _userId = '444555666777888999';

// ── Shard message factories ───────────────────────────────────────────────────

ShardMessage<dynamic> _buildGuildIntegrationsUpdateMessage() => ShardMessage(
      type: 'GUILD_INTEGRATIONS_UPDATE',
      opCode: OpCode.dispatch,
      sequence: 1,
      payload: {'guild_id': _guildId},
    );

Map<String, dynamic> _integrationPayload({bool withApplicationId = false}) => {
      'id': _integrationId,
      'name': 'Test Integration',
      'type': 'twitch',
      'enabled': true,
      'syncing': false,
      'role_id': _roleId,
      'enable_emoticons': true,
      'expire_behavior': 0,
      'expire_grace_period': 7,
      'user': {'id': _userId, 'username': 'testuser', 'discriminator': '0000'},
      'account': {'id': 'acc-123', 'name': 'TwitchAccount'},
      'synced_at': '2024-01-15T12:00:00.000Z',
      'subscriber_count': 42,
      'revoked': false,
      'application': {
        'id': _applicationId,
        'name': 'TestApp',
        'description': 'A test app',
      },
      'scopes': ['bot', 'applications.commands'],
      'guild_id': _guildId,
      if (withApplicationId) 'application_id': _applicationId,
    };

ShardMessage<dynamic> _buildIntegrationCreateMessage() => ShardMessage(
      type: 'INTEGRATION_CREATE',
      opCode: OpCode.dispatch,
      sequence: 2,
      payload: _integrationPayload(),
    );

ShardMessage<dynamic> _buildIntegrationUpdateMessage() => ShardMessage(
      type: 'INTEGRATION_UPDATE',
      opCode: OpCode.dispatch,
      sequence: 3,
      payload: _integrationPayload(),
    );

ShardMessage<dynamic> _buildIntegrationDeleteMessage(
        {bool withApplicationId = false}) =>
    ShardMessage(
      type: 'INTEGRATION_DELETE',
      opCode: OpCode.dispatch,
      sequence: 4,
      payload: {
        'id': _integrationId,
        'guild_id': _guildId,
        if (withApplicationId) 'application_id': _applicationId,
      },
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── PacketType identity ──────────────────────────────────────────────────

  group('PacketType identity', () {
    test('GuildIntegrationsUpdatePacket has correct packetType', () {
      final packet = GuildIntegrationsUpdatePacket(dataStore: buildMockDs());
      expect(packet.packetType, equals(PacketType.guildIntegrationsUpdate));
      expect(packet.packetType.name, equals('GUILD_INTEGRATIONS_UPDATE'));
    });

    test('IntegrationCreatePacket has correct packetType', () {
      final packet = IntegrationCreatePacket(dataStore: buildMockDs());
      expect(packet.packetType, equals(PacketType.integrationCreate));
      expect(packet.packetType.name, equals('INTEGRATION_CREATE'));
    });

    test('IntegrationUpdatePacket has correct packetType', () {
      final packet = IntegrationUpdatePacket(dataStore: buildMockDs());
      expect(packet.packetType, equals(PacketType.integrationUpdate));
      expect(packet.packetType.name, equals('INTEGRATION_UPDATE'));
    });

    test('IntegrationDeletePacket has correct packetType', () {
      final packet = IntegrationDeletePacket(dataStore: buildMockDs());
      expect(packet.packetType, equals(PacketType.integrationDelete));
      expect(packet.packetType.name, equals('INTEGRATION_DELETE'));
    });
  });

  // ── GUILD_INTEGRATIONS_UPDATE ────────────────────────────────────────────

  group('GuildIntegrationsUpdatePacket', () {
    late MockDataStore ds;

    setUp(() {
      ds = MockDataStore();
      final guild = buildMinimalGuild(_guildId, buildCtx(dataStore: ds, wss: FakeWebsocketOrchestrator()));
      when(() => ds.guild).thenReturn(FakeGuildPart(guild));
    });

    test('dispatches Event.guildIntegrationsUpdate', () async {
      final packet = GuildIntegrationsUpdatePacket(dataStore: ds);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_buildGuildIntegrationsUpdateMessage(), dispatch);

      expect(capturedEvent, equals(Event.guildIntegrationsUpdate));
    });

    test('payload carries the resolved guild', () async {
      final packet = GuildIntegrationsUpdatePacket(dataStore: ds);
      GuildIntegrationsUpdateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildIntegrationsUpdate) {
          args = payload as GuildIntegrationsUpdateArgs;
        }
      }

      await packet.listen(_buildGuildIntegrationsUpdateMessage(), dispatch);

      expect(args, isNotNull);
      expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
      expect(args!.guild.name, equals('Test Guild'));
    });
  });

  // ── INTEGRATION_CREATE ───────────────────────────────────────────────────

  group('IntegrationCreatePacket', () {
    late MockDataStore ds;

    setUp(() {
      ds = MockDataStore();
      final guild = buildMinimalGuild(_guildId, buildCtx(dataStore: ds, wss: FakeWebsocketOrchestrator()));
      when(() => ds.guild).thenReturn(FakeGuildPart(guild));
    });

    test('dispatches Event.guildIntegrationCreate', () async {
      final packet = IntegrationCreatePacket(dataStore: ds);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_buildIntegrationCreateMessage(), dispatch);

      expect(capturedEvent, equals(Event.guildIntegrationCreate));
    });

    test('payload carries guild and correctly parsed integration', () async {
      final packet = IntegrationCreatePacket(dataStore: ds);
      GuildIntegrationCreateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildIntegrationCreate) {
          args = payload as GuildIntegrationCreateArgs;
        }
      }

      await packet.listen(_buildIntegrationCreateMessage(), dispatch);

      expect(args, isNotNull);
      expect(args!.guild.id, equals(Snowflake.parse(_guildId)));

      final i = args!.integration;
      expect(i.id, equals(Snowflake.parse(_integrationId)));
      expect(i.name, equals('Test Integration'));
      expect(i.type, equals('twitch'));
      expect(i.enabled, isTrue);
      expect(i.account.id, equals('acc-123'));
      expect(i.account.name, equals('TwitchAccount'));
      expect(i.expireBehavior, equals(IntegrationExpireBehavior.removeRole));
      expect(i.userId, equals(Snowflake.parse(_userId)));
      expect(i.application?.id, equals(Snowflake.parse(_applicationId)));
      expect(i.application?.name, equals('TestApp'));
      expect(i.scopes, containsAll(['bot', 'applications.commands']));
    });
  });

  // ── INTEGRATION_UPDATE ───────────────────────────────────────────────────

  group('IntegrationUpdatePacket', () {
    late MockDataStore ds;

    setUp(() {
      ds = MockDataStore();
      final guild = buildMinimalGuild(_guildId, buildCtx(dataStore: ds, wss: FakeWebsocketOrchestrator()));
      when(() => ds.guild).thenReturn(FakeGuildPart(guild));
    });

    test('dispatches Event.guildIntegrationUpdate', () async {
      final packet = IntegrationUpdatePacket(dataStore: ds);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_buildIntegrationUpdateMessage(), dispatch);

      expect(capturedEvent, equals(Event.guildIntegrationUpdate));
    });

    test('payload carries guild and correctly parsed integration', () async {
      final packet = IntegrationUpdatePacket(dataStore: ds);
      GuildIntegrationUpdateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildIntegrationUpdate) {
          args = payload as GuildIntegrationUpdateArgs;
        }
      }

      await packet.listen(_buildIntegrationUpdateMessage(), dispatch);

      expect(args, isNotNull);
      expect(args!.guild.id, equals(Snowflake.parse(_guildId)));

      final i = args!.integration;
      expect(i.id, equals(Snowflake.parse(_integrationId)));
      expect(i.name, equals('Test Integration'));
      expect(i.type, equals('twitch'));
      expect(i.enabled, isTrue);
      expect(i.account.id, equals('acc-123'));
      expect(i.account.name, equals('TwitchAccount'));
      expect(i.expireBehavior, equals(IntegrationExpireBehavior.removeRole));
    });
  });

  // ── INTEGRATION_DELETE ───────────────────────────────────────────────────

  group('IntegrationDeletePacket', () {
    late MockDataStore ds;

    setUp(() {
      ds = MockDataStore();
      final guild = buildMinimalGuild(_guildId, buildCtx(dataStore: ds, wss: FakeWebsocketOrchestrator()));
      when(() => ds.guild).thenReturn(FakeGuildPart(guild));
    });

    test('dispatches Event.guildIntegrationDelete', () async {
      final packet = IntegrationDeletePacket(dataStore: ds);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_buildIntegrationDeleteMessage(), dispatch);

      expect(capturedEvent, equals(Event.guildIntegrationDelete));
    });

    test('payload carries guild and integrationId, applicationId is null',
        () async {
      final packet = IntegrationDeletePacket(dataStore: ds);
      GuildIntegrationDeleteArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildIntegrationDelete) {
          args = payload as GuildIntegrationDeleteArgs;
        }
      }

      await packet.listen(_buildIntegrationDeleteMessage(), dispatch);

      expect(args, isNotNull);
      expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
      expect(args!.integrationId, equals(Snowflake.parse(_integrationId)));
      expect(args!.applicationId, isNull);
    });

    test('payload carries applicationId when present', () async {
      final packet = IntegrationDeletePacket(dataStore: ds);
      GuildIntegrationDeleteArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildIntegrationDelete) {
          args = payload as GuildIntegrationDeleteArgs;
        }
      }

      await packet.listen(
          _buildIntegrationDeleteMessage(withApplicationId: true), dispatch);

      expect(args, isNotNull);
      expect(args!.integrationId, equals(Snowflake.parse(_integrationId)));
      expect(args!.applicationId, equals(Snowflake.parse(_applicationId)));
    });
  });
}
