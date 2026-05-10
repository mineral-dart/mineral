import 'package:mineral/src/api/common/channel_permission_overwrite.dart';
import 'package:mineral/src/api/common/permission.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/cache_key.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/channel_permission_overwrite_serializer.dart';
import 'package:test/test.dart';

import '../../helpers/fake_cache_provider.dart';
import '../../helpers/fake_marshaller.dart';

void main() {
  group('ChannelPermissionOverwriteSerializer', () {
    late ChannelPermissionOverwriteSerializer serializer;
    late FakeCacheProvider cache;

    setUp(() {
      cache = FakeCacheProvider();
      serializer = ChannelPermissionOverwriteSerializer(
        FakeMarshaller(cache: cache),
      );
    });

    Map<String, dynamic> normalizedPayload() => {
          'id': '123456789',
          'type': 0,
          'allow': '8',
          'deny': '0',
        };

    Map<String, dynamic> rawDiscordPayload() => {
          'id': '123456789',
          'type': 0,
          'allow': '8',
          'deny': '0',
          'server_id': '987654321',
        };

    group('serialize()', () {
      test('maps fields correctly', () {
        final overwrite = serializer.serialize(normalizedPayload());

        expect(overwrite, isA<ChannelPermissionOverwrite>());
        expect(overwrite.id, equals('123456789'));
        expect(overwrite.type, equals(ChannelPermissionOverwriteType.role));
      });

      test('resolves member type for type 1', () {
        final payload = normalizedPayload()..['type'] = 1;
        final overwrite = serializer.serialize(payload);

        expect(overwrite.type, equals(ChannelPermissionOverwriteType.member));
      });

      test('parses allow bitfield from string', () {
        final payload = normalizedPayload()..['allow'] = '8';
        final overwrite = serializer.serialize(payload);

        expect(overwrite.allow, contains(Permission.administrator));
      });

      test('parses deny bitfield from string', () {
        final payload = normalizedPayload()..['deny'] = '2048';
        final overwrite = serializer.serialize(payload);

        expect(overwrite.deny, contains(Permission.sendMessages));
      });

      test('returns empty list for zero bitfield', () {
        final payload = normalizedPayload()..['allow'] = '0';
        final overwrite = serializer.serialize(payload);

        expect(overwrite.allow, isEmpty);
      });
    });

    group('deserialize()', () {
      test('produces map with expected keys', () {
        final overwrite = serializer.serialize(normalizedPayload());
        final result = serializer.deserialize(overwrite);

        expect(result, containsPair('id', '123456789'));
        expect(result,
            containsPair('type', ChannelPermissionOverwriteType.role.value));
      });
    });

    group('normalize()', () {
      test('writes to cache with channelPermission key', () async {
        await serializer.normalize(rawDiscordPayload());

        final expectedKey =
            CacheKey().channelPermission('123456789', serverId: '987654321');
        expect(cache.store.containsKey(expectedKey), isTrue);
      });

      test('preserves all fields', () async {
        final result = await serializer.normalize(rawDiscordPayload());

        expect(result['id'], equals('123456789'));
        expect(result['type'], equals(0));
        expect(result['allow'], equals('8'));
        expect(result['deny'], equals('0'));
      });
    });
  });
}
