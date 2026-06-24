import 'dart:io';

import 'package:mineral/api.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/application_emoji_part.dart';
import 'package:test/test.dart';

import '../../helpers/fake_datastore.dart';
import '../../helpers/fake_http_client.dart';
import '../../helpers/fake_marshaller.dart';
import '../../helpers/fake_response.dart';
import '../../helpers/ioc_test_helper.dart';

/// A raw Discord application-emoji payload (no guild_id field).
Map<String, dynamic> _emojiPayload({
  String id = '111222333444555666',
  String name = 'thumbsup',
}) =>
    {
      'id': id,
      'name': name,
      'managed': false,
      'available': true,
      'animated': false,
      'roles': null,
    };

/// Creates a minimal [Image] from a 1x1 transparent PNG for tests.
Image _fakeImage() {
  // 1x1 transparent PNG bytes (smallest valid PNG)
  final pngBytes = [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
    0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, // IDAT chunk
    0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
    0x00, 0x00, 0x02, 0x00, 0x01, 0xE2, 0x21, 0xBC,
    0x33, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, // IEND chunk
    0x44, 0xAE, 0x42, 0x60, 0x82,
  ];
  final path =
      '${Directory.systemTemp.path}/test_emoji_${DateTime.now().microsecondsSinceEpoch}.png';
  final tmpFile = File(path)..writeAsBytesSync(pngBytes);
  final image = Image.file(tmpFile);
  tmpFile.deleteSync();
  return image;
}

void main() {
  const applicationId = '999888777666555444';

  group('ApplicationEmojiPart', () {
    late FakeHttpClient http;
    late FakeDataStore dataStore;
    late ApplicationEmojiPart part;
    late void Function() restoreIoc;

    /// Creates a fresh [ApplicationEmojiPart] with a given HTTP client,
    /// registers a new IoC scope, and returns the restore callback.
    (ApplicationEmojiPart, void Function() restore) buildPart(
        FakeHttpClient client) {
      final ds = FakeDataStore(client);
      final ioc = createTestIoc(dataStore: ds);
      return (ApplicationEmojiPart(FakeMarshaller(), ds), ioc.restore);
    }

    setUp(() {
      http = FakeHttpClient();
      dataStore = FakeDataStore(http);
      final iocResult = createTestIoc(dataStore: dataStore);
      restoreIoc = iocResult.restore;
      part = ApplicationEmojiPart(FakeMarshaller(), dataStore);
    });

    tearDown(() => restoreIoc());

    // ── fetch ────────────────────────────────────────────────────────────────

    group('fetch()', () {
      test('sends GET to /applications/:id/emojis', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, {
            'items': [_emojiPayload()],
          }),
        ]);
        final (p, restore) = buildPart(client);

        await p.fetch(applicationId);
        restore();

        expect(client.calls, hasLength(1));
        expect(client.calls.single.method, equals('GET'));
        expect(client.calls.single.path,
            equals('/applications/$applicationId/emojis'));
      });

      test('unwraps the items wrapper and returns Emojis', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, {
            'items': [
              _emojiPayload(id: '111000111000111000', name: 'wave'),
              _emojiPayload(id: '222000222000222000', name: 'fire'),
            ],
          }),
        ]);
        final (p, restore) = buildPart(client);

        final result = await p.fetch(applicationId);
        restore();

        expect(result, hasLength(2));
        expect(result.values.map((e) => e.name), containsAll(['wave', 'fire']));
      });

      test('returns empty map when items is empty', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, {'items': []}),
        ]);
        final (p, restore) = buildPart(client);

        final result = await p.fetch(applicationId);
        restore();

        expect(result, isEmpty);
      });
    });

    // ── get ──────────────────────────────────────────────────────────────────

    group('get()', () {
      test('sends GET to /applications/:id/emojis/:emojiId', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _emojiPayload()),
        ]);
        final (p, restore) = buildPart(client);

        await p.get(applicationId, '111222333444555666');
        restore();

        expect(client.calls, hasLength(1));
        expect(client.calls.single.method, equals('GET'));
        expect(client.calls.single.path,
            equals('/applications/$applicationId/emojis/111222333444555666'));
      });

      test('deserializes app-emoji payload WITHOUT guild_id into an Emoji', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200,
              _emojiPayload(id: '555666777888999000', name: 'cool')),
        ]);
        final (p, restore) = buildPart(client);

        final emoji = await p.get(applicationId, '555666777888999000');
        restore();

        expect(emoji, isA<Emoji>());
        expect(emoji!.name, equals('cool'));
        expect(emoji.id, equals(Snowflake.parse('555666777888999000')));
        // guildId is set to applicationId since app emojis have no guild_id
        expect(emoji.guildId, equals(Snowflake.parse(applicationId)));
        expect(emoji.managed, isFalse);
        expect(emoji.available, isTrue);
        expect(emoji.animated, isFalse);
        expect(emoji.roles, isEmpty);
      });
    });

    // ── create ───────────────────────────────────────────────────────────────

    group('create()', () {
      test('sends POST to /applications/:id/emojis', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _emojiPayload()),
        ]);
        final (p, restore) = buildPart(client);

        await p.create(applicationId, 'test', _fakeImage());
        restore();

        expect(client.calls, hasLength(1));
        expect(client.calls.single.method, equals('POST'));
        expect(client.calls.single.path,
            equals('/applications/$applicationId/emojis'));
      });
    });

    // ── update ───────────────────────────────────────────────────────────────

    group('update()', () {
      test('sends PATCH to /applications/:id/emojis/:emojiId', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200,
              _emojiPayload(id: '111222333444555666', name: 'new_name')),
        ]);
        final (p, restore) = buildPart(client);

        await p.update(applicationId, '111222333444555666', 'new_name');
        restore();

        expect(client.calls, hasLength(1));
        expect(client.calls.single.method, equals('PATCH'));
        expect(client.calls.single.path,
            equals('/applications/$applicationId/emojis/111222333444555666'));
      });
    });

    // ── delete ───────────────────────────────────────────────────────────────

    group('delete()', () {
      test('sends DELETE to /applications/:id/emojis/:emojiId', () async {
        await part.delete(applicationId, '111222333444555666');

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('DELETE'));
        expect(http.calls.single.path,
            equals('/applications/$applicationId/emojis/111222333444555666'));
      });
    });
  });
}
