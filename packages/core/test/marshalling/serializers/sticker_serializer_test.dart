import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/api/common/sticker.dart';
import 'package:mineral/src/api/common/types/format_type.dart';
import 'package:mineral/src/api/common/types/sticker_type.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/cache_key.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/sticker_serializer.dart';
import 'package:test/test.dart';

import '../../helpers/fake_cache_provider.dart';
import '../../helpers/fake_entity_context.dart';
import '../../helpers/fake_marshaller.dart';

void main() {
  group('StickerSerializer', () {
    late StickerSerializer serializer;
    late FakeCacheProvider cache;

    setUp(() {
      cache = FakeCacheProvider();
      serializer = StickerSerializer(
        FakeMarshaller(cache: cache),
        fakeEntityContext(),
      );
    });

    Map<String, dynamic> normalizedPayload() => {
          'id': '111222333',
          'name': 'cool_sticker',
          'type': 2,
          'available': true,
          'pack_id': 'pack_001',
          'description': 'A cool sticker',
          'tags': 'cool,fun',
          'asset': null,
          'format_type': 1,
          'sort_value': 5,
          'server_id': '987654321',
        };

    Map<String, dynamic> rawDiscordPayload() => {
          'id': '111222333',
          'name': 'cool_sticker',
          'type': 2,
          'available': true,
          'pack_id': 'pack_001',
          'description': 'A cool sticker',
          'tags': 'cool,fun',
          'asset': null,
          'format_type': 1,
          'sort_value': 5,
          'guild_id': '987654321',
        };

    group('serialize()', () {
      test('maps all fields correctly', () {
        final sticker = serializer.serialize(normalizedPayload());

        expect(sticker, isA<Sticker>());
        expect(sticker.id, equals(Snowflake('111222333')));
        expect(sticker.name, equals('cool_sticker'));
        expect(sticker.type, equals(StickerType.guild));
        expect(sticker.isAvailable, isTrue);
        expect(sticker.packId, equals('pack_001'));
        expect(sticker.description, equals('A cool sticker'));
        expect(sticker.tags, equals('cool,fun'));
        expect(sticker.formatType, equals(FormatType.standard));
        expect(sticker.sortValue, equals(5));
        expect(sticker.serverId, equals(Snowflake('987654321')));
      });

      test('resolves StickerType.standard for type 1', () {
        final payload = normalizedPayload()..['type'] = 1;
        final sticker = serializer.serialize(payload);

        expect(sticker.type, equals(StickerType.standard));
      });

      test('resolves FormatType.guild for format_type 2', () {
        final payload = normalizedPayload()..['format_type'] = 2;
        final sticker = serializer.serialize(payload);

        expect(sticker.formatType, equals(FormatType.guild));
      });
    });

    group('deserialize()', () {
      test('produces map with expected keys and values', () {
        final sticker = serializer.serialize(normalizedPayload());
        final result = serializer.deserialize(sticker);

        expect(result['id'], equals(Snowflake('111222333')));
        expect(result['name'], equals('cool_sticker'));
        expect(result['type'], equals(StickerType.guild.value));
        expect(result['available'], isTrue);
        expect(result['pack_id'], equals('pack_001'));
        expect(result['description'], equals('A cool sticker'));
        expect(result['tags'], equals('cool,fun'));
        expect(result['format_type'], equals(FormatType.standard.value));
        expect(result['sort_value'], equals(5));
        expect(result['server_id'], equals(Snowflake('987654321')));
      });
    });

    group('normalize()', () {
      test('writes to cache with sticker key', () async {
        await serializer.normalize(rawDiscordPayload());

        final expectedKey = CacheKey().sticker('987654321', '111222333');
        expect(cache.store.containsKey(expectedKey), isTrue);
      });

      test('renames guild_id to server_id', () async {
        final result = await serializer.normalize(rawDiscordPayload());

        expect(result, containsPair('server_id', '987654321'));
        expect(result.containsKey('guild_id'), isFalse);
      });
    });

    group('round-trip', () {
      test('serialize then deserialize preserves key data', () {
        final json = normalizedPayload();
        final sticker = serializer.serialize(json);
        final result = serializer.deserialize(sticker);

        expect(result['name'], equals(json['name']));
        expect(result['type'], equals(json['type']));
        expect(result['available'], equals(json['available']));
        expect(result['format_type'], equals(json['format_type']));
      });
    });
  });
}
