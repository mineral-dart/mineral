import 'package:mineral/src/api/common/message.dart';
import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/cache_key.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/message_serializer.dart';
import 'package:test/test.dart';

import '../../helpers/fake_cache_provider.dart';
import '../../helpers/fake_entity_context.dart';
import '../../helpers/fake_marshaller.dart';

void main() {
  group('MessageSerializer', () {
    late MessageSerializer serializer;
    late FakeCacheProvider cache;

    setUp(() {
      cache = FakeCacheProvider();
      serializer = MessageSerializer(
        FakeMarshaller(cache: cache),
        fakeEntityContext(),
      );
    });

    Map<String, dynamic> normalizedPayload() => {
      'id': '777888999',
      'author_id': '444555666',
      'content': 'Hello world!',
      'embeds': <Map<String, dynamic>>[],
      'channel_id': '111222333',
      'guild_id': '987654321',
      'author_is_bot': false,
      'timestamp': '2024-01-15T10:30:00.000Z',
      'edited_timestamp': null,
    };

    Map<String, dynamic> rawDiscordPayload() => {
      'id': '777888999',
      'author': {'id': '444555666', 'bot': false},
      'content': 'Hello world!',
      'embeds': <Map<String, dynamic>>[],
      'channel_id': '111222333',
      'guild_id': '987654321',
      'timestamp': '2024-01-15T10:30:00.000Z',
      'edited_timestamp': null,
    };

    group('serialize()', () {
      test('maps all fields correctly', () async {
        final message = await serializer.serialize(normalizedPayload());

        expect(message, isA<Message>());
        expect(message.id, equals(Snowflake('777888999')));
        expect(message.content, equals('Hello world!'));
        expect(message.channelId, equals(Snowflake('111222333')));
        expect(message.authorId, equals(Snowflake('444555666')));
        expect(message.authorIsBot, isFalse);
        expect(message.embeds, isEmpty);
      });

      test('parses createdAt timestamp', () async {
        final message = await serializer.serialize(normalizedPayload());

        expect(message.createdAt, isA<DateTime>());
        expect(
          message.createdAt,
          equals(DateTime.parse('2024-01-15T10:30:00.000Z')),
        );
      });

      test('handles null edited_timestamp', () async {
        final message = await serializer.serialize(normalizedPayload());

        expect(message.updatedAt, isNull);
      });

      test('handles nullable guild_id', () async {
        final payload = normalizedPayload()..['guild_id'] = null;
        final message = await serializer.serialize(payload);

        expect(message, isA<Message>());
      });

      test('handles nullable author_id', () async {
        final payload = normalizedPayload()..['author_id'] = null;
        final message = await serializer.serialize(payload);

        expect(message.authorId, isNull);
      });

      test('serializes embeds when present', () async {
        final payload = normalizedPayload()
          ..['embeds'] = [
            {
              'title': 'Test',
              'description': 'desc',
              'type': null,
              'url': null,
              'timestamp': null,
              'assets': null,
              'provider': null,
              'fields': null,
              'color': null,
            },
          ];
        final message = await serializer.serialize(payload);

        expect(message.embeds, hasLength(1));
        expect(message.embeds.first.title, equals('Test'));
      });
    });

    group('deserialize()', () {
      test('produces map with expected keys', () async {
        final message = await serializer.serialize(normalizedPayload());
        final result = await serializer.deserialize(message);

        expect(result['id'], equals('777888999'));
        expect(result['content'], equals('Hello world!'));
        expect(result['channel_id'], equals('111222333'));
        expect(result['author_id'], equals('444555666'));
        expect(result['guild_id'], equals('987654321'));
        expect(result['author_is_bot'], isFalse);
      });

      test('embeds are serialized as list of maps', () async {
        final message = await serializer.serialize(normalizedPayload());
        final result = await serializer.deserialize(message);

        expect(result['embeds'], isA<List>());
      });
    });

    group('normalize()', () {
      test('writes to cache with message key', () async {
        await serializer.normalize(rawDiscordPayload());

        final expectedKey = CacheKey().message('111222333', '777888999');
        expect(cache.store.containsKey(expectedKey), isTrue);
      });

      test('extracts author_id from nested author object', () async {
        final result = await serializer.normalize(rawDiscordPayload());

        expect(result['author_id'], equals('444555666'));
      });

      test('extracts author_is_bot from nested author object', () async {
        final result = await serializer.normalize(rawDiscordPayload());

        expect(result['author_is_bot'], isFalse);
      });

      test('renames guild_id to guild_id', () async {
        final result = await serializer.normalize(rawDiscordPayload());

        expect(result, containsPair('guild_id', '987654321'));
      });
    });

    group('round-trip', () {
      test('serialize then deserialize preserves key data', () async {
        final json = normalizedPayload();
        final message = await serializer.serialize(json);
        final result = await serializer.deserialize(message);

        expect(result['id'], equals(json['id']));
        expect(result['content'], equals(json['content']));
        expect(result['channel_id'], equals(json['channel_id']));
        expect(result['author_id'], equals(json['author_id']));
        expect(result['author_is_bot'], equals(json['author_is_bot']));
      });
    });
  });
}
