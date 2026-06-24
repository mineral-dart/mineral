/// Tests for THREAD_CREATE, THREAD_UPDATE, and THREAD_DELETE.
library;

import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/common/runtime_state.dart';
import 'package:mineral/src/domains/services/datastore/request_bucket_contract.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/thread_create_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/thread_delete_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/thread_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:test/test.dart';

import '../helpers/fake_cache_provider.dart';
import '../helpers/fake_logger.dart';
import '../helpers/fake_marshaller.dart';
import '../helpers/fake_websocket_orchestrator.dart';
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
  late _FakeGuildDataStore dataStore;

  setUp(() {
    wss = FakeWebsocketOrchestrator();
    cache = FakeCacheProvider();

    late _FakeGuildDataStore dsFinal;
    marshaller = FakeMarshaller(
      cache: cache,
      entityContext: EntityContext(
        datastore: LazyDataStore(() => dsFinal),
        wss: wss,
        logger: FakeLogger(),
        runtimeState: RuntimeState(),
      ),
    );

    final ctx = EntityContext(
      datastore: LazyDataStore(() => dsFinal),
      wss: wss,
      logger: FakeLogger(),
      runtimeState: RuntimeState(),
    );

    fakeGuild = buildMinimalGuild(_guildId, ctx);
    dsFinal = _FakeGuildDataStore(FakeGuildPart(fakeGuild));
    dataStore = dsFinal;
  });

  // ── THREAD_CREATE ──────────────────────────────────────────────────────────

  group('ThreadCreatePacket', () {
    test('packetType is PacketType.threadCreate', () {
      final packet =
          ThreadCreatePacket(marshaller: marshaller, dataStore: dataStore);
      expect(packet.packetType, equals(PacketType.threadCreate));
      expect(packet.packetType.name, equals('THREAD_CREATE'));
    });

    test('dispatches Event.guildThreadCreate', () async {
      final packet =
          ThreadCreatePacket(marshaller: marshaller, dataStore: dataStore);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_msg('THREAD_CREATE', _threadPayload()), dispatch);

      expect(capturedEvent, equals(Event.guildThreadCreate));
    });

    test('payload carries guild and thread channel', () async {
      final packet =
          ThreadCreatePacket(marshaller: marshaller, dataStore: dataStore);
      GuildThreadCreateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
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
      final packet =
          ThreadUpdatePacket(marshaller: marshaller, dataStore: dataStore);
      expect(packet.packetType, equals(PacketType.threadUpdate));
      expect(packet.packetType.name, equals('THREAD_UPDATE'));
    });

    test('dispatches Event.guildThreadUpdate', () async {
      // Pre-seed thread in cache so getOrFail doesn't throw.
      final threadCacheKey = marshaller.cacheKey.thread(_threadId);
      final normalized =
          await marshaller.serializers.channels.normalize(_threadPayload());
      await cache.put(threadCacheKey, normalized);

      final packet =
          ThreadUpdatePacket(marshaller: marshaller, dataStore: dataStore);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_msg('THREAD_UPDATE', _threadPayload()), dispatch);

      expect(capturedEvent, equals(Event.guildThreadUpdate));
    });

    test('before is null when no cache is configured', () async {
      // Use a marshaller WITHOUT cache so getOrFail? returns null.
      final nocacheMarshallerCtx = EntityContext(
        datastore: LazyDataStore(() => dataStore),
        wss: wss,
        logger: FakeLogger(),
        runtimeState: RuntimeState(),
      );
      final noCache = FakeMarshaller(entityContext: nocacheMarshallerCtx);

      final packet =
          ThreadUpdatePacket(marshaller: noCache, dataStore: dataStore);
      GuildThreadUpdateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
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
      final oldNormalized = await marshaller.serializers.channels
          .normalize(_threadPayload(name: 'old-thread'));
      await cache.put(threadCacheKey, oldNormalized);

      final packet =
          ThreadUpdatePacket(marshaller: marshaller, dataStore: dataStore);
      GuildThreadUpdateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildThreadUpdate) {
          args = payload as GuildThreadUpdateArgs;
        }
      }

      await packet.listen(
          _msg('THREAD_UPDATE', _threadPayload(name: 'new-thread')), dispatch);

      expect(args, isNotNull);
      expect(args!.before, isNotNull);
      expect(args!.after.id, equals(Snowflake.parse(_threadId)));
    });
  });

  // ── THREAD_DELETE ──────────────────────────────────────────────────────────

  group('ThreadDeletePacket', () {
    test('packetType is PacketType.threadDelete', () {
      final packet =
          ThreadDeletePacket(marshaller: marshaller, dataStore: dataStore);
      expect(packet.packetType, equals(PacketType.threadDelete));
      expect(packet.packetType.name, equals('THREAD_DELETE'));
    });

    test('dispatches Event.guildThreadDelete', () async {
      // Pre-seed so getOrFail doesn't throw.
      final threadCacheKey = marshaller.cacheKey.thread(_threadId);
      final normalized =
          await marshaller.serializers.channels.normalize(_threadPayload());
      await cache.put(threadCacheKey, normalized);

      final packet =
          ThreadDeletePacket(marshaller: marshaller, dataStore: dataStore);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_msg('THREAD_DELETE', _threadPayload()), dispatch);

      expect(capturedEvent, equals(Event.guildThreadDelete));
    });

    test('payload carries guild on delete', () async {
      // Pre-seed thread in cache so the packet can deserialize before deleting.
      final threadCacheKey = marshaller.cacheKey.thread(_threadId);
      final normalized =
          await marshaller.serializers.channels.normalize(_threadPayload());
      await cache.put(threadCacheKey, normalized);

      final packet =
          ThreadDeletePacket(marshaller: marshaller, dataStore: dataStore);
      GuildThreadDeleteArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
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
      final normalized =
          await marshaller.serializers.channels.normalize(_threadPayload());
      await cache.put(threadCacheKey, normalized);
      expect(cache.store.containsKey(threadCacheKey), isTrue);

      final packet =
          ThreadDeletePacket(marshaller: marshaller, dataStore: dataStore);

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {}

      await packet.listen(_msg('THREAD_DELETE', _threadPayload()), dispatch);

      final cached = await cache.get(threadCacheKey);
      expect(cached, isNull);
    });
  });
}

// ── Fake DataStore ────────────────────────────────────────────────────────────

final class _FakeGuildDataStore implements DataStoreContract {
  final GuildPartContract _guildPart;
  _FakeGuildDataStore(this._guildPart);

  @override
  GuildPartContract get guild => _guildPart;

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
  ThreadPartContract get thread => throw UnimplementedError();
  @override
  InvitePartContract get invite => throw UnimplementedError();
  @override
  WebhookPartContract get webhook => throw UnimplementedError();
  @override
  GuildScheduledEventPartContract get scheduledEvent =>
      throw UnimplementedError();
  @override
  ApplicationEmojiPartContract get applicationEmoji =>
      throw UnimplementedError();
  @override
  WelcomeScreenPartContract get welcomeScreen => throw UnimplementedError();
  @override
  OnboardingPartContract get onboarding => throw UnimplementedError();
  @override
  TemplatePartContract get template => throw UnimplementedError();
  @override
  StageInstancePartContract get stageInstance => throw UnimplementedError();
  @override
  MonetizationPartContract get monetization => throw UnimplementedError();
  @override
  SoundboardPartContract get soundboard => throw UnimplementedError();
  @override
  RequestBucketContract get requestBucket => throw UnimplementedError();
  @override
  HttpClientContract get client => throw UnimplementedError();
}
