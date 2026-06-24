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
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_soundboard_sound_create_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_soundboard_sound_delete_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_soundboard_sound_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_soundboard_sounds_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/soundboard_sounds_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:test/test.dart';

import '../helpers/fake_logger.dart';
import '../helpers/fake_websocket_orchestrator.dart';

// ── IDs ───────────────────────────────────────────────────────────────────────

const _serverId = '123456789012345678';
const _soundId = '111222333444555666';
const _soundId2 = '222333444555666777';

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
      'guild_id': _serverId,
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
        'guild_id': _serverId,
      },
    );

ShardMessage<dynamic> _buildSoundsUpdateMessage() => ShardMessage(
      type: 'GUILD_SOUNDBOARD_SOUNDS_UPDATE',
      opCode: OpCode.dispatch,
      sequence: 4,
      payload: {
        'guild_id': _serverId,
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
        'guild_id': _serverId,
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
        dataStore: _FakeDataStore(serverPart: _DummyServerPart()),
      );
      expect(packet.packetType, equals(PacketType.guildSoundboardSoundCreate));
      expect(packet.packetType.name, equals('GUILD_SOUNDBOARD_SOUND_CREATE'));
    });

    test('GuildSoundboardSoundUpdatePacket has correct packetType', () {
      final packet = GuildSoundboardSoundUpdatePacket(
        dataStore: _FakeDataStore(serverPart: _DummyServerPart()),
      );
      expect(packet.packetType, equals(PacketType.guildSoundboardSoundUpdate));
      expect(packet.packetType.name, equals('GUILD_SOUNDBOARD_SOUND_UPDATE'));
    });

    test('GuildSoundboardSoundDeletePacket has correct packetType', () {
      final packet = GuildSoundboardSoundDeletePacket(
        dataStore: _FakeDataStore(serverPart: _DummyServerPart()),
      );
      expect(packet.packetType, equals(PacketType.guildSoundboardSoundDelete));
      expect(packet.packetType.name, equals('GUILD_SOUNDBOARD_SOUND_DELETE'));
    });

    test('GuildSoundboardSoundsUpdatePacket has correct packetType', () {
      final packet = GuildSoundboardSoundsUpdatePacket(
        dataStore: _FakeDataStore(serverPart: _DummyServerPart()),
      );
      expect(
          packet.packetType, equals(PacketType.guildSoundboardSoundsUpdate));
      expect(
          packet.packetType.name, equals('GUILD_SOUNDBOARD_SOUNDS_UPDATE'));
    });

    test('SoundboardSoundsPacket has correct packetType', () {
      final packet = SoundboardSoundsPacket(
        dataStore: _FakeDataStore(serverPart: _DummyServerPart()),
      );
      expect(packet.packetType, equals(PacketType.soundboardSounds));
      expect(packet.packetType.name, equals('SOUNDBOARD_SOUNDS'));
    });
  });

  // ── GUILD_SOUNDBOARD_SOUND_CREATE ─────────────────────────────────────────

  group('GuildSoundboardSoundCreatePacket', () {
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

    test('dispatches Event.serverSoundboardSoundCreate', () async {
      final packet = GuildSoundboardSoundCreatePacket(dataStore: ds);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_buildCreateMessage(), dispatch);
      expect(capturedEvent, equals(Event.serverSoundboardSoundCreate));
    });

    test('payload carries server and correctly parsed SoundboardSound',
        () async {
      final packet = GuildSoundboardSoundCreatePacket(dataStore: ds);
      ServerSoundboardSoundCreateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.serverSoundboardSoundCreate) {
          args = payload as ServerSoundboardSoundCreateArgs;
        }
      }

      await packet.listen(_buildCreateMessage(), dispatch);

      expect(args, isNotNull);
      expect(args!.server.id, equals(Snowflake.parse(_serverId)));
      expect(args!.server.name, equals('Test Server'));
      final sound = args!.sound;
      expect(sound.soundId, equals(Snowflake.parse(_soundId)));
      expect(sound.name, equals('Created Sound'));
      expect(sound.guildId, equals(Snowflake.parse(_serverId)));
    });
  });

  // ── GUILD_SOUNDBOARD_SOUND_UPDATE ─────────────────────────────────────────

  group('GuildSoundboardSoundUpdatePacket', () {
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

    test('dispatches Event.serverSoundboardSoundUpdate', () async {
      final packet = GuildSoundboardSoundUpdatePacket(dataStore: ds);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_buildUpdateMessage(), dispatch);
      expect(capturedEvent, equals(Event.serverSoundboardSoundUpdate));
    });

    test('payload carries server and correctly parsed SoundboardSound',
        () async {
      final packet = GuildSoundboardSoundUpdatePacket(dataStore: ds);
      ServerSoundboardSoundUpdateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.serverSoundboardSoundUpdate) {
          args = payload as ServerSoundboardSoundUpdateArgs;
        }
      }

      await packet.listen(_buildUpdateMessage(), dispatch);

      expect(args, isNotNull);
      expect(args!.server.id, equals(Snowflake.parse(_serverId)));
      final sound = args!.sound;
      expect(sound.soundId, equals(Snowflake.parse(_soundId)));
      expect(sound.name, equals('Updated Sound'));
    });
  });

  // ── GUILD_SOUNDBOARD_SOUND_DELETE ─────────────────────────────────────────

  group('GuildSoundboardSoundDeletePacket', () {
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

    test('dispatches Event.serverSoundboardSoundDelete', () async {
      final packet = GuildSoundboardSoundDeletePacket(dataStore: ds);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_buildDeleteMessage(), dispatch);
      expect(capturedEvent, equals(Event.serverSoundboardSoundDelete));
    });

    test('payload carries server and soundId (not a full sound)', () async {
      final packet = GuildSoundboardSoundDeletePacket(dataStore: ds);
      ServerSoundboardSoundDeleteArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.serverSoundboardSoundDelete) {
          args = payload as ServerSoundboardSoundDeleteArgs;
        }
      }

      await packet.listen(_buildDeleteMessage(), dispatch);

      expect(args, isNotNull);
      expect(args!.server.id, equals(Snowflake.parse(_serverId)));
      expect(args!.soundId, equals(Snowflake.parse(_soundId)));
    });
  });

  // ── GUILD_SOUNDBOARD_SOUNDS_UPDATE ────────────────────────────────────────

  group('GuildSoundboardSoundsUpdatePacket', () {
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

    test('dispatches Event.serverSoundboardSoundsUpdate', () async {
      final packet = GuildSoundboardSoundsUpdatePacket(dataStore: ds);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_buildSoundsUpdateMessage(), dispatch);
      expect(capturedEvent, equals(Event.serverSoundboardSoundsUpdate));
    });

    test('payload carries server and a list of SoundboardSounds', () async {
      final packet = GuildSoundboardSoundsUpdatePacket(dataStore: ds);
      ServerSoundboardSoundsUpdateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.serverSoundboardSoundsUpdate) {
          args = payload as ServerSoundboardSoundsUpdateArgs;
        }
      }

      await packet.listen(_buildSoundsUpdateMessage(), dispatch);

      expect(args, isNotNull);
      expect(args!.server.id, equals(Snowflake.parse(_serverId)));
      expect(args!.sounds, hasLength(2));
      expect(args!.sounds[0].name, equals('Alpha'));
      expect(args!.sounds[1].name, equals('Beta'));
    });
  });

  // ── SOUNDBOARD_SOUNDS ─────────────────────────────────────────────────────

  group('SoundboardSoundsPacket', () {
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

    test('dispatches Event.serverSoundboardSounds', () async {
      final packet = SoundboardSoundsPacket(dataStore: ds);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_buildSoundboardSoundsMessage(), dispatch);
      expect(capturedEvent, equals(Event.serverSoundboardSounds));
    });

    test('payload carries server and a list of SoundboardSounds', () async {
      final packet = SoundboardSoundsPacket(dataStore: ds);
      ServerSoundboardSoundsArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.serverSoundboardSounds) {
          args = payload as ServerSoundboardSoundsArgs;
        }
      }

      await packet.listen(_buildSoundboardSoundsMessage(), dispatch);

      expect(args, isNotNull);
      expect(args!.server.id, equals(Snowflake.parse(_serverId)));
      expect(args!.sounds, hasLength(1));
      expect(args!.sounds[0].name, equals('Gamma'));
      expect(args!.sounds[0].soundId, equals(Snowflake.parse(_soundId)));
    });
  });
}
