import 'package:mineral/api.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_scheduled_event_create_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_scheduled_event_delete_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_scheduled_event_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_scheduled_event_user_add_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_scheduled_event_user_remove_packet.dart';
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
const _eventId = '111222333444555666';
const _userId = '999888777666555444';
const _channelId = '777888999000111222';

// ── Domain object builders ────────────────────────────────────────────────────

User _buildUser(MockDataStore ds) {
  final ctx = buildCtx(dataStore: ds, wss: FakeWebsocketOrchestrator());
  return User(
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
}

// ── Scheduled event payload ───────────────────────────────────────────────────

Map<String, dynamic> _scheduledEventPayload() => {
      'id': _eventId,
      'guild_id': _guildId,
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
        'guild_id': _guildId,
        'guild_scheduled_event_id': _eventId,
        'user_id': _userId,
      },
    );

ShardMessage<dynamic> _buildUserRemoveMessage() => ShardMessage(
      type: 'GUILD_SCHEDULED_EVENT_USER_REMOVE',
      opCode: OpCode.dispatch,
      sequence: 5,
      payload: {
        'guild_id': _guildId,
        'guild_scheduled_event_id': _eventId,
        'user_id': _userId,
      },
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── PacketType identity ────────────────────────────────────────────────────

  group('PacketType identity', () {
    test('GuildScheduledEventCreatePacket has correct packetType', () {
      final marshaller = FakeMarshaller();
      final packet = GuildScheduledEventCreatePacket(
        marshaller: marshaller,
        dataStore: buildMockDs(),
      );
      expect(packet.packetType, equals(PacketType.guildScheduledEventCreate));
      expect(packet.packetType.name, equals('GUILD_SCHEDULED_EVENT_CREATE'));
    });

    test('GuildScheduledEventUpdatePacket has correct packetType', () {
      final marshaller = FakeMarshaller();
      final packet = GuildScheduledEventUpdatePacket(
        marshaller: marshaller,
        dataStore: buildMockDs(),
      );
      expect(packet.packetType, equals(PacketType.guildScheduledEventUpdate));
      expect(packet.packetType.name, equals('GUILD_SCHEDULED_EVENT_UPDATE'));
    });

    test('GuildScheduledEventDeletePacket has correct packetType', () {
      final marshaller = FakeMarshaller();
      final packet = GuildScheduledEventDeletePacket(
        marshaller: marshaller,
        dataStore: buildMockDs(),
      );
      expect(packet.packetType, equals(PacketType.guildScheduledEventDelete));
      expect(packet.packetType.name, equals('GUILD_SCHEDULED_EVENT_DELETE'));
    });

    test('GuildScheduledEventUserAddPacket has correct packetType', () {
      final packet = GuildScheduledEventUserAddPacket(
        dataStore: buildMockDs(),
      );
      expect(packet.packetType, equals(PacketType.guildScheduledEventUserAdd));
      expect(packet.packetType.name, equals('GUILD_SCHEDULED_EVENT_USER_ADD'));
    });

    test('GuildScheduledEventUserRemovePacket has correct packetType', () {
      final packet = GuildScheduledEventUserRemovePacket(
        dataStore: buildMockDs(),
      );
      expect(
          packet.packetType, equals(PacketType.guildScheduledEventUserRemove));
      expect(packet.packetType.name,
          equals('GUILD_SCHEDULED_EVENT_USER_REMOVE'));
    });
  });

  // ── GUILD_SCHEDULED_EVENT_CREATE ───────────────────────────────────────────

  group('GuildScheduledEventCreatePacket', () {
    late MockDataStore ds;
    late FakeMarshaller marshaller;

    setUp(() {
      ds = MockDataStore();
      final guild = buildMinimalGuild(_guildId, buildCtx(dataStore: ds, wss: FakeWebsocketOrchestrator()));
      when(() => ds.guild).thenReturn(FakeGuildPart(guild));
      marshaller = FakeMarshaller(
        entityContext: buildCtx(dataStore: ds, wss: FakeWebsocketOrchestrator()),
      );
    });

    test('dispatches Event.guildScheduledEventCreate', () async {
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
      expect(capturedEvent, equals(Event.guildScheduledEventCreate));
    });

    test('payload carries guild and correctly serialized GuildScheduledEvent',
        () async {
      final packet =
          GuildScheduledEventCreatePacket(marshaller: marshaller, dataStore: ds);
      GuildScheduledEventCreateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildScheduledEventCreate) {
          args = payload as GuildScheduledEventCreateArgs;
        }
      }

      await packet.listen(_buildCreateMessage(), dispatch);

      expect(args, isNotNull);
      expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
      expect(args!.guild.name, equals('Test Guild'));
      final e = args!.event;
      expect(e.id, equals(Snowflake.parse(_eventId)));
      expect(e.guildId, equals(Snowflake.parse(_guildId)));
      expect(e.name, equals('Test Event'));
      expect(e.status, equals(GuildScheduledEventStatus.scheduled));
      expect(e.entityType, equals(GuildScheduledEventEntityType.voice));
      expect(e.privacyLevel, equals(GuildScheduledEventPrivacyLevel.guildOnly));
    });
  });

  // ── GUILD_SCHEDULED_EVENT_UPDATE ───────────────────────────────────────────

  group('GuildScheduledEventUpdatePacket', () {
    late MockDataStore ds;
    late FakeMarshaller marshaller;
    late FakeCacheProvider cache;

    setUp(() {
      cache = FakeCacheProvider();
      ds = MockDataStore();
      final guild = buildMinimalGuild(_guildId, buildCtx(dataStore: ds, wss: FakeWebsocketOrchestrator()));
      when(() => ds.guild).thenReturn(FakeGuildPart(guild));
      marshaller = FakeMarshaller(
        cache: cache,
        entityContext: buildCtx(dataStore: ds, wss: FakeWebsocketOrchestrator()),
      );
    });

    test('dispatches Event.guildScheduledEventUpdate', () async {
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
      expect(capturedEvent, equals(Event.guildScheduledEventUpdate));
    });

    test('before is null when no cache entry exists', () async {
      final packet =
          GuildScheduledEventUpdatePacket(marshaller: marshaller, dataStore: ds);
      GuildScheduledEventUpdateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildScheduledEventUpdate) {
          args = payload as GuildScheduledEventUpdateArgs;
        }
      }

      await packet.listen(_buildUpdateMessage(), dispatch);
      expect(args, isNotNull);
      expect(args!.before, isNull);
      expect(args!.after.id, equals(Snowflake.parse(_eventId)));
    });

    test('before is populated when cache entry exists', () async {
      // Pre-populate cache with the "before" event data
      final cacheKey = marshaller.cacheKey.scheduledEvent(_guildId, _eventId);
      final beforePayload = Map<String, dynamic>.from(_scheduledEventPayload())
        ..['name'] = 'Old Event Name';
      await cache.put(cacheKey, beforePayload);

      final packet =
          GuildScheduledEventUpdatePacket(marshaller: marshaller, dataStore: ds);
      GuildScheduledEventUpdateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildScheduledEventUpdate) {
          args = payload as GuildScheduledEventUpdateArgs;
        }
      }

      await packet.listen(_buildUpdateMessage(), dispatch);

      expect(args, isNotNull);
      expect(args!.before, isNotNull);
      expect(args!.before!.name, equals('Old Event Name'));
      expect(args!.after.name, equals('Test Event'));
      expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
    });
  });

  // ── GUILD_SCHEDULED_EVENT_DELETE ───────────────────────────────────────────

  group('GuildScheduledEventDeletePacket', () {
    late MockDataStore ds;
    late FakeMarshaller marshaller;

    setUp(() {
      ds = MockDataStore();
      final guild = buildMinimalGuild(_guildId, buildCtx(dataStore: ds, wss: FakeWebsocketOrchestrator()));
      when(() => ds.guild).thenReturn(FakeGuildPart(guild));
      marshaller = FakeMarshaller(
        entityContext: buildCtx(dataStore: ds, wss: FakeWebsocketOrchestrator()),
      );
    });

    test('dispatches Event.guildScheduledEventDelete', () async {
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
      expect(capturedEvent, equals(Event.guildScheduledEventDelete));
    });

    test('payload carries guild and correctly serialized GuildScheduledEvent',
        () async {
      final packet =
          GuildScheduledEventDeletePacket(marshaller: marshaller, dataStore: ds);
      GuildScheduledEventDeleteArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildScheduledEventDelete) {
          args = payload as GuildScheduledEventDeleteArgs;
        }
      }

      await packet.listen(_buildDeleteMessage(), dispatch);
      expect(args, isNotNull);
      expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
      expect(args!.event.id, equals(Snowflake.parse(_eventId)));
      expect(args!.event.name, equals('Test Event'));
    });
  });

  // ── GUILD_SCHEDULED_EVENT_USER_ADD ─────────────────────────────────────────

  group('GuildScheduledEventUserAddPacket', () {
    late MockDataStore ds;

    setUp(() {
      ds = MockDataStore();
      final guild = buildMinimalGuild(_guildId, buildCtx(dataStore: ds, wss: FakeWebsocketOrchestrator()));
      final user = _buildUser(ds);
      when(() => ds.guild).thenReturn(FakeGuildPart(guild));
      when(() => ds.user).thenReturn(FakeUserPart(user));
    });

    test('dispatches Event.guildScheduledEventUserAdd', () async {
      final packet = GuildScheduledEventUserAddPacket(dataStore: ds);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_buildUserAddMessage(), dispatch);
      expect(capturedEvent, equals(Event.guildScheduledEventUserAdd));
    });

    test('payload carries guild, eventId, and user', () async {
      final packet = GuildScheduledEventUserAddPacket(dataStore: ds);
      GuildScheduledEventUserAddArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildScheduledEventUserAdd) {
          args = payload as GuildScheduledEventUserAddArgs;
        }
      }

      await packet.listen(_buildUserAddMessage(), dispatch);

      expect(args, isNotNull);
      expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
      expect(args!.eventId, equals(Snowflake.parse(_eventId)));
      expect(args!.user.id, equals(Snowflake.parse(_userId)));
    });
  });

  // ── GUILD_SCHEDULED_EVENT_USER_REMOVE ──────────────────────────────────────

  group('GuildScheduledEventUserRemovePacket', () {
    late MockDataStore ds;

    setUp(() {
      ds = MockDataStore();
      final guild = buildMinimalGuild(_guildId, buildCtx(dataStore: ds, wss: FakeWebsocketOrchestrator()));
      final user = _buildUser(ds);
      when(() => ds.guild).thenReturn(FakeGuildPart(guild));
      when(() => ds.user).thenReturn(FakeUserPart(user));
    });

    test('dispatches Event.guildScheduledEventUserRemove', () async {
      final packet = GuildScheduledEventUserRemovePacket(dataStore: ds);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_buildUserRemoveMessage(), dispatch);
      expect(capturedEvent, equals(Event.guildScheduledEventUserRemove));
    });

    test('payload carries guild, eventId, and user', () async {
      final packet = GuildScheduledEventUserRemovePacket(dataStore: ds);
      GuildScheduledEventUserRemoveArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildScheduledEventUserRemove) {
          args = payload as GuildScheduledEventUserRemoveArgs;
        }
      }

      await packet.listen(_buildUserRemoveMessage(), dispatch);

      expect(args, isNotNull);
      expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
      expect(args!.eventId, equals(Snowflake.parse(_eventId)));
      expect(args!.user.id, equals(Snowflake.parse(_userId)));
    });
  });
}
