import 'package:mineral/api.dart';
import 'package:mineral/src/api/guild/channels/public_thread_channel.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/channel_serializer.dart';
import 'package:test/test.dart';

import '../../helpers/fake_cache_provider.dart';
import '../../helpers/fake_entity_context.dart';
import '../../helpers/fake_marshaller.dart';

// ── Helpers ────────────────────────────────────────────────────────────────

/// Minimal normalised payload common to all guild text-like channels.
Map<String, dynamic> _textChannelPayload({
  String id = '100000000000000001',
  int type = 0, // ChannelType.guildText
  String name = 'general',
  String guildId = '200000000000000001',
}) =>
    {
      'id': id,
      'type': type,
      'name': name,
      'position': 1,
      'guild_id': guildId,
      'parent_id': null,
      'description': null,
      'permission_overwrites': [],
      'nsfw': false,
    };

/// Public thread channel normalised payload.
Map<String, dynamic> _threadPayload({
  String id = '300000000000000001',
  int type = 11, // ChannelType.guildPublicThread
  String name = 'thread-name',
  String guildId = '200000000000000001',
}) =>
    {
      'id': id,
      'type': type,
      'name': name,
      'guild_id': guildId,
      'parent_id': '100000000000000001',
      'position': null,
      'description': null,
      'permission_overwrites': [],
      'nsfw': false,
      'last_message_id': null,
      'flags': 0,
      'rate_limit_per_user': 0,
      'bitrate': 0,
      'user_limit': 0,
      'rtc_region': null,
      'owner_id': '111000111000111000',
      'thread_metadata': {
        'archived': false,
        'archive_timestamp': null,
        'auto_archive_duration': 60,
        'locked': false,
      },
      'message_count': 0,
      'member_count': 0,
      'total_message_sent': 0,
    };

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('ChannelSerializer', () {
    late ChannelSerializer serializer;
    late FakeCacheProvider cache;

    setUp(() {
      cache = FakeCacheProvider();
      serializer = ChannelSerializer(
        FakeMarshaller(cache: cache),
        fakeEntityContext(),
      );
    });

    // ── GuildTextChannel ─────────────────────────────────────────────────

    group('guildText (type 0)', () {
      test('serialize returns a GuildTextChannel', () async {
        final payload = _textChannelPayload(type: 0);
        final channel =
            await serializer.serialize(payload) as GuildTextChannel;

        expect(channel.type, equals(ChannelType.guildText));
        expect(channel.id, equals(Snowflake('100000000000000001')));
        expect(channel.name, equals('general'));
        expect(channel.guildId, equals(Snowflake('200000000000000001')));
      });

      test('normalize caches channel payload under channel key', () async {
        final raw = {
          'id': '100000000000000001',
          'type': 0,
          'name': 'general',
          'position': 1,
          'guild_id': '200000000000000001',
          'parent_id': null,
          'topic': 'A test topic',
          'permission_overwrites': [],
        };

        final result = await serializer.normalize(raw);

        expect(result['id'], equals('100000000000000001'));
        expect(result['type'], equals(0));
        expect(result['name'], equals('general'));
        // topic is remapped to description
        expect(result['description'], equals('A test topic'));

        // cache should contain the entry
        final cacheKey = FakeMarshaller().cacheKey.channel('100000000000000001');
        expect(cache.store.containsKey(cacheKey), isTrue);
      });

      test('deserialize produces map with expected keys', () async {
        final payload = _textChannelPayload(type: 0);
        final channel = await serializer.serialize(payload) as GuildTextChannel;
        final result = await serializer.deserialize(channel);

        expect(result['id'], equals('100000000000000001'));
        expect(result['type'], equals(0));
        expect(result['name'], equals('general'));
        expect(result['guild_id'], equals(Snowflake('200000000000000001')));
      });
    });

    // ── GuildVoiceChannel ────────────────────────────────────────────────

    group('guildVoice (type 2)', () {
      test('serialize returns a GuildVoiceChannel with empty members list',
          () async {
        final payload = _textChannelPayload(type: 2);
        final channel =
            await serializer.serialize(payload) as GuildVoiceChannel;

        expect(channel.type, equals(ChannelType.guildVoice));
        expect(channel.members, isEmpty);
      });

      test('normalize caches voice channel payload', () async {
        final raw = {
          'id': '100000000000000002',
          'type': 2,
          'name': 'voice-chat',
          'position': 2,
          'guild_id': '200000000000000001',
          'parent_id': null,
          'permission_overwrites': [],
        };

        await serializer.normalize(raw);

        final cacheKey = FakeMarshaller().cacheKey.channel('100000000000000002');
        expect(cache.store.containsKey(cacheKey), isTrue);
      });

      test('deserialize produces map with expected keys', () async {
        final payload = _textChannelPayload(
            id: '100000000000000002', type: 2, name: 'voice-chat');
        final channel = await serializer.serialize(payload) as GuildVoiceChannel;
        final result = await serializer.deserialize(channel);

        expect(result['id'], equals('100000000000000002'));
        expect(result['type'], equals(2));
        expect(result['name'], equals('voice-chat'));
      });
    });

    // ── GuildCategoryChannel ─────────────────────────────────────────────

    group('guildCategory (type 4)', () {
      test('serialize returns a GuildCategoryChannel', () async {
        final payload = _textChannelPayload(
            id: '100000000000000003', type: 4, name: 'category');
        final channel =
            await serializer.serialize(payload) as GuildCategoryChannel;

        expect(channel.type, equals(ChannelType.guildCategory));
        expect(channel.name, equals('category'));
      });

      test('normalize caches category payload', () async {
        final raw = {
          'id': '100000000000000003',
          'type': 4,
          'name': 'category',
          'position': 0,
          'guild_id': '200000000000000001',
          'topic': null,
          'nsfw': false,
          'parent_id': null,
          'permission_overwrites': [],
        };

        await serializer.normalize(raw);

        final cacheKey = FakeMarshaller().cacheKey.channel('100000000000000003');
        expect(cache.store.containsKey(cacheKey), isTrue);
      });
    });

    // ── GuildAnnouncementChannel ─────────────────────────────────────────

    group('guildAnnouncement (type 5)', () {
      test('serialize returns a GuildAnnouncementChannel', () async {
        final payload = _textChannelPayload(
            id: '100000000000000004', type: 5, name: 'announcements');
        final channel =
            await serializer.serialize(payload) as GuildAnnouncementChannel;

        expect(channel.type, equals(ChannelType.guildAnnouncement));
      });

      test('deserialize produces map with expected keys', () async {
        final payload = _textChannelPayload(
            id: '100000000000000004', type: 5, name: 'announcements');
        final channel =
            await serializer.serialize(payload) as GuildAnnouncementChannel;
        final result = await serializer.deserialize(channel);

        expect(result['id'], equals('100000000000000004'));
        expect(result['type'], equals(5));
      });

      test('normalize uses parent_id as category_id for announcement channels',
          () async {
        final raw = {
          'id': '100000000000000004',
          'type': 5,
          'name': 'announcements',
          'position': 1,
          'guild_id': '200000000000000001',
          'topic': null,
          'nsfw': false,
          'parent_id': '100000000000000003',
          'permission_overwrites': [],
        };

        final result = await serializer.normalize(raw);

        // GuildAnnouncementChannelFactory maps parent_id → category_id
        expect(result['category_id'], equals('100000000000000003'));
      });
    });

    // ── GuildForumChannel ────────────────────────────────────────────────

    group('guildForum (type 15)', () {
      test('serialize returns a GuildForumChannel', () async {
        final payload = {
          'id': '100000000000000005',
          'type': 15,
          'name': 'forum',
          'guild_id': '200000000000000001',
          'position': 1,
          'parent_id': null,
          'description': 'Forum channel',
          'permission_overwrites': [],
          'nsfw': false,
          'default_sort_order': null,
          'default_forum_layout': null,
          // applied_tags intentionally omitted — defaults to empty list
        };

        final channel =
            await serializer.serialize(payload) as GuildForumChannel;

        expect(channel.type, equals(ChannelType.guildForum));
        expect(channel.name, equals('forum'));
      });

      test('normalize caches forum payload', () async {
        final raw = {
          'id': '100000000000000005',
          'type': 15,
          'name': 'forum',
          'position': 1,
          'guild_id': '200000000000000001',
          'topic': 'Forum discussions',
          'nsfw': false,
          'parent_id': null,
          'permission_overwrites': [],
        };

        await serializer.normalize(raw);

        final cacheKey = FakeMarshaller().cacheKey.channel('100000000000000005');
        expect(cache.store.containsKey(cacheKey), isTrue);
      });
    });

    // ── GuildStageChannel ────────────────────────────────────────────────

    group('guildStageVoice (type 13)', () {
      test('serialize returns a GuildStageChannel', () async {
        final payload = _textChannelPayload(
            id: '100000000000000006', type: 13, name: 'stage');
        final channel =
            await serializer.serialize(payload) as GuildStageChannel;

        expect(channel.type, equals(ChannelType.guildStageVoice));
        expect(channel.name, equals('stage'));
      });

      test('normalize caches stage channel payload', () async {
        final raw = {
          'id': '100000000000000006',
          'type': 13,
          'name': 'stage',
          'position': 1,
          'guild_id': '200000000000000001',
          'topic': null,
          'parent_id': null,
          'permission_overwrites': [],
        };

        await serializer.normalize(raw);

        final cacheKey = FakeMarshaller().cacheKey.channel('100000000000000006');
        expect(cache.store.containsKey(cacheKey), isTrue);
      });
    });

    // ── PublicThreadChannel ──────────────────────────────────────────────

    group('guildPublicThread (type 11)', () {
      test('serialize returns a PublicThreadChannel', () async {
        final payload = _threadPayload(type: 11);
        final channel =
            await serializer.serialize(payload) as PublicThreadChannel;

        expect(channel.type, equals(ChannelType.guildPublicThread));
        expect(channel.name, equals('thread-name'));
      });

      test('serialize exposes ThreadMetadata with archived=false, locked=false',
          () async {
        final payload = _threadPayload(type: 11);
        final channel =
            await serializer.serialize(payload) as PublicThreadChannel;

        expect(channel.metadata.archived, isFalse);
        expect(channel.metadata.locked, isFalse);
      });

      test('normalize caches thread payload', () async {
        final raw = {
          'id': '300000000000000001',
          'type': 11,
          'name': 'cached-thread',
          'guild_id': '200000000000000001',
          'parent_id': '100000000000000001',
          'position': null,
          'permission_overwrites': [],
          'last_message_id': null,
          'flags': 0,
          'rate_limit_per_user': 0,
          'bitrate': 0,
          'user_limit': 0,
          'rtc_region': null,
          'owner_id': '111000111000111000',
          'thread_metadata': {
            'archived': false,
            'archive_timestamp': null,
            'auto_archive_duration': 60,
            'locked': false,
          },
          'message_count': 0,
          'member_count': 0,
          'total_message_sent': 0,
        };

        await serializer.normalize(raw);

        final cacheKey = FakeMarshaller().cacheKey.channel('300000000000000001');
        expect(cache.store.containsKey(cacheKey), isTrue);
      });

      test('deserialize produces map with expected keys', () async {
        final payload = _threadPayload(type: 11);
        final channel =
            await serializer.serialize(payload) as PublicThreadChannel;
        final result = await serializer.deserialize(channel);

        expect(result['id'], equals('300000000000000001'));
        expect(result['type'], equals(11));
        expect(result['name'], equals('thread-name'));
        expect(result['guild_id'], equals(Snowflake('200000000000000001')));
        expect(result['thread_metadata'], isA<Map>());
        expect(result['thread_metadata']['archived'], isFalse);
      });
    });

    // ── Unknown channel type ─────────────────────────────────────────────

    group('unknown channel type', () {
      test('serialize falls back to unknown factory', () async {
        // Unknown type value — no factory matches except UnknownChannelFactory
        final payload = _textChannelPayload(type: 999);
        // UnknownChannelFactory is the fallback
        final channel = await serializer.serialize(payload);

        expect(channel, isNotNull);
        expect(channel!.type, equals(ChannelType.unknown));
      });
    });

    // ── Channel type dispatch via type field ─────────────────────────────

    group('type-based dispatch', () {
      test('dispatches to GuildTextChannel for type 0', () async {
        final channel = await serializer.serialize(
            _textChannelPayload(id: '1', type: 0));
        expect(channel, isA<GuildTextChannel>());
      });

      test('dispatches to GuildVoiceChannel for type 2', () async {
        final channel = await serializer.serialize(
            _textChannelPayload(id: '2', type: 2));
        expect(channel, isA<GuildVoiceChannel>());
      });

      test('dispatches to GuildCategoryChannel for type 4', () async {
        final channel = await serializer.serialize(
            _textChannelPayload(id: '3', type: 4));
        expect(channel, isA<GuildCategoryChannel>());
      });

      test('dispatches to GuildAnnouncementChannel for type 5', () async {
        final channel = await serializer.serialize(
            _textChannelPayload(id: '4', type: 5));
        expect(channel, isA<GuildAnnouncementChannel>());
      });

      test('dispatches to GuildStageChannel for type 13', () async {
        final channel = await serializer.serialize(
            _textChannelPayload(id: '5', type: 13));
        expect(channel, isA<GuildStageChannel>());
      });
    });
  });
}
