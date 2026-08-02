import 'package:mineral/src/infrastructure/internals/marshaller/cache_key.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/invite_serializer.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/message_reaction_serializer.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/message_serializer.dart';
import 'package:test/test.dart';

import '../../helpers/fake_cache_provider.dart';
import '../../helpers/fake_entity_context.dart';
import '../../helpers/fake_marshaller.dart';

void main() {
  group('MessageSerializer edge cases', () {
    late MessageSerializer serializer;
    late FakeCacheProvider cache;

    setUp(() {
      cache = FakeCacheProvider();
      serializer = MessageSerializer(
        FakeMarshaller(cache: cache),
        fakeEntityContext(),
      );
    });

    group('normalize() with null author (webhook messages)', () {
      test('does not crash when author is null', () async {
        final payload = {
          'id': '111222333',
          'channel_id': '444555666',
          'content': 'webhook message',
          'embeds': <Map<String, dynamic>>[],
          'guild_id': '987654321',
          'author': null,
          'timestamp': '2024-06-01T12:00:00.000Z',
          'edited_timestamp': null,
        };

        final result = await serializer.normalize(payload);

        expect(result['id'], equals('111222333'));
        expect(result['channel_id'], equals('444555666'));
        expect(result['author_id'], isNull);
        expect(result['author_is_bot'], isNull);
      });

      test('still writes to cache when author is null', () async {
        final payload = {
          'id': '111222333',
          'channel_id': '444555666',
          'content': 'webhook message',
          'embeds': <Map<String, dynamic>>[],
          'guild_id': '987654321',
          'author': null,
          'timestamp': '2024-06-01T12:00:00.000Z',
          'edited_timestamp': null,
        };

        await serializer.normalize(payload);

        final expectedKey = CacheKey().message('444555666', '111222333');
        expect(cache.store.containsKey(expectedKey), isTrue);
      });
    });

    group('normalize() with missing embeds field', () {
      test('defaults embeds to empty list when field is absent', () async {
        final payload = {
          'id': '111222333',
          'channel_id': '444555666',
          'content': 'no embeds',
          'guild_id': '987654321',
          'author': {'id': '444555666', 'bot': false},
          'timestamp': '2024-06-01T12:00:00.000Z',
          'edited_timestamp': null,
        };

        final result = await serializer.normalize(payload);

        expect(result['embeds'], isA<List>());
        expect(result['embeds'], isEmpty);
      });

      test('defaults embeds to empty list when field is null', () async {
        final payload = {
          'id': '111222333',
          'channel_id': '444555666',
          'content': 'null embeds',
          'embeds': null,
          'guild_id': '987654321',
          'author': {'id': '444555666', 'bot': false},
          'timestamp': '2024-06-01T12:00:00.000Z',
          'edited_timestamp': null,
        };

        final result = await serializer.normalize(payload);

        expect(result['embeds'], isA<List>());
        expect(result['embeds'], isEmpty);
      });
    });

    group('normalize() with minimal valid payload', () {
      test('does not crash with only id and channel_id', () async {
        final payload = {'id': '111222333', 'channel_id': '444555666'};

        final result = await serializer.normalize(payload);

        expect(result['id'], equals('111222333'));
        expect(result['channel_id'], equals('444555666'));
        expect(result['author_id'], isNull);
        expect(result['author_is_bot'], isNull);
        expect(result['content'], isNull);
        expect(result['guild_id'], isNull);
        expect(result['timestamp'], isNull);
        expect(result['edited_timestamp'], isNull);
      });

      test('defaults embeds to empty list in minimal payload', () async {
        final payload = {'id': '111222333', 'channel_id': '444555666'};

        final result = await serializer.normalize(payload);

        expect(result['embeds'], isA<List>());
        expect(result['embeds'], isEmpty);
      });

      test('writes to cache with minimal payload', () async {
        final payload = {'id': '111222333', 'channel_id': '444555666'};

        await serializer.normalize(payload);

        final expectedKey = CacheKey().message('444555666', '111222333');
        expect(cache.store.containsKey(expectedKey), isTrue);
      });
    });
  });

  group('InviteSerializer edge cases', () {
    late InviteSerializer serializer;
    late FakeCacheProvider cache;

    setUp(() {
      cache = FakeCacheProvider();
      serializer = InviteSerializer(
        FakeMarshaller(cache: cache),
        fakeEntityContext(),
      );
    });

    group('normalize() with null inviter (vanity invites)', () {
      test(
        'does not throw and caches under invites/<code>, not voice_states',
        () async {
          // Fixed by #463: normalize() no longer hard-casts inviter?['id'],
          // and writes to cacheKey.invite(code) instead of
          // cacheKey.voiceState(guildId, inviterId) — so a null inviter
          // (vanity invites) neither throws nor pollutes the voice-state
          // cache namespace.
          final payload = {
            'channel_id': '111222333',
            'code': 'vanity-url',
            'created_at': '2024-06-01T12:00:00.000Z',
            'expires_at': null,
            'guild_id': '987654321',
            'inviter': null,
            'max_age': 0,
            'max_uses': 0,
            'temporary': false,
            'type': 0,
          };

          await serializer.normalize(payload);

          expect(
            cache.store.containsKey(CacheKey().invite('vanity-url')),
            isTrue,
          );
          expect(
            cache.store.keys.where((key) => key.startsWith('voice_states/')),
            isEmpty,
          );
        },
      );
    });

    group('normalize() with missing optional fields', () {
      test('does not throw when inviter is absent', () async {
        // Fixed by #463: same root cause as the null-inviter test above —
        // an absent inviter key must not throw or reach the voice-state
        // namespace.
        final payload = {'code': 'abc123', 'guild_id': '987654321', 'type': 0};

        await serializer.normalize(payload);

        expect(cache.store.containsKey(CacheKey().invite('abc123')), isTrue);
        expect(
          cache.store.keys.where((key) => key.startsWith('voice_states/')),
          isEmpty,
        );
      });

      test('handles null expires_at gracefully', () async {
        final payload = {
          'channel_id': '111222333',
          'code': 'abc123',
          'created_at': '2024-06-01T12:00:00.000Z',
          'expires_at': null,
          'guild_id': '987654321',
          'inviter': {'id': '444555666'},
          'max_age': 0,
          'max_uses': 0,
          'temporary': false,
          'type': 0,
        };

        final result = await serializer.normalize(payload);

        expect(result['expiresAt'], isNull);
      });
    });
  });

  group('MessageReactionSerializer edge cases', () {
    late MessageReactionSerializer serializer;

    setUp(() {
      serializer = MessageReactionSerializer(
        FakeMarshaller(),
        fakeEntityContext(),
      );
    });

    group('serialize() with null emoji field', () {
      test('handles null emoji gracefully with empty name fallback', () async {
        // The serializer handles null emoji by defaulting name to '' and
        // animated to false, so no TypeError is thrown.
        final payload = {
          'guild_id': '987654321',
          'channel_id': '111222333',
          'author_id': '444555666',
          'message_id': '777888999',
          'emoji': null,
          'is_burst': false,
          'type': 0,
        };

        final reaction = await serializer.serialize(payload);

        expect(reaction.emoji.id, isNull);
        expect(reaction.emoji.name, equals(''));
        expect(reaction.emoji.animated, isFalse);
      });

      test('handles emoji with null id (unicode emoji)', () async {
        final payload = {
          'guild_id': '987654321',
          'channel_id': '111222333',
          'author_id': '444555666',
          'message_id': '777888999',
          'emoji': {'id': null, 'name': '\u{1F44D}', 'animated': false},
          'is_burst': false,
          'type': 0,
        };

        final reaction = await serializer.serialize(payload);

        expect(reaction.emoji.id, isNull);
        expect(reaction.emoji.name, equals('\u{1F44D}'));
        expect(reaction.emoji.animated, isFalse);
      });
    });

    group('normalize() with null emoji field', () {
      test('passes null emoji through without crashing', () async {
        final payload = {
          'guild_id': '987654321',
          'channel_id': '111222333',
          'user_id': '444555666',
          'message_id': '777888999',
          'emoji': null,
          'burst': false,
          'type': 0,
        };

        final result = await serializer.normalize(payload);

        expect(result['emoji'], isNull);
      });
    });
  });
}
