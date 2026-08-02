import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/api/common/sticker.dart';
import 'package:mineral/src/api/common/types/format_type.dart';
import 'package:mineral/src/api/common/types/sticker_type.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/cache_key.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/sticker_serializer.dart';
import 'package:test/test.dart';

import '../../helpers/fake_cache_provider.dart';
import '../../helpers/fake_marshaller.dart';
import '../../helpers/serializer_round_trip.dart';

void main() {
  group('StickerSerializer', () {
    late StickerSerializer serializer;
    late FakeCacheProvider cache;

    setUp(() {
      cache = FakeCacheProvider();
      serializer = StickerSerializer(FakeMarshaller(cache: cache));
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
      'guild_id': '987654321',
    };

    // Mirrors the raw Sticker object Discord sends over the gateway and REST
    // API (https://discord.com/developers/docs/resources/sticker). Must not
    // be adjusted to match what the serializer currently expects — see
    // test/helpers/serializer_round_trip.dart. Notably, `format_type` is
    // 1=PNG, 2=APNG, 3=LOTTIE, 4=GIF, and `guild_id`/`available` are only
    // present on guild stickers, never on standard-pack ones.
    Map<String, dynamic> rawDiscordPayload() => {
      'id': '111222333',
      'pack_id': 'pack_001',
      'name': 'cool_sticker',
      'description': 'A cool sticker',
      'tags': 'cool,fun',
      'asset': '',
      'type': 2,
      'format_type': 1,
      'available': true,
      'guild_id': '987654321',
      'user': {'id': '999888777', 'username': 'sticker_author'},
      'sort_value': 5,
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
        expect(sticker.guildId, equals(Snowflake('987654321')));
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
        expect(result['guild_id'], equals(Snowflake('987654321')));
      });
    });

    group('normalize()', () {
      test('writes to cache with sticker key', () async {
        await serializer.normalize(rawDiscordPayload());

        final expectedKey = CacheKey().sticker('987654321', '111222333');
        expect(cache.store.containsKey(expectedKey), isTrue);
      });

      test('renames guild_id to guild_id', () async {
        final result = await serializer.normalize(rawDiscordPayload());

        expect(result, containsPair('guild_id', '987654321'));
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

    group('round-trip (normalize -> serialize)', () {
      // Discord's sticker `format_type` is 1=PNG, 2=APNG, 3=LOTTIE, 4=GIF.
      // `FormatType` only declares standard(1)/guild(2) (a copy-paste of
      // StickerType's values), so LOTTIE and GIF stickers cannot resolve.

      test('format_type 1 (PNG) resolves', () async {
        final raw = rawDiscordPayload()..['format_type'] = 1;

        await expectRoundTrip<Sticker>(serializer, raw, {
          'Sticker.formatType': (sticker) =>
              expect(sticker.formatType, equals(FormatType.standard)),
        });
      });

      test('format_type 2 (APNG) resolves', () async {
        final raw = rawDiscordPayload()..['format_type'] = 2;

        await expectRoundTrip<Sticker>(serializer, raw, {
          'Sticker.formatType': (sticker) =>
              expect(sticker.formatType, equals(FormatType.guild)),
        });
      });

      test('format_type 3 (LOTTIE) throws StateError — this is the format of '
          'every Discord standard sticker pack', () async {
        // guild_id is left as a valid value here on purpose: normalize()
        // itself hard-casts guild_id for the cache key (see the separate
        // "no guild_id" case below), and mixing that failure in here would
        // no longer isolate the format_type defect this case targets.
        final raw = rawDiscordPayload()..['format_type'] = 3;

        await expectLater(roundTrip(serializer, raw), throwsStateError);
      });

      test('format_type 4 (GIF) throws StateError', () async {
        final raw = rawDiscordPayload()..['format_type'] = 4;

        await expectLater(roundTrip(serializer, raw), throwsStateError);
      });

      test('standard-pack sticker with no guild_id round-trips', () async {
        final raw = rawDiscordPayload()..['type'] = StickerType.standard.value;

        await expectRoundTripWithoutOptionals(serializer, raw, {'guild_id'});
      });

      test('available survives the round-trip when Discord sends it', () async {
        await expectRoundTrip<Sticker>(serializer, rawDiscordPayload(), {
          'Sticker.isAvailable': (sticker) =>
              expect(sticker.isAvailable, isTrue),
        });
      });

      test(
        'round-trips when Discord omits the optional available field',
        () async {
          await expectRoundTripWithoutOptionals(
            serializer,
            rawDiscordPayload(),
            {'available'},
          );
        },
      );
    });
  });
}
