import 'package:mineral/src/api/common/embed/message_embed.dart';
import 'package:mineral/src/api/common/embed/message_embed_type.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/embed_serializer.dart';
import 'package:test/test.dart';

import '../../helpers/fake_cache_provider.dart';
import '../../helpers/fake_marshaller.dart';

void main() {
  group('EmbedSerializer', () {
    late EmbedSerializer serializer;
    late FakeCacheProvider cache;

    setUp(() {
      cache = FakeCacheProvider();
      serializer = EmbedSerializer(FakeMarshaller(cache: cache));
    });

    Map<String, dynamic> fullPayload() => {
          'id': 'msg_123',
          'title': 'Test Embed',
          'description': 'A test description',
          'type': 'rich',
          'url': 'https://example.com',
          'timestamp': '2024-01-15T10:30:00.000Z',
          'assets': null,
          'provider': null,
          'fields': [
            {'name': 'Field 1', 'value': 'Value 1', 'inline': false},
          ],
          'color': 16711680,
        };

    Map<String, dynamic> minimalPayload() => {
          'id': 'msg_456',
          'title': null,
          'description': null,
          'type': null,
          'url': null,
          'timestamp': null,
          'assets': null,
          'provider': null,
          'fields': null,
          'color': null,
        };

    group('serialize()', () {
      test('maps all fields when present', () {
        final embed = serializer.serialize(fullPayload());

        expect(embed, isA<MessageEmbed>());
        expect(embed.title, equals('Test Embed'));
        expect(embed.description, equals('A test description'));
        expect(embed.type, equals(MessageEmbedType.rich));
        expect(embed.url, equals('https://example.com'));
        expect(embed.timestamp, isA<DateTime>());
        expect(embed.color!.toInt(), equals(16711680));
      });

      test('parses fields list', () {
        final embed = serializer.serialize(fullPayload());

        expect(embed.fields, isNotNull);
        expect(embed.fields, hasLength(1));
        expect(embed.fields!.first.name, equals('Field 1'));
        expect(embed.fields!.first.value, equals('Value 1'));
        expect(embed.fields!.first.inline, isFalse);
      });

      test('handles all null optional fields', () {
        final embed = serializer.serialize(minimalPayload());

        expect(embed.title, isNull);
        expect(embed.description, isNull);
        expect(embed.type, isNull);
        expect(embed.url, isNull);
        expect(embed.timestamp, isNull);
        expect(embed.assets, isNull);
        expect(embed.provider, isNull);
        expect(embed.fields, isNull);
        expect(embed.color, isNull);
      });
    });

    group('deserialize()', () {
      test('produces map with expected keys for full embed', () {
        final embed = serializer.serialize(fullPayload());
        final result = serializer.deserialize(embed);

        expect(result['title'], equals('Test Embed'));
        expect(result['description'], equals('A test description'));
        expect(result['url'], equals('https://example.com'));
        expect(result['color'], equals(16711680));
      });

      test('fields are serialized as list of maps', () {
        final embed = serializer.serialize(fullPayload());
        final result = serializer.deserialize(embed);

        expect(result['fields'], isA<List>());
        expect(result['fields'], hasLength(1));
      });

      test('null fields produce null values in map', () {
        final embed = serializer.serialize(minimalPayload());
        final result = serializer.deserialize(embed);

        expect(result['title'], isNull);
        expect(result['description'], isNull);
        expect(result['url'], isNull);
        expect(result['color'], isNull);
      });
    });

    group('round-trip', () {
      test('serialize then deserialize preserves key data', () {
        final json = fullPayload();
        final embed = serializer.serialize(json);
        final result = serializer.deserialize(embed);

        expect(result['title'], equals(json['title']));
        expect(result['description'], equals(json['description']));
        expect(result['url'], equals(json['url']));
        expect(result['color'], equals(json['color']));
      });
    });
  });
}
