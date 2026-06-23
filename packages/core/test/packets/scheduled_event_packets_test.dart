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
import 'package:mineral/src/infrastructure/internals/marshaller/cache_key.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializer_bucket.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_scheduled_event_create_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_scheduled_event_delete_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_scheduled_event_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_scheduled_event_user_add_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_scheduled_event_user_remove_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:test/test.dart';

import '../helpers/fake_cache_provider.dart';
import '../helpers/fake_logger.dart';
import '../helpers/fake_websocket_orchestrator.dart';

// ── IDs ───────────────────────────────────────────────────────────────────────

const _serverId = '123456789012345678';
const _eventId = '111222333444555666';
const _userId = '999888777666555444';
const _channelId = '777888999000111222';

// ── Stub DataStore ────────────────────────────────────────────────────────────

final class _FakeDataStore implements DataStoreContract {
  final ServerPartContract _serverPart;
  final UserPartContract _userPart;

  _FakeDataStore({
    required ServerPartContract serverPart,
    UserPartContract? userPart,
  })  : _serverPart = serverPart,
        _userPart = userPart ?? _ThrowUserPart();

  @override
  ServerPartContract get server => _serverPart;

  @override
  UserPartContract get user => _userPart;

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
  HttpClientContract get client => throw UnimplementedError('client');
}

final class _ThrowUserPart implements UserPartContract {
  @override
  Future<User?> get(Object id, bool force) => throw UnimplementedError();
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

final class _FakeUserPart implements UserPartContract {
  final User _user;
  _FakeUserPart(this._user);

  @override
  Future<User?> get(Object id, bool force) async => _user;
}

// ── Fake Marshaller ───────────────────────────────────────────────────────────

final class _FakeMarshaller implements MarshallerContract {
  @override
  final LoggerContract logger = FakeLogger();

  @override
  final CacheProviderContract? cache;

  @override
  final CacheKey cacheKey = CacheKey();

  @override
  late final SerializerBucket serializers;

  _FakeMarshaller({this.cache, EntityContext? entityContext}) {
    serializers = SerializerBucket(
        this,
        entityContext ??
            EntityContext(
              datastore: _NullDataStore(),
              wss: FakeWebsocketOrchestrator(),
              logger: logger,
              runtimeState: RuntimeState(),
            ));
  }
}

final class _NullDataStore implements DataStoreContract {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

// ── Domain object builders ────────────────────────────────────────────────────

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

User _buildUser(EntityContext ctx) => User(
      ctx: ctx,
      id: Snowflake.parse(_userId),
      username: 'testuser',
      discriminator: '0000',
      avatar: null,
      bot: false,
      system: false,
      mfaEnabled: false,
      locale: null,
      verified: false,
      email: null,
      flags: null,
      premiumType: null,
      publicFlags: null,
      assets: UserAssets(
        avatar: null,
        avatarDecoration: null,
        banner: null,
      ),
      createdAt: null,
      presence: null,
    );

// ── Scheduled event payload ───────────────────────────────────────────────────

Map<String, dynamic> _scheduledEventPayload() => {
      'id': _eventId,
      'guild_id': _serverId,
      'channel_id': _channelId,
      'creator_id': null,
      'name': 'Test Event',
      'description': 'A test event',
      'scheduled_start_time': '2026-07-01T10:00:00.000Z',
      'scheduled_end_time': '2026-07-01T12:00:00.000Z',
      'privacy_level': 2,
      'status': 1,
      'entity_type': 2,
      'entity_id': null,
      'entity_metadata': null,
      'user_count': null,
      'image': null,
    };

ShardMessage<dynamic> _buildCreateMessage() => ShardMessage(
      type: 'GUILD_SCHEDULED_EVENT_CREATE',
      opCode: OpCode.dispatch,
      sequence: 1,
      payload: _scheduledEventPayload(),
    );

ShardMessage<dynamic> _buildUpdateMessage() => ShardMessage(
      type: 'GUILD_SCHEDULED_EVENT_UPDATE',
      opCode: OpCode.dispatch,
      sequence: 2,
      payload: _scheduledEventPayload(),
    );

ShardMessage<dynamic> _buildDeleteMessage() => ShardMessage(
      type: 'GUILD_SCHEDULED_EVENT_DELETE',
      opCode: OpCode.dispatch,
      sequence: 3,
      payload: _scheduledEventPayload(),
    );

ShardMessage<dynamic> _buildUserAddMessage() => ShardMessage(
      type: 'GUILD_SCHEDULED_EVENT_USER_ADD',
      opCode: OpCode.dispatch,
      sequence: 4,
      payload: {
        'guild_id': _serverId,
        'guild_scheduled_event_id': _eventId,
        'user_id': _userId,
      },
    );

ShardMessage<dynamic> _buildUserRemoveMessage() => ShardMessage(
      type: 'GUILD_SCHEDULED_EVENT_USER_REMOVE',
      opCode: OpCode.dispatch,
      sequence: 5,
      payload: {
        'guild_id': _serverId,
        'guild_scheduled_event_id': _eventId,
        'user_id': _userId,
      },
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── PacketType identity ────────────────────────────────────────────────────

  group('PacketType identity', () {
    test('GuildScheduledEventCreatePacket has correct packetType', () {
      final marshaller = _FakeMarshaller();
      final packet = GuildScheduledEventCreatePacket(
        marshaller: marshaller,
        dataStore: _FakeDataStore(serverPart: _DummyServerPart()),
      );
      expect(packet.packetType, equals(PacketType.guildScheduledEventCreate));
      expect(packet.packetType.name, equals('GUILD_SCHEDULED_EVENT_CREATE'));
    });

    test('GuildScheduledEventUpdatePacket has correct packetType', () {
      final marshaller = _FakeMarshaller();
      final packet = GuildScheduledEventUpdatePacket(
        marshaller: marshaller,
        dataStore: _FakeDataStore(serverPart: _DummyServerPart()),
      );
      expect(packet.packetType, equals(PacketType.guildScheduledEventUpdate));
      expect(packet.packetType.name, equals('GUILD_SCHEDULED_EVENT_UPDATE'));
    });

    test('GuildScheduledEventDeletePacket has correct packetType', () {
      final marshaller = _FakeMarshaller();
      final packet = GuildScheduledEventDeletePacket(
        marshaller: marshaller,
        dataStore: _FakeDataStore(serverPart: _DummyServerPart()),
      );
      expect(packet.packetType, equals(PacketType.guildScheduledEventDelete));
      expect(packet.packetType.name, equals('GUILD_SCHEDULED_EVENT_DELETE'));
    });

    test('GuildScheduledEventUserAddPacket has correct packetType', () {
      final packet = GuildScheduledEventUserAddPacket(
        dataStore: _FakeDataStore(serverPart: _DummyServerPart()),
      );
      expect(packet.packetType, equals(PacketType.guildScheduledEventUserAdd));
      expect(packet.packetType.name, equals('GUILD_SCHEDULED_EVENT_USER_ADD'));
    });

    test('GuildScheduledEventUserRemovePacket has correct packetType', () {
      final packet = GuildScheduledEventUserRemovePacket(
        dataStore: _FakeDataStore(serverPart: _DummyServerPart()),
      );
      expect(
          packet.packetType, equals(PacketType.guildScheduledEventUserRemove));
      expect(packet.packetType.name,
          equals('GUILD_SCHEDULED_EVENT_USER_REMOVE'));
    });
  });

  // ── GUILD_SCHEDULED_EVENT_CREATE ───────────────────────────────────────────

  group('GuildScheduledEventCreatePacket', () {
    late _FakeDataStore ds;
    late _FakeMarshaller marshaller;

    setUp(() {
      final ctx = EntityContext(
        datastore: _NullDataStore(),
        wss: FakeWebsocketOrchestrator(),
        logger: FakeLogger(),
        runtimeState: RuntimeState(),
      );
      // We need a deferred setup since marshaller/server depend on each other
      late _FakeDataStore dsFinal;
      marshaller = _FakeMarshaller(
        entityContext: EntityContext(
          datastore: _LazyDataStore(() => dsFinal),
          wss: FakeWebsocketOrchestrator(),
          logger: FakeLogger(),
          runtimeState: RuntimeState(),
        ),
      );
      final server = _buildServer(ctx);
      dsFinal = _FakeDataStore(serverPart: _FakeServerPart(server));
      ds = dsFinal;
    });

    test('dispatches Event.serverScheduledEventCreate', () async {
      final packet =
          GuildScheduledEventCreatePacket(marshaller: marshaller, dataStore: ds);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_buildCreateMessage(), dispatch);
      expect(capturedEvent, equals(Event.serverScheduledEventCreate));
    });

    test('payload carries server and correctly serialized GuildScheduledEvent',
        () async {
      final packet =
          GuildScheduledEventCreatePacket(marshaller: marshaller, dataStore: ds);
      ServerScheduledEventCreateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.serverScheduledEventCreate) {
          args = payload as ServerScheduledEventCreateArgs;
        }
      }

      await packet.listen(_buildCreateMessage(), dispatch);

      expect(args, isNotNull);
      expect(args!.server.id, equals(Snowflake.parse(_serverId)));
      expect(args!.server.name, equals('Test Server'));
      final e = args!.event;
      expect(e.id, equals(Snowflake.parse(_eventId)));
      expect(e.serverId, equals(Snowflake.parse(_serverId)));
      expect(e.name, equals('Test Event'));
      expect(e.status, equals(GuildScheduledEventStatus.scheduled));
      expect(e.entityType, equals(GuildScheduledEventEntityType.voice));
      expect(e.privacyLevel, equals(GuildScheduledEventPrivacyLevel.guildOnly));
    });
  });

  // ── GUILD_SCHEDULED_EVENT_UPDATE ───────────────────────────────────────────

  group('GuildScheduledEventUpdatePacket', () {
    late _FakeDataStore ds;
    late _FakeMarshaller marshaller;
    late FakeCacheProvider cache;

    setUp(() {
      cache = FakeCacheProvider();

      late _FakeDataStore dsFinal;
      marshaller = _FakeMarshaller(
        cache: cache,
        entityContext: EntityContext(
          datastore: _LazyDataStore(() => dsFinal),
          wss: FakeWebsocketOrchestrator(),
          logger: FakeLogger(),
          runtimeState: RuntimeState(),
        ),
      );

      final ctx = EntityContext(
        datastore: _NullDataStore(),
        wss: FakeWebsocketOrchestrator(),
        logger: FakeLogger(),
        runtimeState: RuntimeState(),
      );
      final server = _buildServer(ctx);
      dsFinal = _FakeDataStore(serverPart: _FakeServerPart(server));
      ds = dsFinal;
    });

    test('dispatches Event.serverScheduledEventUpdate', () async {
      final packet =
          GuildScheduledEventUpdatePacket(marshaller: marshaller, dataStore: ds);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_buildUpdateMessage(), dispatch);
      expect(capturedEvent, equals(Event.serverScheduledEventUpdate));
    });

    test('before is null when no cache entry exists', () async {
      final packet =
          GuildScheduledEventUpdatePacket(marshaller: marshaller, dataStore: ds);
      ServerScheduledEventUpdateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.serverScheduledEventUpdate) {
          args = payload as ServerScheduledEventUpdateArgs;
        }
      }

      await packet.listen(_buildUpdateMessage(), dispatch);
      expect(args, isNotNull);
      expect(args!.before, isNull);
      expect(args!.after.id, equals(Snowflake.parse(_eventId)));
    });

    test('before is populated when cache entry exists', () async {
      // Pre-populate cache with the "before" event data
      final cacheKey = marshaller.cacheKey.scheduledEvent(_serverId, _eventId);
      final beforePayload = Map<String, dynamic>.from(_scheduledEventPayload())
        ..['name'] = 'Old Event Name';
      await cache.put(cacheKey, beforePayload);

      final packet =
          GuildScheduledEventUpdatePacket(marshaller: marshaller, dataStore: ds);
      ServerScheduledEventUpdateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.serverScheduledEventUpdate) {
          args = payload as ServerScheduledEventUpdateArgs;
        }
      }

      await packet.listen(_buildUpdateMessage(), dispatch);

      expect(args, isNotNull);
      expect(args!.before, isNotNull);
      expect(args!.before!.name, equals('Old Event Name'));
      expect(args!.after.name, equals('Test Event'));
      expect(args!.server.id, equals(Snowflake.parse(_serverId)));
    });
  });

  // ── GUILD_SCHEDULED_EVENT_DELETE ───────────────────────────────────────────

  group('GuildScheduledEventDeletePacket', () {
    late _FakeDataStore ds;
    late _FakeMarshaller marshaller;

    setUp(() {
      late _FakeDataStore dsFinal;
      marshaller = _FakeMarshaller(
        entityContext: EntityContext(
          datastore: _LazyDataStore(() => dsFinal),
          wss: FakeWebsocketOrchestrator(),
          logger: FakeLogger(),
          runtimeState: RuntimeState(),
        ),
      );
      final ctx = EntityContext(
        datastore: _NullDataStore(),
        wss: FakeWebsocketOrchestrator(),
        logger: FakeLogger(),
        runtimeState: RuntimeState(),
      );
      final server = _buildServer(ctx);
      dsFinal = _FakeDataStore(serverPart: _FakeServerPart(server));
      ds = dsFinal;
    });

    test('dispatches Event.serverScheduledEventDelete', () async {
      final packet =
          GuildScheduledEventDeletePacket(marshaller: marshaller, dataStore: ds);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_buildDeleteMessage(), dispatch);
      expect(capturedEvent, equals(Event.serverScheduledEventDelete));
    });

    test('payload carries server and correctly serialized GuildScheduledEvent',
        () async {
      final packet =
          GuildScheduledEventDeletePacket(marshaller: marshaller, dataStore: ds);
      ServerScheduledEventDeleteArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.serverScheduledEventDelete) {
          args = payload as ServerScheduledEventDeleteArgs;
        }
      }

      await packet.listen(_buildDeleteMessage(), dispatch);
      expect(args, isNotNull);
      expect(args!.server.id, equals(Snowflake.parse(_serverId)));
      expect(args!.event.id, equals(Snowflake.parse(_eventId)));
      expect(args!.event.name, equals('Test Event'));
    });
  });

  // ── GUILD_SCHEDULED_EVENT_USER_ADD ─────────────────────────────────────────

  group('GuildScheduledEventUserAddPacket', () {
    late _FakeDataStore ds;

    setUp(() {
      final ctx = EntityContext(
        datastore: _NullDataStore(),
        wss: FakeWebsocketOrchestrator(),
        logger: FakeLogger(),
        runtimeState: RuntimeState(),
      );
      late _FakeDataStore dsFinal;
      final user = _buildUser(ctx);
      dsFinal = _FakeDataStore(
        serverPart: _FakeServerPart(_buildServer(ctx)),
        userPart: _FakeUserPart(user),
      );
      ds = dsFinal;
    });

    test('dispatches Event.serverScheduledEventUserAdd', () async {
      final packet = GuildScheduledEventUserAddPacket(dataStore: ds);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_buildUserAddMessage(), dispatch);
      expect(capturedEvent, equals(Event.serverScheduledEventUserAdd));
    });

    test('payload carries server, eventId, and user', () async {
      final packet = GuildScheduledEventUserAddPacket(dataStore: ds);
      ServerScheduledEventUserAddArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.serverScheduledEventUserAdd) {
          args = payload as ServerScheduledEventUserAddArgs;
        }
      }

      await packet.listen(_buildUserAddMessage(), dispatch);

      expect(args, isNotNull);
      expect(args!.server.id, equals(Snowflake.parse(_serverId)));
      expect(args!.eventId, equals(Snowflake.parse(_eventId)));
      expect(args!.user.id, equals(Snowflake.parse(_userId)));
    });
  });

  // ── GUILD_SCHEDULED_EVENT_USER_REMOVE ──────────────────────────────────────

  group('GuildScheduledEventUserRemovePacket', () {
    late _FakeDataStore ds;

    setUp(() {
      final ctx = EntityContext(
        datastore: _NullDataStore(),
        wss: FakeWebsocketOrchestrator(),
        logger: FakeLogger(),
        runtimeState: RuntimeState(),
      );
      late _FakeDataStore dsFinal;
      final user = _buildUser(ctx);
      dsFinal = _FakeDataStore(
        serverPart: _FakeServerPart(_buildServer(ctx)),
        userPart: _FakeUserPart(user),
      );
      ds = dsFinal;
    });

    test('dispatches Event.serverScheduledEventUserRemove', () async {
      final packet = GuildScheduledEventUserRemovePacket(dataStore: ds);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_buildUserRemoveMessage(), dispatch);
      expect(capturedEvent, equals(Event.serverScheduledEventUserRemove));
    });

    test('payload carries server, eventId, and user', () async {
      final packet = GuildScheduledEventUserRemovePacket(dataStore: ds);
      ServerScheduledEventUserRemoveArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.serverScheduledEventUserRemove) {
          args = payload as ServerScheduledEventUserRemoveArgs;
        }
      }

      await packet.listen(_buildUserRemoveMessage(), dispatch);

      expect(args, isNotNull);
      expect(args!.server.id, equals(Snowflake.parse(_serverId)));
      expect(args!.eventId, equals(Snowflake.parse(_eventId)));
      expect(args!.user.id, equals(Snowflake.parse(_userId)));
    });
  });
}

// ── Helpers ───────────────────────────────────────────────────────────────────

final class _DummyServerPart implements ServerPartContract {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());

  @override
  Future<Server> get(Object id, bool force) => throw UnimplementedError();
}

/// A [DataStoreContract] that resolves lazily, used to break circular init deps.
final class _LazyDataStore implements DataStoreContract {
  final DataStoreContract Function() _resolve;
  _LazyDataStore(this._resolve);

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
