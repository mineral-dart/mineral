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
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_integrations_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/integration_create_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/integration_delete_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/integration_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:test/test.dart';

import '../helpers/fake_logger.dart';
import '../helpers/fake_websocket_orchestrator.dart';

// ── Test IDs ──────────────────────────────────────────────────────────────────

const _serverId = '123456789012345678';
const _integrationId = '111222333444555666';
const _applicationId = '999888777666555444';
const _roleId = '333444555666777888';
const _userId = '444555666777888999';

// ── Stub DataStore ────────────────────────────────────────────────────────────

final class _FakeDataStore implements DataStoreContract {
  final ServerPartContract _serverPart;

  _FakeDataStore({required ServerPartContract serverPart})
      : _serverPart = serverPart;

  @override
  ServerPartContract get server => _serverPart;

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
  ThreadPart get thread => throw UnimplementedError();
  @override
  InvitePartContract get invite => throw UnimplementedError();
  @override
  WebhookPartContract get webhook => throw UnimplementedError();
  @override
  GuildScheduledEventPartContract get scheduledEvent =>
      throw UnimplementedError();
  @override
  StageInstancePartContract get stageInstance => throw UnimplementedError();
  @override
  RequestBucket get requestBucket => throw UnimplementedError();
  @override
  HttpClientContract get client => throw UnimplementedError();
}

// ── Deferred DataStore (for breaking circular dep in EntityContext setup) ─────

final class _DeferredDataStore implements DataStoreContract {
  final DataStoreContract Function() _resolve;

  _DeferredDataStore(this._resolve);

  @override
  ServerPartContract get server => _resolve().server;

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
  ThreadPart get thread => throw UnimplementedError();
  @override
  InvitePartContract get invite => throw UnimplementedError();
  @override
  WebhookPartContract get webhook => throw UnimplementedError();
  @override
  GuildScheduledEventPartContract get scheduledEvent =>
      throw UnimplementedError();
  @override
  StageInstancePartContract get stageInstance => throw UnimplementedError();
  @override
  RequestBucket get requestBucket => throw UnimplementedError();
  @override
  HttpClientContract get client => throw UnimplementedError();
}

// ── Fake server part ──────────────────────────────────────────────────────────

final class _FakeServerPart implements ServerPartContract {
  final Server _server;

  _FakeServerPart(this._server);

  @override
  Future<Server> get(Object id, bool force) async => _server;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

// ── Domain object builder ─────────────────────────────────────────────────────

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

// ── Shard message factories ───────────────────────────────────────────────────

ShardMessage<dynamic> _buildGuildIntegrationsUpdateMessage() => ShardMessage(
      type: 'GUILD_INTEGRATIONS_UPDATE',
      opCode: OpCode.dispatch,
      sequence: 1,
      payload: {'guild_id': _serverId},
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
      'guild_id': _serverId,
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
        'guild_id': _serverId,
        if (withApplicationId) 'application_id': _applicationId,
      },
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── PacketType identity ──────────────────────────────────────────────────

  group('PacketType identity', () {
    test('GuildIntegrationsUpdatePacket has correct packetType', () {
      final packet = GuildIntegrationsUpdatePacket(
          dataStore: _FakeDataStore(serverPart: _DummyServerPart()));
      expect(packet.packetType, equals(PacketType.guildIntegrationsUpdate));
      expect(packet.packetType.name, equals('GUILD_INTEGRATIONS_UPDATE'));
    });

    test('IntegrationCreatePacket has correct packetType', () {
      final packet = IntegrationCreatePacket(
          dataStore: _FakeDataStore(serverPart: _DummyServerPart()));
      expect(packet.packetType, equals(PacketType.integrationCreate));
      expect(packet.packetType.name, equals('INTEGRATION_CREATE'));
    });

    test('IntegrationUpdatePacket has correct packetType', () {
      final packet = IntegrationUpdatePacket(
          dataStore: _FakeDataStore(serverPart: _DummyServerPart()));
      expect(packet.packetType, equals(PacketType.integrationUpdate));
      expect(packet.packetType.name, equals('INTEGRATION_UPDATE'));
    });

    test('IntegrationDeletePacket has correct packetType', () {
      final packet = IntegrationDeletePacket(
          dataStore: _FakeDataStore(serverPart: _DummyServerPart()));
      expect(packet.packetType, equals(PacketType.integrationDelete));
      expect(packet.packetType.name, equals('INTEGRATION_DELETE'));
    });
  });

  // ── GUILD_INTEGRATIONS_UPDATE ────────────────────────────────────────────

  group('GuildIntegrationsUpdatePacket', () {
    late _FakeDataStore ds;

    setUp(() {
      final ctx = EntityContext(
        datastore: _DeferredDataStore(() => ds),
        wss: FakeWebsocketOrchestrator(),
        logger: FakeLogger(),
        runtimeState: RuntimeState(),
      );
      final server = _buildServer(ctx);
      ds = _FakeDataStore(serverPart: _FakeServerPart(server));
    });

    test('dispatches Event.serverIntegrationsUpdate', () async {
      final packet = GuildIntegrationsUpdatePacket(dataStore: ds);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_buildGuildIntegrationsUpdateMessage(), dispatch);

      expect(capturedEvent, equals(Event.serverIntegrationsUpdate));
    });

    test('payload carries the resolved server', () async {
      final packet = GuildIntegrationsUpdatePacket(dataStore: ds);
      ServerIntegrationsUpdateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.serverIntegrationsUpdate) {
          args = payload as ServerIntegrationsUpdateArgs;
        }
      }

      await packet.listen(_buildGuildIntegrationsUpdateMessage(), dispatch);

      expect(args, isNotNull);
      expect(args!.server.id, equals(Snowflake.parse(_serverId)));
      expect(args!.server.name, equals('Test Server'));
    });
  });

  // ── INTEGRATION_CREATE ───────────────────────────────────────────────────

  group('IntegrationCreatePacket', () {
    late _FakeDataStore ds;

    setUp(() {
      final ctx = EntityContext(
        datastore: _DeferredDataStore(() => ds),
        wss: FakeWebsocketOrchestrator(),
        logger: FakeLogger(),
        runtimeState: RuntimeState(),
      );
      final server = _buildServer(ctx);
      ds = _FakeDataStore(serverPart: _FakeServerPart(server));
    });

    test('dispatches Event.serverIntegrationCreate', () async {
      final packet = IntegrationCreatePacket(dataStore: ds);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_buildIntegrationCreateMessage(), dispatch);

      expect(capturedEvent, equals(Event.serverIntegrationCreate));
    });

    test('payload carries server and correctly parsed integration', () async {
      final packet = IntegrationCreatePacket(dataStore: ds);
      ServerIntegrationCreateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.serverIntegrationCreate) {
          args = payload as ServerIntegrationCreateArgs;
        }
      }

      await packet.listen(_buildIntegrationCreateMessage(), dispatch);

      expect(args, isNotNull);
      expect(args!.server.id, equals(Snowflake.parse(_serverId)));

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
    late _FakeDataStore ds;

    setUp(() {
      final ctx = EntityContext(
        datastore: _DeferredDataStore(() => ds),
        wss: FakeWebsocketOrchestrator(),
        logger: FakeLogger(),
        runtimeState: RuntimeState(),
      );
      final server = _buildServer(ctx);
      ds = _FakeDataStore(serverPart: _FakeServerPart(server));
    });

    test('dispatches Event.serverIntegrationUpdate', () async {
      final packet = IntegrationUpdatePacket(dataStore: ds);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_buildIntegrationUpdateMessage(), dispatch);

      expect(capturedEvent, equals(Event.serverIntegrationUpdate));
    });

    test('payload carries server and correctly parsed integration', () async {
      final packet = IntegrationUpdatePacket(dataStore: ds);
      ServerIntegrationUpdateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.serverIntegrationUpdate) {
          args = payload as ServerIntegrationUpdateArgs;
        }
      }

      await packet.listen(_buildIntegrationUpdateMessage(), dispatch);

      expect(args, isNotNull);
      expect(args!.server.id, equals(Snowflake.parse(_serverId)));

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
    late _FakeDataStore ds;

    setUp(() {
      final ctx = EntityContext(
        datastore: _DeferredDataStore(() => ds),
        wss: FakeWebsocketOrchestrator(),
        logger: FakeLogger(),
        runtimeState: RuntimeState(),
      );
      final server = _buildServer(ctx);
      ds = _FakeDataStore(serverPart: _FakeServerPart(server));
    });

    test('dispatches Event.serverIntegrationDelete', () async {
      final packet = IntegrationDeletePacket(dataStore: ds);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_buildIntegrationDeleteMessage(), dispatch);

      expect(capturedEvent, equals(Event.serverIntegrationDelete));
    });

    test('payload carries server and integrationId, applicationId is null',
        () async {
      final packet = IntegrationDeletePacket(dataStore: ds);
      ServerIntegrationDeleteArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.serverIntegrationDelete) {
          args = payload as ServerIntegrationDeleteArgs;
        }
      }

      await packet.listen(_buildIntegrationDeleteMessage(), dispatch);

      expect(args, isNotNull);
      expect(args!.server.id, equals(Snowflake.parse(_serverId)));
      expect(args!.integrationId, equals(Snowflake.parse(_integrationId)));
      expect(args!.applicationId, isNull);
    });

    test('payload carries applicationId when present', () async {
      final packet = IntegrationDeletePacket(dataStore: ds);
      ServerIntegrationDeleteArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.serverIntegrationDelete) {
          args = payload as ServerIntegrationDeleteArgs;
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

// ── Dummy server part (for packetType identity tests that don't dispatch) ─────

final class _DummyServerPart implements ServerPartContract {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());

  @override
  Future<Server> get(Object id, bool force) => throw UnimplementedError();
}
