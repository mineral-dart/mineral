import 'package:mineral/src/api/common/emoji.dart';
import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/cache_key.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/emoji_serializer.dart';
import 'package:test/test.dart';

import '../../helpers/fake_cache_provider.dart';
import '../../helpers/fake_entity_context.dart';
import '../../helpers/fake_marshaller.dart';
import '../../helpers/serializer_round_trip.dart';

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

    // Mirrors the Discord wire format for an emoji object exactly as Discord
    // sends it (see
    // https://discord.com/developers/docs/resources/emoji#emoji-object).
    // Discord does NOT include `guild_id` here — it is never present on the
    // wire and must be injected by the caller before the payload reaches the
    // serializer. `roles` is an array of bare role-id (snowflake) strings,
    // never role objects. Do not add or reshape fields here to make the
    // serializer happy; if the serializer can't consume this shape, the
    // serializer is wrong, not this fixture.
    Map<String, dynamic> rawDiscordPayload() => {
      'id': '100200300',
      'name': 'thumbsup',
      'roles': ['41771983423143936'],
      'user': {
        'id': '41771983429993937',
        'username': 'Luigi',
        'discriminator': '0002',
        'avatar': null,
      },
      'require_colons': true,
      'managed': false,
      'animated': false,
      'available': true,
    };

    // What a correctly-behaving caller (EmojiPart.create/update,
    // GuildEmojisUpdatePacket) hands to `normalize()`: the genuine Discord
    // payload plus the `guild_id` it injected itself, since normalize() hard-
    // requires that key.
    //
    // This is the serializer's real contract, so it is what every test below
    // exercises. Requiring guild_id is by design — Discord never sends it on
    // an emoji object, and injecting it is the caller's job.
    //
    // Keeping the two fixtures separate is what makes the `roles` defect
    // visible at all: fed the bare `rawDiscordPayload()`, normalize() throws
    // on the missing `guild_id` before it ever reaches the roles mapping, and
    // the second bug is unreachable.
    //
    // The defect where a caller FORGETS to inject guild_id (EmojiPart.fetch/
    // get) is a datastore-part concern; its regression tests belong in
    // test/datastore/parts/emoji_part_test.dart.
    Map<String, dynamic> rawDiscordPayloadWithGuildId() => {
      ...rawDiscordPayload(),
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
        await serializer.normalize(rawDiscordPayloadWithGuildId());

        final expectedKey = CacheKey().guildEmoji('987654321', '100200300');
        expect(cache.store.containsKey(expectedKey), isTrue);
      });

      test('maps the roles array of snowflake strings', () async {
        final result = await serializer.normalize(
          rawDiscordPayloadWithGuildId(),
        );

        expect(result['roles'], isA<List>());
        expect(result['roles'], hasLength(1));
      });

      test('transforms an absent roles array into an empty list', () async {
        final raw = rawDiscordPayloadWithGuildId()..remove('roles');
        final result = await serializer.normalize(raw);

        expect(result['roles'], isA<List>());
        expect(result['roles'], isEmpty);
      });

      test('passes through the guild_id injected by the caller', () async {
        final result = await serializer.normalize(
          rawDiscordPayloadWithGuildId(),
        );

        expect(result, containsPair('guild_id', '987654321'));
      });
    });

    group('round-trip (normalize -> serialize)', () {
      test('preserves fields through the real pipeline', () async {
        // The emoji's `roles` array only ever carries role *ids* on the
        // wire; resolving them into `Emoji.roles` entities depends on the
        // role already being cached under its `guildRole` key (see
        // `serialize() resolves roles from cache` above), same as it would
        // be in production once `guild.roles.fetch()`/GUILD_CREATE has run.
        final roleKey = CacheKey().guildRole('987654321', '41771983423143936');
        cache.store[roleKey] = {
          'id': '41771983423143936',
          'name': 'Muffins',
          'color': 0,
          'hoist': false,
          'position': 1,
          'permissions': '0',
          'managed': false,
          'mentionable': false,
          'flags': 0,
          'guild_id': '987654321',
        };

        await expectRoundTrip<Emoji>(serializer, rawDiscordPayloadWithGuildId(), {
          'Emoji.id': (emoji) =>
              expect(emoji.id, equals(Snowflake('100200300'))),
          'Emoji.name': (emoji) => expect(emoji.name, equals('thumbsup')),
          'Emoji.roles': (emoji) => expect(
            emoji.roles.keys,
            contains(Snowflake('41771983423143936')),
          ),
          'Emoji.animated': (emoji) => expect(emoji.animated, isFalse),
          'Emoji.managed': (emoji) => expect(emoji.managed, isFalse),
          'Emoji.available': (emoji) => expect(emoji.available, isTrue),
        });
      });

      test('round-trips an emoji with an empty roles array', () async {
        final raw = rawDiscordPayloadWithGuildId()..['roles'] = <String>[];

        await expectRoundTrip<Emoji>(serializer, raw, {
          'Emoji.roles': (emoji) => expect(emoji.roles, isEmpty),
        });
      });

      test('round-trips an emoji when roles is absent entirely', () async {
        // Discord omits `roles` on some emoji payloads entirely (as opposed
        // to sending an empty array); the serializer must not hard-cast it.
        await expectRoundTripWithoutOptionals<Emoji>(
          serializer,
          rawDiscordPayloadWithGuildId(),
          {'roles'},
        );
      });
    });
  });
}
