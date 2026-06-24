import 'package:mineral/api.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/soundboard_part.dart';
import 'package:test/test.dart';

import '../../helpers/fake_datastore.dart';
import '../../helpers/fake_http_client.dart';
import '../../helpers/fake_marshaller.dart';
import '../../helpers/fake_response.dart';
import '../../helpers/ioc_test_helper.dart';

const _guildId = '123456789012345678';
const _soundId = '111222333444555666';
const _channelId = '999888777666555444';
const _soundId2 = '222333444555666777';

Map<String, dynamic> _soundPayload({
  String? id,
  String name = 'Bloop',
  double volume = 1.0,
  String? emojiId,
  String? emojiName,
  String? guildId,
  bool available = true,
  Map<String, dynamic>? user,
}) =>
    {
      'sound_id': id ?? _soundId,
      'name': name,
      'volume': volume,
      if (emojiId != null) 'emoji_id': emojiId,
      if (emojiName != null) 'emoji_name': emojiName,
      if (guildId != null) 'guild_id': guildId,
      'available': available,
      if (user != null) 'user': user,
    };

(SoundboardPart, void Function() restore) _buildPart(FakeHttpClient client) {
  final ds = FakeDataStore(client);
  final ioc = createTestIoc(dataStore: ds);
  return (SoundboardPart(FakeMarshaller(), ds), ioc.restore);
}

void main() {
  group('SoundboardPart', () {
    late void Function() restoreIoc;

    setUp(() {
      final http = FakeHttpClient();
      final dataStore = FakeDataStore(http);
      final iocResult = createTestIoc(dataStore: dataStore);
      restoreIoc = iocResult.restore;
    });

    tearDown(() => restoreIoc());

    // ── fetchDefault ──────────────────────────────────────────────────────────

    group('fetchDefault()', () {
      test('sends GET to /soundboard-default-sounds', () async {
        final client = FakeHttpClient([
          FakeResponse<List<Map<String, dynamic>>>(
              200, [_soundPayload()]),
        ]);
        final (p, restore) = _buildPart(client);

        await p.fetchDefault();
        restore();

        expect(client.calls, hasLength(1));
        expect(client.calls.single.method, equals('GET'));
        expect(client.calls.single.path,
            equals('/soundboard-default-sounds'));
      });

      test('returns a list of SoundboardSounds', () async {
        final client = FakeHttpClient([
          FakeResponse<List<Map<String, dynamic>>>(200,
              [_soundPayload(name: 'Boom'), _soundPayload(id: _soundId2, name: 'Zap')]),
        ]);
        final (p, restore) = _buildPart(client);

        final sounds = await p.fetchDefault();
        restore();

        expect(sounds, hasLength(2));
        expect(sounds[0].name, equals('Boom'));
        expect(sounds[1].name, equals('Zap'));
      });
    });

    // ── fetchForServer ────────────────────────────────────────────────────────

    group('fetchForServer()', () {
      test('sends GET to /guilds/:guildId/soundboard-sounds', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(
              200, {'items': <Map<String, dynamic>>[]}),
        ]);
        final (p, restore) = _buildPart(client);

        await p.fetchForServer(_guildId);
        restore();

        expect(client.calls, hasLength(1));
        expect(client.calls.single.method, equals('GET'));
        expect(client.calls.single.path,
            equals('/guilds/$_guildId/soundboard-sounds'));
      });

      test('unwraps the items wrapper', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, {
            'items': [
              _soundPayload(id: _soundId, name: 'Alpha'),
              _soundPayload(id: _soundId2, name: 'Beta'),
            ]
          }),
        ]);
        final (p, restore) = _buildPart(client);

        final sounds = await p.fetchForServer(_guildId);
        restore();

        expect(sounds, hasLength(2));
        expect(sounds.containsKey(Snowflake.parse(_soundId)), isTrue);
        expect(sounds.containsKey(Snowflake.parse(_soundId2)), isTrue);
        expect(sounds[Snowflake.parse(_soundId)]!.name, equals('Alpha'));
        expect(sounds[Snowflake.parse(_soundId2)]!.name, equals('Beta'));
      });

      test('keys map by soundId', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, {
            'items': [_soundPayload(id: _soundId)]
          }),
        ]);
        final (p, restore) = _buildPart(client);

        final sounds = await p.fetchForServer(_guildId);
        restore();

        final key = sounds.keys.single;
        expect(key, equals(Snowflake.parse(_soundId)));
      });
    });

    // ── get ───────────────────────────────────────────────────────────────────

    group('get()', () {
      test('sends GET to /guilds/:guildId/soundboard-sounds/:soundId',
          () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _soundPayload()),
        ]);
        final (p, restore) = _buildPart(client);

        await p.get(_guildId, _soundId);
        restore();

        expect(client.calls, hasLength(1));
        expect(client.calls.single.method, equals('GET'));
        expect(client.calls.single.path,
            equals('/guilds/$_guildId/soundboard-sounds/$_soundId'));
      });

      test('returns a correctly parsed SoundboardSound', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200,
              _soundPayload(name: 'Test Sound', volume: 0.5, guildId: _guildId)),
        ]);
        final (p, restore) = _buildPart(client);

        final sound = await p.get(_guildId, _soundId);
        restore();

        expect(sound.soundId, equals(Snowflake.parse(_soundId)));
        expect(sound.name, equals('Test Sound'));
        expect(sound.volume, closeTo(0.5, 0.001));
        expect(sound.guildId, equals(Snowflake.parse(_guildId)));
      });

      test('parses optional user id from nested user object', () async {
        const userId = '555666777888999000';
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200,
              _soundPayload(user: {'id': userId, 'username': 'alice'})),
        ]);
        final (p, restore) = _buildPart(client);

        final sound = await p.get(_guildId, _soundId);
        restore();

        expect(sound.userId, equals(Snowflake.parse(userId)));
      });
    });

    // ── create ────────────────────────────────────────────────────────────────

    group('create()', () {
      test('sends POST to /guilds/:guildId/soundboard-sounds', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(
              200, _soundPayload(guildId: _guildId)),
        ]);
        final (p, restore) = _buildPart(client);

        await p.create(_guildId,
            name: 'NewSound', sound: 'data:audio/mp3;base64,abc');
        restore();

        expect(client.calls, hasLength(1));
        expect(client.calls.single.method, equals('POST'));
        expect(client.calls.single.path,
            equals('/guilds/$_guildId/soundboard-sounds'));
      });

      test('sends required fields name and sound', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(
              200, _soundPayload(guildId: _guildId)),
        ]);
        final (p, restore) = _buildPart(client);

        await p.create(_guildId,
            name: 'MySound', sound: 'data:audio/mp3;base64,xyz');
        restore();

        final body = client.requests.single.body as Map<String, dynamic>;
        expect(body['name'], equals('MySound'));
        expect(body['sound'], equals('data:audio/mp3;base64,xyz'));
      });

      test('sends only required fields when optionals absent', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(
              200, _soundPayload(guildId: _guildId)),
        ]);
        final (p, restore) = _buildPart(client);

        await p.create(_guildId,
            name: 'Minimal', sound: 'data:audio/mp3;base64,abc');
        restore();

        final body = client.requests.single.body as Map<String, dynamic>;
        expect(body.containsKey('volume'), isFalse);
        expect(body.containsKey('emoji_id'), isFalse);
        expect(body.containsKey('emoji_name'), isFalse);
      });

      test('sends volume when provided', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(
              200, _soundPayload(volume: 0.75, guildId: _guildId)),
        ]);
        final (p, restore) = _buildPart(client);

        await p.create(_guildId,
            name: 'S', sound: 'data:audio/mp3;base64,abc', volume: 0.75);
        restore();

        final body = client.requests.single.body as Map<String, dynamic>;
        expect(body['volume'], closeTo(0.75, 0.001));
      });

      test('sends emojiName when provided', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(
              200, _soundPayload(emojiName: '🎵', guildId: _guildId)),
        ]);
        final (p, restore) = _buildPart(client);

        await p.create(_guildId,
            name: 'S', sound: 'data:audio/mp3;base64,abc', emojiName: '🎵');
        restore();

        final body = client.requests.single.body as Map<String, dynamic>;
        expect(body['emoji_name'], equals('🎵'));
      });

      test('sends audit log reason header when reason provided', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(
              200, _soundPayload(guildId: _guildId)),
        ]);
        final (p, restore) = _buildPart(client);

        await p.create(_guildId,
            name: 'S', sound: 'data:audio/mp3;base64,abc', reason: 'custom reason');
        restore();

        final headers = client.requests.single.headers;
        final auditHeader = headers.firstWhere(
          (h) => h.key == 'X-Audit-Log-Reason',
          orElse: () => throw StateError('Audit-Log-Reason header not found'),
        );
        expect(auditHeader.value, isNotEmpty);
      });
    });

    // ── update ────────────────────────────────────────────────────────────────

    group('update()', () {
      test('sends PATCH to /guilds/:guildId/soundboard-sounds/:soundId',
          () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _soundPayload()),
        ]);
        final (p, restore) = _buildPart(client);

        await p.update(_guildId, _soundId, name: 'Updated');
        restore();

        expect(client.calls, hasLength(1));
        expect(client.calls.single.method, equals('PATCH'));
        expect(client.calls.single.path,
            equals('/guilds/$_guildId/soundboard-sounds/$_soundId'));
      });

      test('sends only provided fields - name only', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _soundPayload()),
        ]);
        final (p, restore) = _buildPart(client);

        await p.update(_guildId, _soundId, name: 'NewName');
        restore();

        final body = client.requests.single.body as Map<String, dynamic>;
        expect(body.containsKey('name'), isTrue);
        expect(body['name'], equals('NewName'));
        expect(body.containsKey('volume'), isFalse);
        expect(body.containsKey('emoji_id'), isFalse);
        expect(body.containsKey('emoji_name'), isFalse);
      });

      test('sends only provided fields - volume only', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _soundPayload(volume: 0.5)),
        ]);
        final (p, restore) = _buildPart(client);

        await p.update(_guildId, _soundId, volume: 0.5);
        restore();

        final body = client.requests.single.body as Map<String, dynamic>;
        expect(body.containsKey('volume'), isTrue);
        expect(body.containsKey('name'), isFalse);
      });

      test('sends audit log reason header when reason provided', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _soundPayload()),
        ]);
        final (p, restore) = _buildPart(client);

        await p.update(_guildId, _soundId, name: 'X', reason: 'mod action');
        restore();

        final headers = client.requests.single.headers;
        final auditHeader = headers.firstWhere(
          (h) => h.key == 'X-Audit-Log-Reason',
          orElse: () => throw StateError('Audit-Log-Reason header not found'),
        );
        expect(auditHeader.value, isNotEmpty);
      });
    });

    // ── delete ────────────────────────────────────────────────────────────────

    group('delete()', () {
      test('sends DELETE to /guilds/:guildId/soundboard-sounds/:soundId',
          () async {
        final client = FakeHttpClient([
          FakeResponse<void>(204, null),
        ]);
        final (p, restore) = _buildPart(client);

        await p.delete(_guildId, _soundId);
        restore();

        expect(client.calls, hasLength(1));
        expect(client.calls.single.method, equals('DELETE'));
        expect(client.calls.single.path,
            equals('/guilds/$_guildId/soundboard-sounds/$_soundId'));
      });

      test('sends audit log reason header when reason provided', () async {
        final client = FakeHttpClient([
          FakeResponse<void>(204, null),
        ]);
        final (p, restore) = _buildPart(client);

        await p.delete(_guildId, _soundId, reason: 'removal');
        restore();

        final headers = client.requests.single.headers;
        final auditHeader = headers.firstWhere(
          (h) => h.key == 'X-Audit-Log-Reason',
          orElse: () => throw StateError('Audit-Log-Reason header not found'),
        );
        expect(auditHeader.value, isNotEmpty);
      });

      test('completes without error when no reason provided', () async {
        final client = FakeHttpClient([
          FakeResponse<void>(204, null),
        ]);
        final (p, restore) = _buildPart(client);

        await expectLater(p.delete(_guildId, _soundId), completes);
        restore();
      });
    });

    // ── sendToChannel ─────────────────────────────────────────────────────────

    group('sendToChannel()', () {
      test(
          'sends POST to /channels/:channelId/send-soundboard-sound', () async {
        final client = FakeHttpClient([
          FakeResponse<void>(204, null),
        ]);
        final (p, restore) = _buildPart(client);

        await p.sendToChannel(_channelId, soundId: _soundId);
        restore();

        expect(client.calls, hasLength(1));
        expect(client.calls.single.method, equals('POST'));
        expect(client.calls.single.path,
            equals('/channels/$_channelId/send-soundboard-sound'));
      });

      test('sends sound_id in body', () async {
        final client = FakeHttpClient([
          FakeResponse<void>(204, null),
        ]);
        final (p, restore) = _buildPart(client);

        await p.sendToChannel(_channelId, soundId: _soundId);
        restore();

        final body = client.requests.single.body as Map<String, dynamic>;
        expect(body['sound_id'], equals(_soundId));
      });

      test('sends source_guild_id when provided', () async {
        final client = FakeHttpClient([
          FakeResponse<void>(204, null),
        ]);
        final (p, restore) = _buildPart(client);

        await p.sendToChannel(_channelId,
            soundId: _soundId, sourceGuildId: _guildId);
        restore();

        final body = client.requests.single.body as Map<String, dynamic>;
        expect(body['sound_id'], equals(_soundId));
        expect(body['source_guild_id'], equals(_guildId));
      });

      test('omits source_guild_id when not provided', () async {
        final client = FakeHttpClient([
          FakeResponse<void>(204, null),
        ]);
        final (p, restore) = _buildPart(client);

        await p.sendToChannel(_channelId, soundId: _soundId);
        restore();

        final body = client.requests.single.body as Map<String, dynamic>;
        expect(body.containsKey('source_guild_id'), isFalse);
      });
    });
  });
}
