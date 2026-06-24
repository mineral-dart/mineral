import 'package:mineral/api.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/api/guild/managers/threads_manager.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/channel_create_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/channel_delete_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/channel_pins_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/channel_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../helpers/fake_cache_provider.dart';
import '../helpers/fake_logger.dart';
import '../helpers/fake_marshaller.dart';
import '../helpers/fake_websocket_orchestrator.dart';
import '../helpers/mocks.dart';
import 'helpers/packet_test_helpers.dart';

// ── IDs ───────────────────────────────────────────────────────────────────────

const _guildId = '123456789012345678';
const _channelId = '777888999000111222';

// ── Minimal channel payload (guild text channel, type=0) ─────────────────────

Map<String, dynamic> _guildTextChannelPayload() => {
      'id': _channelId,
      'type': 0, // GUILD_TEXT
      'guild_id': _guildId,
      'name': 'general',
      'position': 1,
      'permission_overwrites': <Map<String, dynamic>>[],
      'nsfw': false,
      'topic': null,
      'last_message_id': null,
      'parent_id': null,
      'rate_limit_per_user': 0,
    };

ShardMessage<dynamic> _msg(String type, Map<String, dynamic> payload) =>
    ShardMessage(
      type: type,
      opCode: OpCode.dispatch,
      sequence: 1,
      payload: payload,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeWebsocketOrchestrator wss;
  late FakeCacheProvider cache;
  late FakeMarshaller marshaller;
  late FakeLogger logger;
  late Guild fakeGuild;
  late GuildTextChannel fakeChannel;

  setUp(() async {
    wss = FakeWebsocketOrchestrator();
    cache = FakeCacheProvider();
    logger = FakeLogger();

    final ds = MockDataStore();
    final ctx = buildCtx(dataStore: ds, wss: wss);
    fakeGuild = buildMinimalGuild(_guildId, ctx);
    fakeChannel = _buildGuildTextChannel(ctx);
    when(() => ds.guild).thenReturn(FakeGuildPart(fakeGuild));
    when(() => ds.channel).thenReturn(FakeChannelPart(fakeChannel));

    marshaller = FakeMarshaller(
      cache: cache,
      logger: logger,
      entityContext: buildCtx(dataStore: ds, wss: wss),
    );
  });

  // ── CHANNEL_CREATE ─────────────────────────────────────────────────────────

  group('ChannelCreatePacket', () {
    test('packetType is PacketType.channelCreate', () {
      final packet =
          ChannelCreatePacket(logger: logger, marshaller: marshaller);
      expect(packet.packetType, equals(PacketType.channelCreate));
      expect(packet.packetType.name, equals('CHANNEL_CREATE'));
    });

    test('dispatches Event.guildChannelCreate for guild text channel', () async {
      final packet =
          ChannelCreatePacket(logger: logger, marshaller: marshaller);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(
          _msg('CHANNEL_CREATE', _guildTextChannelPayload()), dispatch);

      expect(capturedEvent, equals(Event.guildChannelCreate));
    });

    test('payload is GuildChannelCreateArgs with correct channel', () async {
      final packet =
          ChannelCreatePacket(logger: logger, marshaller: marshaller);
      GuildChannelCreateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildChannelCreate) {
          args = payload as GuildChannelCreateArgs;
        }
      }

      await packet.listen(
          _msg('CHANNEL_CREATE', _guildTextChannelPayload()), dispatch);

      expect(args, isNotNull);
      expect(args!.channel.id, equals(Snowflake.parse(_channelId)));
      expect(args!.channel, isA<GuildTextChannel>());
    });

    test('channel is cached after dispatch', () async {
      final packet =
          ChannelCreatePacket(logger: logger, marshaller: marshaller);

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {}

      await packet.listen(
          _msg('CHANNEL_CREATE', _guildTextChannelPayload()), dispatch);

      final channelCacheKey = marshaller.cacheKey.channel(_channelId);
      final cached = await cache.get(channelCacheKey);
      expect(cached, isNotNull);
    });
  });

  // ── CHANNEL_UPDATE ─────────────────────────────────────────────────────────

  group('ChannelUpdatePacket', () {
    test('packetType is PacketType.channelUpdate', () {
      final packet =
          ChannelUpdatePacket(logger: logger, marshaller: marshaller);
      expect(packet.packetType, equals(PacketType.channelUpdate));
      expect(packet.packetType.name, equals('CHANNEL_UPDATE'));
    });

    test('dispatches Event.guildChannelUpdate', () async {
      final packet =
          ChannelUpdatePacket(logger: logger, marshaller: marshaller);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(
          _msg('CHANNEL_UPDATE', _guildTextChannelPayload()), dispatch);

      expect(capturedEvent, equals(Event.guildChannelUpdate));
    });

    test('before is null when channel not in cache', () async {
      final packet =
          ChannelUpdatePacket(logger: logger, marshaller: marshaller);
      GuildChannelUpdateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildChannelUpdate) {
          args = payload as GuildChannelUpdateArgs;
        }
      }

      await packet.listen(
          _msg('CHANNEL_UPDATE', _guildTextChannelPayload()), dispatch);

      expect(args, isNotNull);
      expect(args!.before, isNull);
      expect(args!.after.id, equals(Snowflake.parse(_channelId)));
    });

    test('before is populated when channel is in cache', () async {
      // Pre-seed cache with normalized channel data.
      final normalized = await marshaller.serializers.channels
          .normalize(_guildTextChannelPayload()..['name'] = 'old-name');
      await cache.put(_channelId, normalized);

      final packet =
          ChannelUpdatePacket(logger: logger, marshaller: marshaller);
      GuildChannelUpdateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildChannelUpdate) {
          args = payload as GuildChannelUpdateArgs;
        }
      }

      final updatedPayload = Map<String, dynamic>.from(_guildTextChannelPayload())
        ..['name'] = 'new-name';

      await packet.listen(_msg('CHANNEL_UPDATE', updatedPayload), dispatch);

      expect(args, isNotNull);
      expect(args!.before, isNotNull);
      expect(args!.after.id, equals(Snowflake.parse(_channelId)));
    });
  });

  // ── CHANNEL_DELETE ─────────────────────────────────────────────────────────

  group('ChannelDeletePacket', () {
    test('packetType is PacketType.channelDelete', () {
      final packet = ChannelDeletePacket(marshaller: marshaller);
      expect(packet.packetType, equals(PacketType.channelDelete));
      expect(packet.packetType.name, equals('CHANNEL_DELETE'));
    });

    test('dispatches Event.guildChannelDelete', () async {
      final packet = ChannelDeletePacket(marshaller: marshaller);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(
          _msg('CHANNEL_DELETE', _guildTextChannelPayload()), dispatch);

      expect(capturedEvent, equals(Event.guildChannelDelete));
    });

    test('channel is invalidated from cache on delete', () async {
      final channelCacheKey = marshaller.cacheKey.channel(_channelId);
      await cache.put(channelCacheKey, {'id': _channelId, 'type': 0});

      final packet = ChannelDeletePacket(marshaller: marshaller);

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {}

      await packet.listen(
          _msg('CHANNEL_DELETE', _guildTextChannelPayload()), dispatch);

      final cached = await cache.get(channelCacheKey);
      expect(cached, isNull);
    });

    test('payload carries the deleted channel', () async {
      final packet = ChannelDeletePacket(marshaller: marshaller);
      GuildChannelDeleteArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildChannelDelete) {
          args = payload as GuildChannelDeleteArgs;
        }
      }

      await packet.listen(
          _msg('CHANNEL_DELETE', _guildTextChannelPayload()), dispatch);

      expect(args, isNotNull);
      expect(args!.channel?.id, equals(Snowflake.parse(_channelId)));
    });
  });

  // ── CHANNEL_PINS_UPDATE ────────────────────────────────────────────────────

  group('ChannelPinsUpdatePacket', () {
    late MockDataStore dataStore;

    setUp(() {
      dataStore = buildMockDs(
        guild: FakeGuildPart(fakeGuild),
        channel: FakeChannelPart(fakeChannel),
      );
    });

    test('packetType is PacketType.channelPinsUpdate', () {
      final packet = ChannelPinsUpdatePacket(
          logger: logger, dataStore: dataStore);
      expect(packet.packetType, equals(PacketType.channelPinsUpdate));
      expect(packet.packetType.name, equals('CHANNEL_PINS_UPDATE'));
    });

    test('dispatches Event.guildChannelPinsUpdate for guild channel', () async {
      final packet = ChannelPinsUpdatePacket(
          logger: logger, dataStore: dataStore);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(
          _msg('CHANNEL_PINS_UPDATE', {
            'channel_id': _channelId,
            'guild_id': _guildId,
          }),
          dispatch);

      expect(capturedEvent, equals(Event.guildChannelPinsUpdate));
    });

    test('payload carries guild and channel for guild branch', () async {
      final packet = ChannelPinsUpdatePacket(
          logger: logger, dataStore: dataStore);
      GuildChannelPinsUpdateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildChannelPinsUpdate) {
          args = payload as GuildChannelPinsUpdateArgs;
        }
      }

      await packet.listen(
          _msg('CHANNEL_PINS_UPDATE', {
            'channel_id': _channelId,
            'guild_id': _guildId,
          }),
          dispatch);

      expect(args, isNotNull);
      expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
      expect(args!.channel.id, equals(Snowflake.parse(_channelId)));
    });
  });
}

// ── Domain helpers ────────────────────────────────────────────────────────────

GuildTextChannel _buildGuildTextChannel(EntityContext ctx) => GuildTextChannel(
      ChannelProperties(
        ctx: ctx,
        id: Snowflake.parse(_channelId),
        type: ChannelType.guildText,
        name: 'general',
        description: null,
        guildId: Snowflake.parse(_guildId),
        categoryId: null,
        position: null,
        nsfw: false,
        lastMessageId: null,
        bitrate: null,
        userLimit: null,
        rateLimitPerUser: null,
        recipients: [],
        icon: null,
        ownerId: null,
        applicationId: null,
        lastPinTimestamp: null,
        rtcRegion: null,
        videoQualityMode: null,
        messageCount: null,
        memberCount: null,
        defaultAutoArchiveDuration: null,
        permissions: [],
        flags: null,
        totalMessageSent: null,
        available: null,
        appliedTags: [],
        defaultReactions: null,
        defaultSortOrder: null,
        defaultForumLayout: null,
        threads: ThreadsManager(
          Snowflake.parse(_guildId),
          Snowflake.parse(_channelId),
          ctx: ctx,
        ),
      ),
    );

