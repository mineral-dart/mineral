import 'package:mineral/src/api/common/permissions.dart';
import 'package:mineral/src/api/common/premium_tier.dart';
import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/api/guild/member.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/cache_key.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/member_serializer.dart';
import 'package:test/test.dart';

import '../../helpers/fake_cache_provider.dart';
import '../../helpers/fake_entity_context.dart';
import '../../helpers/fake_marshaller.dart';

void main() {
  group('MemberSerializer', () {
    late MemberSerializer serializer;
    late FakeCacheProvider cache;

    setUp(() {
      cache = FakeCacheProvider();
      serializer = MemberSerializer(
        FakeMarshaller(cache: cache),
        fakeEntityContext(),
      );
    });

    Map<String, dynamic> normalizedPayload() => {
      'id': '444555666',
      'username': 'testuser',
      'nick': null,
      'global_name': 'TestUser',
      'discriminator': '0',
      'assets': {
        'guild_id': '987654321',
        'member_id': '444555666',
        'avatar': null,
        'avatar_decoration': null,
        'banner': null,
      },
      'flags': 0,
      'roles': ['111222333'],
      'premium_since': null,
      'public_flags': 64,
      'is_bot': false,
      'is_pending': false,
      'timeout': null,
      'mfa_enabled': false,
      'locale': 'en-US',
      'premium_type': null,
      'joined_at': '2024-01-15T10:30:00.000Z',
      'permissions': '8',
      'accent_color': null,
      'guild_id': '987654321',
    };

    Map<String, dynamic> rawDiscordPayload() => {
      'user': {
        'id': '444555666',
        'username': 'testuser',
        'global_name': 'TestUser',
        'discriminator': '0',
        'avatar': null,
        'avatar_decoration_data': null,
        'public_flags': 64,
        'bot': false,
        'mfa_enabled': false,
        'locale': 'en-US',
        'premium_type': null,
      },
      'nick': null,
      'banner': null,
      'flags': 0,
      'roles': ['111222333'],
      'premium_since': null,
      'pending': false,
      'communication_disabled_until': null,
      'joined_at': '2024-01-15T10:30:00.000Z',
      'permissions': '8',
      'accent_color': null,
      'guild_id': '987654321',
    };

    group('serialize()', () {
      test('maps all scalar fields correctly', () async {
        final member = await serializer.serialize(normalizedPayload());

        expect(member, isA<Member>());
        expect(member.id, equals(Snowflake('444555666')));
        expect(member.username, equals('testuser'));
        expect(member.globalName, equals('TestUser'));
        expect(member.discriminator, equals('0'));
        expect(member.isBot, isFalse);
        expect(member.isPending, isFalse);
        expect(member.mfaEnabled, isFalse);
        expect(member.locale, equals('en-US'));
        expect(member.publicFlags, equals(64));
        expect(member.guildId, equals(Snowflake('987654321')));
      });

      test('parses permissions from String', () async {
        final member = await serializer.serialize(normalizedPayload());

        expect(member.permissions, isA<Permissions>());
        expect(member.permissions.raw, equals(8));
      });

      test('defaults permissions to 0 when null', () async {
        final payload = normalizedPayload()..['permissions'] = null;
        final member = await serializer.serialize(payload);

        expect(member.permissions.raw, equals(0));
      });

      test('builds MemberRoleManager with role IDs', () async {
        final member = await serializer.serialize(normalizedPayload());

        expect(member.roles.currentIds, hasLength(1));
        expect(member.roles.currentIds.first, equals(Snowflake('111222333')));
      });

      test('handles null timeout', () async {
        final member = await serializer.serialize(normalizedPayload());

        expect(member.timeout.isTimeout, isFalse);
        expect(member.timeout.duration, isNull);
      });

      test('parses joinedAt datetime', () async {
        final member = await serializer.serialize(normalizedPayload());

        expect(member.joinedAt, isA<DateTime>());
        expect(
          member.joinedAt,
          equals(DateTime.parse('2024-01-15T10:30:00.000Z')),
        );
      });

      test('defaults premiumType to none when null', () async {
        final member = await serializer.serialize(normalizedPayload());

        expect(member.premiumType, equals(PremiumTier.none));
      });

      test('builds MemberAssets with null values when absent', () async {
        final member = await serializer.serialize(normalizedPayload());

        expect(member.assets.avatar, isNull);
        expect(member.assets.avatarDecoration, isNull);
        expect(member.assets.banner, isNull);
      });
    });

    group('deserialize()', () {
      test('produces map with expected keys', () async {
        final member = await serializer.serialize(normalizedPayload());
        final result = await serializer.deserialize(member);

        expect(result['id'], equals('444555666'));
        expect(result['username'], equals('testuser'));
        expect(result['is_bot'], isFalse);
        expect(result['is_pending'], isFalse);
        expect(result['locale'], equals('en-US'));
        expect(result['guild_id'], equals('987654321'));
      });

      test('roles are serialized as list of Snowflake values', () async {
        final member = await serializer.serialize(normalizedPayload());
        final result = await serializer.deserialize(member);

        expect(result['roles'], isA<List>());
        expect(result['roles'], contains('111222333'));
      });
    });

    group('normalize()', () {
      test('writes to cache with member key', () async {
        await serializer.normalize(rawDiscordPayload());

        final expectedKey = CacheKey().member('987654321', '444555666');
        expect(cache.store.containsKey(expectedKey), isTrue);
      });

      test('extracts user fields from nested user object', () async {
        final result = await serializer.normalize(rawDiscordPayload());

        expect(result['id'], equals('444555666'));
        expect(result['username'], equals('testuser'));
        expect(result['global_name'], equals('TestUser'));
        expect(result['discriminator'], equals('0'));
        expect(result['is_bot'], isFalse);
      });

      test('renames guild_id to guild_id', () async {
        final result = await serializer.normalize(rawDiscordPayload());

        expect(result, containsPair('guild_id', '987654321'));
      });

      test('builds assets sub-map', () async {
        final result = await serializer.normalize(rawDiscordPayload());

        expect(result['assets'], isA<Map>());
        expect(result['assets']['guild_id'], equals('987654321'));
        expect(result['assets']['member_id'], equals('444555666'));
      });

      test('renames nick to nickname field', () async {
        final result = await serializer.normalize(rawDiscordPayload());

        expect(result, containsPair('nickname', null));
      });

      test('preserves roles list', () async {
        final result = await serializer.normalize(rawDiscordPayload());

        expect(result['roles'], isA<List>());
        expect(result['roles'], contains('111222333'));
      });
    });

    group('round-trip', () {
      test('serialize then deserialize preserves key data', () async {
        final json = normalizedPayload();
        final member = await serializer.serialize(json);
        final result = await serializer.deserialize(member);

        expect(result['username'], equals('testuser'));
        expect(result['is_bot'], equals(json['is_bot']));
        expect(result['locale'], equals(json['locale']));
        expect(result['guild_id'], equals(Snowflake('987654321').value));
      });
    });
  });
}
