/// Tests for THREAD_CREATE, THREAD_UPDATE, and THREAD_DELETE.
library;

import 'package:mineral/api.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/thread_create_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/thread_delete_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/thread_update_packet.dart';
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
const _threadId = '777888999000111222';
const _parentId = '111222333444555666';

// ── Minimal thread payload (public thread, type=11) ───────────────────────────

Map<String, dynamic> _threadPayload({String name = 'test-thread'}) => {
  'id': _threadId,
  'type': 11, // GUILD_PUBLIC_THREAD
  'guild_id': _guildId,
  'parent_id': _parentId,
  'name': name,
  'owner_id': '987654321098765432',
  'message_count': 0,
  'member_count': 1,
  'thread_metadata': {
    'archived': false,
    'auto_archive_duration': 60,
    'archive_timestamp': '2024-01-01T00:00:00.000Z',
    'locked': false,
    'create_timestamp': '2024-01-01T00:00:00.000Z',
  },
  'rate_limit_per_user': 0,
  'total_message_sent': 0,
  'flags': 0,
  'last_message_id': null,
  'nsfw': false,
  'permission_overwrites': <dynamic>[],
  'position': null,
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
  late Guild fakeGuild;
  late MockDataStore dataStore;

  setUp(() {
    wss = FakeWebsocketOrchestrator();
    cache = FakeCacheProvider();

    dataStore = MockDataStore();
    fakeGuild = buildMinimalGuild(
      _guildId,
      buildCtx(dataStore: dataStore, wss: wss),
    );
    when(() => dataStore.guild).thenReturn(FakeGuildPart(fakeGuild));

    marshaller = FakeMarshaller(
      cache: cache,
      entityContext: buildCtx(dataStore: dataStore, wss: wss),
    );
  });

  // ── THREAD_CREATE ──────────────────────────────────────────────────────────

  group('ThreadCreatePacket', () {
    test('packetType is PacketType.threadCreate', () {
      final packet = ThreadCreatePacket(
        marshaller: marshaller,
        dataStore: dataStore,
      );
      expect(packet.packetType, equals(PacketType.threadCreate));
      expect(packet.packetType.name, equals('THREAD_CREATE'));
    });

    test('dispatches Event.guildThreadCreate', () async {
      final packet = ThreadCreatePacket(
        marshaller: marshaller,
        dataStore: dataStore,
      );
      Event? capturedEvent;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        capturedEvent = event;
      }

      await packet.listen(_msg('THREAD_CREATE', _threadPayload()), dispatch);

      expect(capturedEvent, equals(Event.guildThreadCreate));
    });

    test('payload carries guild and thread channel', () async {
      final packet = ThreadCreatePacket(
        marshaller: marshaller,
        dataStore: dataStore,
      );
      GuildThreadCreateArgs? args;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        if (event == Event.guildThreadCreate) {
          args = payload as GuildThreadCreateArgs;
        }
      }

      await packet.listen(_msg('THREAD_CREATE', _threadPayload()), dispatch);

      expect(args, isNotNull);
      expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
      expect(args!.channel.id, equals(Snowflake.parse(_threadId)));
      expect(args!.channel, isA<ThreadChannel>());
    });
  });

  // ── THREAD_UPDATE ──────────────────────────────────────────────────────────

  group('ThreadUpdatePacket', () {
    test('packetType is PacketType.threadUpdate', () {
      final packet = ThreadUpdatePacket(
        marshaller: marshaller,
        dataStore: dataStore,
      );
      expect(packet.packetType, equals(PacketType.threadUpdate));
      expect(packet.packetType.name, equals('THREAD_UPDATE'));
    });

    test('dispatches Event.guildThreadUpdate', () async {
      // Pre-seed thread in cache so getOrFail doesn't throw.
      final threadCacheKey = marshaller.cacheKey.thread(_threadId);
      final normalized = await marshaller.serializers.channels.normalize(
        _threadPayload(),
      );
      await cache.put(threadCacheKey, normalized);

      final packet = ThreadUpdatePacket(
        marshaller: marshaller,
        dataStore: dataStore,
      );
      Event? capturedEvent;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        capturedEvent = event;
      }

      await packet.listen(_msg('THREAD_UPDATE', _threadPayload()), dispatch);

      expect(capturedEvent, equals(Event.guildThreadUpdate));
    });

    test('before is null when no cache is configured', () async {
      // Use a marshaller WITHOUT cache so getOrFail? returns null.
      final noCache = FakeMarshaller(
        entityContext: buildCtx(dataStore: dataStore, wss: wss),
      );

      final packet = ThreadUpdatePacket(
        marshaller: noCache,
        dataStore: dataStore,
      );
      GuildThreadUpdateArgs? args;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        if (event == Event.guildThreadUpdate) {
          args = payload as GuildThreadUpdateArgs;
        }
      }

      await packet.listen(_msg('THREAD_UPDATE', _threadPayload()), dispatch);

      expect(args, isNotNull);
      expect(args!.before, isNull);
      expect(args!.after.id, equals(Snowflake.parse(_threadId)));
    });

    test('before is populated when thread is in cache', () async {
      final threadCacheKey = marshaller.cacheKey.thread(_threadId);
      final oldNormalized = await marshaller.serializers.channels.normalize(
        _threadPayload(name: 'old-thread'),
      );
      await cache.put(threadCacheKey, oldNormalized);

      final packet = ThreadUpdatePacket(
        marshaller: marshaller,
        dataStore: dataStore,
      );
      GuildThreadUpdateArgs? args;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        if (event == Event.guildThreadUpdate) {
          args = payload as GuildThreadUpdateArgs;
        }
      }

      await packet.listen(
        _msg('THREAD_UPDATE', _threadPayload(name: 'new-thread')),
        dispatch,
      );

      expect(args, isNotNull);
      expect(args!.before, isNotNull);
      expect(args!.after.id, equals(Snowflake.parse(_threadId)));
    });
  });

  // ── THREAD_DELETE ──────────────────────────────────────────────────────────

  group('ThreadDeletePacket', () {
    test('packetType is PacketType.threadDelete', () {
      final packet = ThreadDeletePacket(
        marshaller: marshaller,
        dataStore: dataStore,
      );
      expect(packet.packetType, equals(PacketType.threadDelete));
      expect(packet.packetType.name, equals('THREAD_DELETE'));
    });

    test('dispatches Event.guildThreadDelete', () async {
      // Pre-seed so getOrFail doesn't throw.
      final threadCacheKey = marshaller.cacheKey.thread(_threadId);
      final normalized = await marshaller.serializers.channels.normalize(
        _threadPayload(),
      );
      await cache.put(threadCacheKey, normalized);

      final packet = ThreadDeletePacket(
        marshaller: marshaller,
        dataStore: dataStore,
      );
      Event? capturedEvent;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        capturedEvent = event;
      }

      await packet.listen(_msg('THREAD_DELETE', _threadPayload()), dispatch);

      expect(capturedEvent, equals(Event.guildThreadDelete));
    });

    test('payload carries guild on delete', () async {
      // Pre-seed thread in cache so the packet can deserialize before deleting.
      final threadCacheKey = marshaller.cacheKey.thread(_threadId);
      final normalized = await marshaller.serializers.channels.normalize(
        _threadPayload(),
      );
      await cache.put(threadCacheKey, normalized);

      final packet = ThreadDeletePacket(
        marshaller: marshaller,
        dataStore: dataStore,
      );
      GuildThreadDeleteArgs? args;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        if (event == Event.guildThreadDelete) {
          args = payload as GuildThreadDeleteArgs;
        }
      }

      await packet.listen(_msg('THREAD_DELETE', _threadPayload()), dispatch);

      expect(args, isNotNull);
      expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
      expect(args!.thread?.id, equals(Snowflake.parse(_threadId)));
    });

    test('thread cache is invalidated on delete', () async {
      final threadCacheKey = marshaller.cacheKey.thread(_threadId);
      final normalized = await marshaller.serializers.channels.normalize(
        _threadPayload(),
      );
      await cache.put(threadCacheKey, normalized);
      expect(cache.store.containsKey(threadCacheKey), isTrue);

      final packet = ThreadDeletePacket(
        marshaller: marshaller,
        dataStore: dataStore,
      );

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {}

      await packet.listen(_msg('THREAD_DELETE', _threadPayload()), dispatch);

      final cached = await cache.get(threadCacheKey);
      expect(cached, isNull);
    });
  });
}
