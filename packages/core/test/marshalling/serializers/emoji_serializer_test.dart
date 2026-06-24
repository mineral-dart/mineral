import 'package:mineral/src/api/common/emoji.dart';
import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/cache_key.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/emoji_serializer.dart';
import 'package:test/test.dart';

import '../../helpers/fake_cache_provider.dart';
import '../../helpers/fake_entity_context.dart';
import '../../helpers/fake_marshaller.dart';

void main() {
  group('EmojiSerializer', () {
    late EmojiSerializer serializer;
    late FakeCacheProvider cache;

    setUp(() {
      cache = FakeCacheProvider();
      serializer = EmojiSerializer(
        FakeMarshaller(cache: cache),
        fakeEntityContext(),
      );
    });

    Map<String, dynamic> normalizedPayloadWithoutRoles() => {
      'id': '100200300',
      'name': 'thumbsup',
      'managed': false,
      'available': true,
      'animated': false,
      'roles': <String>[],
      'guild_id': '987654321',
    };

    Map<String, dynamic> rawDiscordPayload() => {
      'id': '100200300',
      'name': 'thumbsup',
      'managed': false,
      'available': true,
      'animated': false,
      'roles': null,
      'guild_id': '987654321',
    };

    group('serialize()', () {
      test('creates Emoji without roles when roles is empty', () async {
        final emoji = await serializer.serialize(
          normalizedPayloadWithoutRoles(),
        );

        expect(emoji, isA<Emoji>());
        expect(emoji.id, equals(Snowflake('100200300')));
        expect(emoji.name, equals('thumbsup'));
        expect(emoji.managed, isFalse);
        expect(emoji.available, isTrue);
        expect(emoji.animated, isFalse);
        expect(emoji.roles, isEmpty);
        expect(emoji.guildId, equals(Snowflake('987654321')));
      });

      test('resolves roles from cache', () async {
        final roleKey = CacheKey().guildRole('987654321', '111111111');
        cache.store[roleKey] = {
          'id': '111111111',
          'name': 'Moderator',
          'color': 0,
          'hoist': false,
          'position': 1,
          'permissions': '0',
          'managed': false,
          'mentionable': false,
          'flags': 0,
          'guild_id': '987654321',
        };

        final payload = normalizedPayloadWithoutRoles()..['roles'] = [roleKey];
        final emoji = await serializer.serialize(payload);

        expect(emoji.roles, hasLength(1));
        expect(emoji.roles.values.first.name, equals('Moderator'));
      });
    });

    group('deserialize()', () {
      test('produces map with expected keys', () async {
        final emoji = await serializer.serialize(
          normalizedPayloadWithoutRoles(),
        );
        final result = serializer.deserialize(emoji);

        expect(result['id'], equals(Snowflake('100200300').value));
        expect(result['name'], equals('thumbsup'));
        expect(result['managed'], isFalse);
        expect(result['available'], isTrue);
        expect(result['animated'], isFalse);
        expect(result['roles'], isEmpty);
        expect(result['guild_id'], equals(Snowflake('987654321').value));
      });
    });

    group('normalize()', () {
      test('writes to cache with guildEmoji key', () async {
        await serializer.normalize(rawDiscordPayload());

        final expectedKey = CacheKey().guildEmoji('987654321', '100200300');
        expect(cache.store.containsKey(expectedKey), isTrue);
      });

      test('transforms null roles into empty list', () async {
        final result = await serializer.normalize(rawDiscordPayload());

        expect(result['roles'], isA<List>());
        expect(result['roles'], isEmpty);
      });

      test('renames guild_id to guild_id', () async {
        final result = await serializer.normalize(rawDiscordPayload());

        expect(result, containsPair('guild_id', '987654321'));
      });
    });
  });
}
