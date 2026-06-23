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
import 'package:mineral/src/infrastructure/internals/packets/listeners/stage_instance_create_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/stage_instance_delete_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/stage_instance_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:test/test.dart';

import '../helpers/fake_logger.dart';
import '../helpers/fake_websocket_orchestrator.dart';

// ── IDs ───────────────────────────────────────────────────────────────────────

const _serverId = '123456789012345678';
const _channelId = '111222333444555666';
const _instanceId = '999888777666555444';

// ── Minimal DataStoreContract stubs ──────────────────────────────────────────

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

final class _FakeServerPart implements ServerPartContract {
  final Server _server;
  _FakeServerPart(this._server);

  @override
  Future<Server> get(Object id, bool force) async => _server;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

final class _DummyServerPart implements ServerPartContract {
  @override
  Future<Server> get(Object id, bool force) => throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

final class _NullDataStore implements DataStoreContract {
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

// ── Stage instance payload ────────────────────────────────────────────────────

Map<String, dynamic> _stageInstancePayload({
  String topic = 'Test Stage',
  int privacyLevel = 2,
}) =>
    {
      'id': _instanceId,
      'guild_id': _serverId,
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
        dataStore: _FakeDataStore(serverPart: _DummyServerPart()),
      );
      expect(packet.packetType, equals(PacketType.stageInstanceCreate));
      expect(packet.packetType.name, equals('STAGE_INSTANCE_CREATE'));
    });

    test('StageInstanceUpdatePacket has correct packetType', () {
      final packet = StageInstanceUpdatePacket(
        dataStore: _FakeDataStore(serverPart: _DummyServerPart()),
      );
      expect(packet.packetType, equals(PacketType.stageInstanceUpdate));
      expect(packet.packetType.name, equals('STAGE_INSTANCE_UPDATE'));
    });

    test('StageInstanceDeletePacket has correct packetType', () {
      final packet = StageInstanceDeletePacket(
        dataStore: _FakeDataStore(serverPart: _DummyServerPart()),
      );
      expect(packet.packetType, equals(PacketType.stageInstanceDelete));
      expect(packet.packetType.name, equals('STAGE_INSTANCE_DELETE'));
    });
  });

  // ── STAGE_INSTANCE_CREATE ──────────────────────────────────────────────────

  group('StageInstanceCreatePacket', () {
    late _FakeDataStore ds;

    setUp(() {
      final ctx = EntityContext(
        datastore: _NullDataStore(),
        wss: FakeWebsocketOrchestrator(),
        logger: FakeLogger(),
        runtimeState: RuntimeState(),
      );
      final server = _buildServer(ctx);
      ds = _FakeDataStore(serverPart: _FakeServerPart(server));
    });

    test('dispatches Event.serverStageInstanceCreate', () async {
      final packet = StageInstanceCreatePacket(dataStore: ds);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_buildCreateMessage(), dispatch);
      expect(capturedEvent, equals(Event.serverStageInstanceCreate));
    });

    test('payload carries server and correctly parsed StageInstance', () async {
      final packet = StageInstanceCreatePacket(dataStore: ds);
      ServerStageInstanceCreateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.serverStageInstanceCreate) {
          args = payload as ServerStageInstanceCreateArgs;
        }
      }

      await packet.listen(_buildCreateMessage(), dispatch);

      expect(args, isNotNull);
      expect(args!.server.id, equals(Snowflake.parse(_serverId)));
      expect(args!.server.name, equals('Test Server'));
      final instance = args!.instance;
      expect(instance.id, equals(Snowflake.parse(_instanceId)));
      expect(instance.guildId, equals(Snowflake.parse(_serverId)));
      expect(instance.channelId, equals(Snowflake.parse(_channelId)));
      expect(instance.topic, equals('Test Stage'));
      expect(instance.privacyLevel, equals(StagePrivacyLevel.guildOnly));
    });
  });

  // ── STAGE_INSTANCE_UPDATE ──────────────────────────────────────────────────

  group('StageInstanceUpdatePacket', () {
    late _FakeDataStore ds;

    setUp(() {
      final ctx = EntityContext(
        datastore: _NullDataStore(),
        wss: FakeWebsocketOrchestrator(),
        logger: FakeLogger(),
        runtimeState: RuntimeState(),
      );
      final server = _buildServer(ctx);
      ds = _FakeDataStore(serverPart: _FakeServerPart(server));
    });

    test('dispatches Event.serverStageInstanceUpdate', () async {
      final packet = StageInstanceUpdatePacket(dataStore: ds);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_buildUpdateMessage(), dispatch);
      expect(capturedEvent, equals(Event.serverStageInstanceUpdate));
    });

    test('payload carries server and correctly parsed StageInstance', () async {
      final packet = StageInstanceUpdatePacket(dataStore: ds);
      ServerStageInstanceUpdateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.serverStageInstanceUpdate) {
          args = payload as ServerStageInstanceUpdateArgs;
        }
      }

      await packet.listen(_buildUpdateMessage(), dispatch);

      expect(args, isNotNull);
      expect(args!.server.id, equals(Snowflake.parse(_serverId)));
      final instance = args!.instance;
      expect(instance.id, equals(Snowflake.parse(_instanceId)));
      expect(instance.topic, equals('Updated Topic'));
    });
  });

  // ── STAGE_INSTANCE_DELETE ──────────────────────────────────────────────────

  group('StageInstanceDeletePacket', () {
    late _FakeDataStore ds;

    setUp(() {
      final ctx = EntityContext(
        datastore: _NullDataStore(),
        wss: FakeWebsocketOrchestrator(),
        logger: FakeLogger(),
        runtimeState: RuntimeState(),
      );
      final server = _buildServer(ctx);
      ds = _FakeDataStore(serverPart: _FakeServerPart(server));
    });

    test('dispatches Event.serverStageInstanceDelete', () async {
      final packet = StageInstanceDeletePacket(dataStore: ds);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_buildDeleteMessage(), dispatch);
      expect(capturedEvent, equals(Event.serverStageInstanceDelete));
    });

    test('payload carries server and correctly parsed StageInstance', () async {
      final packet = StageInstanceDeletePacket(dataStore: ds);
      ServerStageInstanceDeleteArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.serverStageInstanceDelete) {
          args = payload as ServerStageInstanceDeleteArgs;
        }
      }

      await packet.listen(_buildDeleteMessage(), dispatch);

      expect(args, isNotNull);
      expect(args!.server.id, equals(Snowflake.parse(_serverId)));
      final instance = args!.instance;
      expect(instance.id, equals(Snowflake.parse(_instanceId)));
      expect(instance.topic, equals('Test Stage'));
    });
  });
}
