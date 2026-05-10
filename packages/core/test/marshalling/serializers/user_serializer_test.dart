import 'package:mineral/src/api/common/premium_tier.dart';
import 'package:mineral/src/api/private/user.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/cache_key.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/user_serializer.dart';
import 'package:test/test.dart';

import '../../helpers/fake_cache_provider.dart';
import '../../helpers/fake_entity_context.dart';
import '../../helpers/fake_marshaller.dart';

void main() {
  group('UserSerializer', () {
    late UserSerializer serializer;
    late FakeCacheProvider cache;

    setUp(() {
      cache = FakeCacheProvider();
      serializer = UserSerializer(
        FakeMarshaller(cache: cache),
        fakeEntityContext(),
      );
    });

    Map<String, dynamic> normalizedPayload() => {
          'id': '444555666',
          'username': 'testuser',
          'discriminator': '1234',
          'flags': 64,
          'public_flags': 64,
          'avatar': 'abc123hash',
          'is_bot': false,
          'system': false,
          'mfa_enabled': true,
          'locale': 'en-US',
          'verified': true,
          'email': 'test@example.com',
          'premium_type': null,
          'assets': {
            'user_id': '444555666',
            'avatar': 'abc123hash',
            'avatar_decoration': null,
            'banner': null,
          },
        };

    Map<String, dynamic> rawDiscordPayload() => {
          'id': '444555666',
          'username': 'testuser',
          'discriminator': '1234',
          'flags': 64,
          'public_flags': 64,
          'avatar': 'abc123hash',
          'bot': false,
          'system': false,
          'mfa_enabled': true,
          'locale': 'en-US',
          'verified': true,
          'email': 'test@example.com',
          'premium_type': null,
          'avatar_decoration_data': null,
          'banner': null,
        };

    group('serialize()', () {
      test('maps all scalar fields correctly', () async {
        final user = await serializer.serialize(normalizedPayload());

        expect(user, isA<User>());
        expect(user.id, equals('444555666'));
        expect(user.username, equals('testuser'));
        expect(user.discriminator, equals('1234'));
        expect(user.flags, equals(64));
        expect(user.publicFlags, equals(64));
        expect(user.avatar, equals('abc123hash'));
        expect(user.bot, isFalse);
        expect(user.system, isFalse);
        expect(user.mfaEnabled, isTrue);
        expect(user.locale, equals('en-US'));
        expect(user.verified, isTrue);
        expect(user.email, equals('test@example.com'));
      });

      test('defaults premiumType to none when null', () async {
        final user = await serializer.serialize(normalizedPayload());

        expect(user.premiumType, equals(PremiumTier.none));
      });

      test('builds UserAssets with avatar when present', () async {
        final user = await serializer.serialize(normalizedPayload());

        expect(user.assets.avatar, isNotNull);
      });

      test('builds UserAssets with null avatarDecoration when absent',
          () async {
        final user = await serializer.serialize(normalizedPayload());

        expect(user.assets.avatarDecoration, isNull);
      });

      test('builds UserAssets with null banner when absent', () async {
        final user = await serializer.serialize(normalizedPayload());

        expect(user.assets.banner, isNull);
      });
    });

    group('deserialize()', () {
      test('produces map with expected keys', () async {
        final user = await serializer.serialize(normalizedPayload());
        final result = serializer.deserialize(user);

        expect(result['id'], equals('444555666'));
        expect(result['username'], equals('testuser'));
        expect(result['discriminator'], equals('1234'));
        expect(result['flags'], equals(64));
        expect(result['public_flags'], equals(64));
        expect(result['avatar'], equals('abc123hash'));
        expect(result['is_bot'], isFalse);
        expect(result['system'], isFalse);
        expect(result['mfa_enabled'], isTrue);
        expect(result['locale'], equals('en-US'));
        expect(result['verified'], isTrue);
        expect(result['email'], equals('test@example.com'));
      });

      test('assets sub-map contains avatar hash', () async {
        final user = await serializer.serialize(normalizedPayload());
        final result = serializer.deserialize(user);

        expect(result['assets'], isA<Map>());
        expect(result['assets']['avatar'], equals('abc123hash'));
        expect(result['assets']['avatar_decoration'], isNull);
        expect(result['assets']['banner'], isNull);
      });
    });

    group('normalize()', () {
      test('writes to cache with user key', () async {
        await serializer.normalize(rawDiscordPayload());

        final expectedKey = CacheKey().user('444555666');
        expect(cache.store.containsKey(expectedKey), isTrue);
      });

      test('renames bot to is_bot', () async {
        final result = await serializer.normalize(rawDiscordPayload());

        expect(result, containsPair('is_bot', false));
        expect(result.containsKey('bot'), isFalse);
      });

      test('builds assets sub-map', () async {
        final result = await serializer.normalize(rawDiscordPayload());

        expect(result['assets'], isA<Map>());
        expect(result['assets']['avatar'], equals('abc123hash'));
      });
    });

    group('round-trip', () {
      test('serialize then deserialize preserves key data', () async {
        final json = normalizedPayload();
        final user = await serializer.serialize(json);
        final result = serializer.deserialize(user);

        expect(result['username'], equals(json['username']));
        expect(result['discriminator'], equals(json['discriminator']));
        expect(result['flags'], equals(json['flags']));
        expect(result['is_bot'], equals(json['is_bot']));
        expect(result['locale'], equals(json['locale']));
      });
    });
  });
}
