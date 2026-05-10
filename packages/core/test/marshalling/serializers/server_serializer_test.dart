import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/api/server/server.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/cache_key.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/server_serializer.dart';
import 'package:test/test.dart';

import '../../helpers/fake_cache_provider.dart';
import '../../helpers/fake_entity_context.dart';
import '../../helpers/fake_marshaller.dart';

void main() {
  group('ServerSerializer', () {
    late ServerSerializer serializer;
    late FakeCacheProvider cache;

    setUp(() {
      cache = FakeCacheProvider();
      serializer = ServerSerializer(
        FakeMarshaller(cache: cache),
        fakeEntityContext(),
      );
    });

    Map<String, dynamic> normalizedPayload() => {
          'id': '987654321',
          'name': 'Test Server',
          'description': 'A test server',
          'application_id': null,
          'owner_id': '444555666',
          'icon': null,
          'splash': null,
          'banner': null,
          'discovery_splash': null,
          'permissions': null,
          'afk_timeout': 300,
          'widget_enabled': false,
          'vanity_url_code': null,
          'max_video_channel_users': 25,
          'settings': {
            'explicit_content_filter': 0,
            'verification_level': 1,
            'default_message_notifications': 0,
            'features': ['COMMUNITY'],
            'mfa_level': 0,
            'system_channel_flags': 0,
            'premium_tier': 0,
            'premium_subscription_count': 0,
            'premium_progress_bar_enabled': false,
            'preferred_locale': 'en-US',
            'nsfw_level': 0,
          },
          'channel_settings': {
            'afk_channel_id': null,
            'system_channel_id': '111222333',
            'rules_channel_id': null,
            'public_updates_channel_id': null,
            'safety_alerts_channel_id': null,
          },
        };

    Map<String, dynamic> rawDiscordPayload() => {
          'id': '987654321',
          'name': 'Test Server',
          'description': 'A test server',
          'application_id': null,
          'owner_id': '444555666',
          'icon': null,
          'icon_hash': null,
          'splash': null,
          'discovery_splash': null,
          'banner': null,
          'permissions': null,
          'afk_timeout': 300,
          'widget_enabled': false,
          'explicit_content_filter': 0,
          'verification_level': 1,
          'default_message_notifications': 0,
          'features': ['COMMUNITY'],
          'mfa_level': 0,
          'system_channel_flags': 0,
          'vanity_url_code': null,
          'premium_tier': 0,
          'premium_subscription_count': 0,
          'premium_progress_bar_enabled': false,
          'preferred_locale': 'en-US',
          'max_video_channel_users': 25,
          'nsfw_level': 0,
          'afk_channel_id': null,
          'system_channel_id': '111222333',
          'rules_channel_id': null,
          'public_updates_channel_id': null,
          'safety_alerts_channel_id': null,
        };

    group('serialize()', () {
      test('maps scalar fields correctly', () async {
        final server = await serializer.serialize(normalizedPayload());

        expect(server, isA<Server>());
        expect(server.id, equals(Snowflake('987654321')));
        expect(server.name, equals('Test Server'));
        expect(server.description, equals('A test server'));
        expect(server.ownerId, equals(Snowflake('444555666')));
      });

      test('builds ServerSettings with enums', () async {
        final server = await serializer.serialize(normalizedPayload());

        expect(server.settings.features, contains('COMMUNITY'));
        expect(server.settings.preferredLocale, equals('en-US'));
      });

      test('builds ChannelManager from channel_settings', () async {
        final server = await serializer.serialize(normalizedPayload());

        expect(server.channels.systemChannelId, equals(Snowflake('111222333')));
        expect(server.channels.afkChannelId, isNull);
        expect(server.channels.rulesChannelId, isNull);
      });
    });

    group('deserialize()', () {
      test('produces map with expected top-level keys', () async {
        final server = await serializer.serialize(normalizedPayload());
        final result = await serializer.deserialize(server);

        expect(result['id'], equals(Snowflake('987654321')));
        expect(result['name'], equals('Test Server'));
        expect(result['description'], equals('A test server'));
        expect(result['owner_id'], equals(Snowflake('444555666')));
      });

      test('produces settings sub-map', () async {
        final server = await serializer.serialize(normalizedPayload());
        final result = await serializer.deserialize(server);

        expect(result['settings'], isA<Map>());
        expect(result['settings']['features'], contains('COMMUNITY'));
        expect(result['settings']['preferred_locale'], equals('en-US'));
      });

      test('produces channel_settings sub-map', () async {
        final server = await serializer.serialize(normalizedPayload());
        final result = await serializer.deserialize(server);

        expect(result['channel_settings'], isA<Map>());
        expect(result['channel_settings']['system_channel_id'],
            equals('111222333'));
      });

      test('produces assets sub-map', () async {
        final server = await serializer.serialize(normalizedPayload());
        final result = await serializer.deserialize(server);

        expect(result['assets'], isA<Map>());
      });
    });

    group('normalize()', () {
      test('writes to cache with server key', () async {
        await serializer.normalize(rawDiscordPayload());

        final expectedKey = CacheKey().server('987654321');
        expect(cache.store.containsKey(expectedKey), isTrue);
      });

      test('groups settings into sub-map', () async {
        final result = await serializer.normalize(rawDiscordPayload());

        expect(result['settings'], isA<Map>());
        expect(result['settings']['explicit_content_filter'], equals(0));
        expect(result['settings']['verification_level'], equals(1));
        expect(result['settings']['features'], contains('COMMUNITY'));
      });

      test('groups channel_settings into sub-map', () async {
        final result = await serializer.normalize(rawDiscordPayload());

        expect(result['channel_settings'], isA<Map>());
        expect(result['channel_settings']['system_channel_id'],
            equals('111222333'));
      });

      test('groups assets into sub-map', () async {
        final result = await serializer.normalize(rawDiscordPayload());

        expect(result['assets'], isA<Map>());
        expect(result['assets']['icon'], isNull);
      });
    });

    group('round-trip', () {
      test('serialize then deserialize preserves key data', () async {
        final json = normalizedPayload();
        final server = await serializer.serialize(json);
        final result = await serializer.deserialize(server);

        expect(result['name'], equals(json['name']));
        expect(result['description'], equals(json['description']));
      });
    });
  });
}
