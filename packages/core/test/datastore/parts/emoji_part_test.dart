import 'package:mineral/api.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/emoji_part.dart';
import 'package:test/test.dart';

import '../../helpers/fake_datastore.dart';
import '../../helpers/fake_http_client.dart';
import '../../helpers/fake_marshaller.dart';
import '../../helpers/fake_response.dart';
import '../../helpers/ioc_test_helper.dart';

/// Mirrors the Discord wire format for an emoji object exactly as Discord
/// sends it (https://discord.com/developers/docs/resources/emoji#emoji-object).
/// Discord does NOT include `guild_id` here — EmojiPart must inject it before
/// handing the payload to `EmojiSerializer.normalize`.
Map<String, dynamic> rawDiscordEmojiPayload({String id = '100200300'}) => {
  'id': id,
  'name': 'thumbsup',
  'roles': <String>[],
  'managed': false,
  'animated': false,
  'available': true,
};

void main() {
  group('EmojiPart', () {
    late FakeHttpClient http;
    late FakeDataStore dataStore;
    late EmojiPart emoji;
    late void Function() restoreIoc;

    setUp(() {
      http = FakeHttpClient();
      dataStore = FakeDataStore(http);
      final iocResult = createTestIoc(dataStore: dataStore);
      restoreIoc = iocResult.restore;
      emoji = EmojiPart(FakeMarshaller(), dataStore);
    });

    tearDown(() => restoreIoc());

    group('fetch', () {
      test(
        'injects guild_id before normalize so the returned emojis are populated',
        () async {
          http = FakeHttpClient([
            FakeResponse<List<Map<String, dynamic>>>(200, [
              rawDiscordEmojiPayload(),
            ]),
          ]);
          dataStore = FakeDataStore(http);
          emoji = EmojiPart(FakeMarshaller(), dataStore);

          final result = await emoji.fetch('222', true);

          expect(result, hasLength(1));
          final fetchedEmoji = result.values.single;
          expect(fetchedEmoji.id, equals(Snowflake('100200300')));
          expect(fetchedEmoji.guildId, equals(Snowflake('222')));
        },
      );
    });

    group('get', () {
      test(
        'injects guild_id before normalize so the returned emoji is populated',
        () async {
          http = FakeHttpClient([
            FakeResponse<Map<String, dynamic>>(200, rawDiscordEmojiPayload()),
          ]);
          dataStore = FakeDataStore(http);
          emoji = EmojiPart(FakeMarshaller(), dataStore);

          final result = await emoji.get('222', '100200300', true);

          expect(result, isNotNull);
          expect(result!.id, equals(Snowflake('100200300')));
          expect(result.guildId, equals(Snowflake('222')));
        },
      );
    });

    group('delete', () {
      test('sends DELETE to /guilds/:guildId/emojis/:emojiId', () async {
        await emoji.delete('222', '111');

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('DELETE'));
        expect(http.calls.single.path, equals('/guilds/222/emojis/111'));
      });
    });
  });
}
