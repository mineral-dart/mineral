import 'package:mineral/src/api/common/permission.dart';
import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/api/guild/role.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/cache_key.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/role_serializer.dart';
import 'package:test/test.dart';

import '../../helpers/fake_cache_provider.dart';
import '../../helpers/fake_entity_context.dart';
import '../../helpers/fake_marshaller.dart';
import '../../helpers/serializer_round_trip.dart';

void main() {
  group('RoleSerializer', () {
    late RoleSerializer serializer;
    late FakeCacheProvider cache;

    setUp(() {
      cache = FakeCacheProvider();
      serializer = RoleSerializer(
        FakeMarshaller(cache: cache),
        fakeEntityContext(),
      );
    });

    Map<String, dynamic> normalizedPayload() => {
      'id': '123456789',
      'name': 'Admin',
      'color': 16711680,
      'hoist': true,
      'position': 3,
      'permissions': '8',
      'managed': false,
      'mentionable': true,
      'flags': 0,
      'guild_id': '987654321',
    };

    // Mirrors the Discord wire format for a role object exactly as Discord
    // sends it (see
    // https://discord.com/developers/docs/topics/permissions#role-object).
    // Discord does NOT include `guild_id` on a role object — it is never
    // present on the wire and must be injected by the caller before the
    // payload reaches the serializer. Do not add fields here to make the
    // serializer happy; if the serializer can't consume this shape, the
    // serializer is wrong, not this fixture.
    Map<String, dynamic> rawDiscordPayload() => {
      'id': '123456789',
      'name': 'Admin',
      'color': 16711680,
      'hoist': true,
      'icon': null,
      'unicode_emoji': null,
      'position': 3,
      'permissions': '8',
      'managed': false,
      'mentionable': true,
      'tags': <String, dynamic>{},
      'flags': 0,
    };

    // What a correctly-behaving caller (e.g. RolePart.fetch,
    // GuildRoleCreatePacket) hands to `normalize()`: the genuine Discord
    // payload plus a `guild_id` it injected itself, since normalize() hard-
    // requires that key. Used by tests below that exercise normalize()'s own
    // logic rather than the guild_id-injection concern, which is covered by
    // the round-trip group.
    Map<String, dynamic> rawDiscordPayloadWithGuildId() => {
      ...rawDiscordPayload(),
      'guild_id': '987654321',
    };

    group('serialize()', () {
      test('maps all scalar fields correctly', () async {
        final role = await serializer.serialize(normalizedPayload());

        expect(role, isA<Role>());
        expect(role.id, equals(Snowflake('123456789')));
        expect(role.name, equals('Admin'));
        expect(role.color.toInt(), equals(16711680));
        expect(role.hoist, isTrue);
        expect(role.position, equals(3));
        expect(role.managed, isFalse);
        expect(role.mentionable, isTrue);
        expect(role.flags, equals(0));
        expect(role.guildId, equals(Snowflake('987654321')));
      });

      test('parses permissions from String', () async {
        final payload = normalizedPayload()..['permissions'] = '8';
        final role = await serializer.serialize(payload);

        expect(role.permissions.raw, equals(8));
        expect(role.permissions.has(Permission.administrator), isTrue);
      });

      test('parses permissions from int', () async {
        final payload = normalizedPayload()..['permissions'] = 8;
        final role = await serializer.serialize(payload);

        expect(role.permissions.raw, equals(8));
        expect(role.permissions.has(Permission.administrator), isTrue);
      });

      test('defaults permissions to 0 when null', () async {
        final payload = normalizedPayload()..['permissions'] = null;
        final role = await serializer.serialize(payload);

        expect(role.permissions.raw, equals(0));
      });

      test('defaults color to 0 when null', () async {
        final payload = normalizedPayload()..['color'] = null;
        final role = await serializer.serialize(payload);

        expect(role.color.toInt(), equals(0));
      });

      test('defaults hoist to false when null', () async {
        final payload = normalizedPayload()..['hoist'] = null;
        final role = await serializer.serialize(payload);

        expect(role.hoist, isFalse);
      });

      test('defaults position to 0 when null', () async {
        final payload = normalizedPayload()..['position'] = null;
        final role = await serializer.serialize(payload);

        expect(role.position, equals(0));
      });
    });

    group('deserialize()', () {
      test('produces map with expected keys', () async {
        final role = await serializer.serialize(normalizedPayload());
        final result = serializer.deserialize(role);

        expect(result, containsPair('id', Snowflake('123456789')));
        expect(result, containsPair('name', 'Admin'));
        expect(result, containsPair('hoist', true));
        expect(result, containsPair('managed', false));
        expect(result, containsPair('mentionable', true));
        expect(result, containsPair('flags', 0));
      });

      test('color is serialized as int', () async {
        final role = await serializer.serialize(normalizedPayload());
        final result = serializer.deserialize(role);

        expect(result['color'], isA<int>());
        expect(result['color'], equals(16711680));
      });

      test('permissions is the recalculated bitfield', () async {
        final role = await serializer.serialize(normalizedPayload());
        final result = serializer.deserialize(role);

        expect(result['permissions'], isA<int>());
      });
    });

    group('normalize()', () {
      test('writes to cache with guildRole key', () async {
        await serializer.normalize(rawDiscordPayloadWithGuildId());

        final expectedKey = CacheKey().guildRole('987654321', '123456789');
        expect(cache.store.containsKey(expectedKey), isTrue);
      });

      test('passes through the guild_id injected by the caller', () async {
        final result = await serializer.normalize(
          rawDiscordPayloadWithGuildId(),
        );

        expect(result, containsPair('guild_id', '987654321'));
      });

      test('preserves all fields in cached payload', () async {
        final result = await serializer.normalize(
          rawDiscordPayloadWithGuildId(),
        );

        expect(result['id'], equals('123456789'));
        expect(result['name'], equals('Admin'));
        expect(result['color'], equals(16711680));
        expect(result['hoist'], isTrue);
        expect(result['position'], equals(3));
        expect(result['permissions'], equals('8'));
        expect(result['managed'], isFalse);
        expect(result['mentionable'], isTrue);
        expect(result['flags'], equals(0));
      });
    });

    group('round-trip', () {
      test('serialize then deserialize preserves key data', () async {
        final json = normalizedPayload();
        final role = await serializer.serialize(json);
        final result = serializer.deserialize(role);

        expect(result['id'], equals(Snowflake('123456789')));
        expect(result['name'], equals('Admin'));
        expect(result['hoist'], equals(json['hoist']));
        expect(result['managed'], equals(json['managed']));
        expect(result['mentionable'], equals(json['mentionable']));
        expect(result['flags'], equals(json['flags']));
        expect(result['color'], equals(json['color']));
      });
    });

    group('round-trip (normalize -> serialize)', () {
      test('preserves fields through the real pipeline', () async {
        await expectRoundTrip<Role>(serializer, rawDiscordPayload(), {
          'Role.id': (role) => expect(role.id, equals(Snowflake('123456789'))),
          'Role.name': (role) => expect(role.name, equals('Admin')),
          'Role.color': (role) => expect(role.color.toInt(), equals(16711680)),
          'Role.hoist': (role) => expect(role.hoist, isTrue),
          'Role.position': (role) => expect(role.position, equals(3)),
          'Role.permissions': (role) => expect(role.permissions.raw, equals(8)),
          'Role.managed': (role) => expect(role.managed, isFalse),
          'Role.mentionable': (role) => expect(role.mentionable, isTrue),
          'Role.flags': (role) => expect(role.flags, equals(0)),
          'Role.guildId': (role) =>
              expect(role.guildId, equals(Snowflake('987654321'))),
        });
      });
    });
  });
}
