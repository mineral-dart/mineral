import 'package:mineral/api.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/template_part.dart';
import 'package:test/test.dart';

import '../../helpers/fake_datastore.dart';
import '../../helpers/fake_http_client.dart';
import '../../helpers/fake_marshaller.dart';
import '../../helpers/fake_response.dart';
import '../../helpers/ioc_test_helper.dart';

const _guildId = '123456789012345678';
const _templateCode = 'AbCdEfGhIjKlMnOp';

Map<String, dynamic> _templatePayload({
  String code = _templateCode,
  String name = 'My Template',
  String? description = 'A great template',
  int usageCount = 5,
  String creatorId = '111111111111111111',
  String createdAt = '2024-01-01T00:00:00+00:00',
  String updatedAt = '2024-06-01T00:00:00+00:00',
  String sourceGuildId = _guildId,
  bool? isDirty,
}) =>
    {
      'code': code,
      'name': name,
      'description': description,
      'usage_count': usageCount,
      'creator_id': creatorId,
      'creator': {
        'id': creatorId,
        'username': 'SomeUser',
        'discriminator': '0000',
        'global_name': null,
      },
      'created_at': createdAt,
      'updated_at': updatedAt,
      'source_guild_id': sourceGuildId,
      'serialized_source_guild': {'name': 'Test Guild'},
      if (isDirty != null) 'is_dirty': isDirty,
    };

(TemplatePart, void Function() restore) _buildPart(FakeHttpClient client) {
  final ds = FakeDataStore(client);
  final ioc = createTestIoc(dataStore: ds);
  return (TemplatePart(FakeMarshaller(), ds), ioc.restore);
}

void main() {
  group('TemplatePart', () {
    late void Function() restoreIoc;

    setUp(() {
      final http = FakeHttpClient();
      final dataStore = FakeDataStore(http);
      final iocResult = createTestIoc(dataStore: dataStore);
      restoreIoc = iocResult.restore;
    });

    tearDown(() => restoreIoc());

    // ── fetchForServer ────────────────────────────────────────────────────────

    group('fetchForServer()', () {
      test('sends GET to /guilds/:id/templates', () async {
        final client = FakeHttpClient([
          FakeResponse<List<Map<String, dynamic>>>(200, [_templatePayload()]),
        ]);
        final (p, restore) = _buildPart(client);

        await p.fetchForServer(_guildId);
        restore();

        expect(client.calls, hasLength(1));
        expect(client.calls.single.method, equals('GET'));
        expect(client.calls.single.path,
            equals('/guilds/$_guildId/templates'));
      });

      test('returns Map keyed by template code', () async {
        final client = FakeHttpClient([
          FakeResponse<List<Map<String, dynamic>>>(200, [
            _templatePayload(code: 'CodeAAA', name: 'Template A'),
            _templatePayload(code: 'CodeBBB', name: 'Template B'),
          ]),
        ]);
        final (p, restore) = _buildPart(client);

        final result = await p.fetchForServer(_guildId);
        restore();

        expect(result, hasLength(2));
        expect(result.keys, containsAll(['CodeAAA', 'CodeBBB']));
        expect(result['CodeAAA']!.name, equals('Template A'));
        expect(result['CodeBBB']!.name, equals('Template B'));
      });

      test('parses template fields correctly', () async {
        final client = FakeHttpClient([
          FakeResponse<List<Map<String, dynamic>>>(200, [_templatePayload()]),
        ]);
        final (p, restore) = _buildPart(client);

        final result = await p.fetchForServer(_guildId);
        restore();

        final t = result[_templateCode]!;
        expect(t.code, equals(_templateCode));
        expect(t.name, equals('My Template'));
        expect(t.description, equals('A great template'));
        expect(t.usageCount, equals(5));
        expect(t.creatorId, equals(Snowflake.parse('111111111111111111')));
        expect(t.sourceGuildId, equals(Snowflake.parse(_guildId)));
        expect(t.serializedSourceGuild, equals({'name': 'Test Guild'}));
        expect(t.isDirty, isNull);
      });

      test('parses isDirty when present', () async {
        final client = FakeHttpClient([
          FakeResponse<List<Map<String, dynamic>>>(
              200, [_templatePayload(isDirty: true)]),
        ]);
        final (p, restore) = _buildPart(client);

        final result = await p.fetchForServer(_guildId);
        restore();

        expect(result[_templateCode]!.isDirty, isTrue);
      });

      test('parses nullable description', () async {
        final client = FakeHttpClient([
          FakeResponse<List<Map<String, dynamic>>>(
              200, [_templatePayload(description: null)]),
        ]);
        final (p, restore) = _buildPart(client);

        final result = await p.fetchForServer(_guildId);
        restore();

        expect(result[_templateCode]!.description, isNull);
      });

      test('returns empty map when no templates', () async {
        final client = FakeHttpClient([
          FakeResponse<List<Map<String, dynamic>>>(200, []),
        ]);
        final (p, restore) = _buildPart(client);

        final result = await p.fetchForServer(_guildId);
        restore();

        expect(result, isEmpty);
      });
    });

    // ── getByCode ─────────────────────────────────────────────────────────────

    group('getByCode()', () {
      test('sends GET to /guilds/templates/:code (not guild-scoped)', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _templatePayload()),
        ]);
        final (p, restore) = _buildPart(client);

        await p.getByCode(_templateCode);
        restore();

        expect(client.calls, hasLength(1));
        expect(client.calls.single.method, equals('GET'));
        expect(client.calls.single.path,
            equals('/guilds/templates/$_templateCode'));
      });

      test('returns parsed GuildTemplate', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _templatePayload()),
        ]);
        final (p, restore) = _buildPart(client);

        final t = await p.getByCode(_templateCode);
        restore();

        expect(t, isA<GuildTemplate>());
        expect(t.code, equals(_templateCode));
      });
    });

    // ── create ────────────────────────────────────────────────────────────────

    group('create()', () {
      test('sends POST to /guilds/:id/templates', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _templatePayload()),
        ]);
        final (p, restore) = _buildPart(client);

        await p.create(_guildId, name: 'My Template');
        restore();

        expect(client.calls, hasLength(1));
        expect(client.calls.single.method, equals('POST'));
        expect(client.calls.single.path,
            equals('/guilds/$_guildId/templates'));
      });

      test('returns parsed GuildTemplate', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _templatePayload()),
        ]);
        final (p, restore) = _buildPart(client);

        final t = await p.create(_guildId, name: 'My Template');
        restore();

        expect(t, isA<GuildTemplate>());
        expect(t.name, equals('My Template'));
      });

      test('includes description when provided', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(
              200, _templatePayload(description: 'Custom desc')),
        ]);
        final (p, restore) = _buildPart(client);

        final t = await p.create(_guildId,
            name: 'My Template', description: 'Custom desc');
        restore();

        expect(t.description, equals('Custom desc'));
      });
    });

    // ── sync ──────────────────────────────────────────────────────────────────

    group('sync()', () {
      test('sends PUT to /guilds/:id/templates/:code', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _templatePayload()),
        ]);
        final (p, restore) = _buildPart(client);

        await p.sync(_guildId, _templateCode);
        restore();

        expect(client.calls, hasLength(1));
        expect(client.calls.single.method, equals('PUT'));
        expect(client.calls.single.path,
            equals('/guilds/$_guildId/templates/$_templateCode'));
      });

      test('returns parsed GuildTemplate', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _templatePayload()),
        ]);
        final (p, restore) = _buildPart(client);

        final t = await p.sync(_guildId, _templateCode);
        restore();

        expect(t, isA<GuildTemplate>());
        expect(t.code, equals(_templateCode));
      });
    });

    // ── update ────────────────────────────────────────────────────────────────

    group('update()', () {
      test('sends PATCH to /guilds/:id/templates/:code', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _templatePayload()),
        ]);
        final (p, restore) = _buildPart(client);

        await p.update(_guildId, _templateCode, name: 'New Name');
        restore();

        expect(client.calls, hasLength(1));
        expect(client.calls.single.method, equals('PATCH'));
        expect(client.calls.single.path,
            equals('/guilds/$_guildId/templates/$_templateCode'));
      });

      test('returns parsed GuildTemplate', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(
              200, _templatePayload(name: 'New Name')),
        ]);
        final (p, restore) = _buildPart(client);

        final t = await p.update(_guildId, _templateCode, name: 'New Name');
        restore();

        expect(t, isA<GuildTemplate>());
        expect(t.name, equals('New Name'));
      });

      test('sends only provided fields (name only)', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _templatePayload()),
        ]);
        final (p, restore) = _buildPart(client);

        await p.update(_guildId, _templateCode, name: 'Only Name');
        restore();

        expect(client.calls, hasLength(1));
        expect(client.calls.single.method, equals('PATCH'));
      });

      test('sends only provided fields (description only)', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _templatePayload()),
        ]);
        final (p, restore) = _buildPart(client);

        await p.update(_guildId, _templateCode, description: 'New desc');
        restore();

        expect(client.calls, hasLength(1));
        expect(client.calls.single.method, equals('PATCH'));
      });

      test('sends both name and description when both provided', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _templatePayload()),
        ]);
        final (p, restore) = _buildPart(client);

        await p.update(_guildId, _templateCode,
            name: 'New Name', description: 'New desc');
        restore();

        expect(client.calls, hasLength(1));
        expect(client.calls.single.method, equals('PATCH'));
      });
    });

    // ── delete ────────────────────────────────────────────────────────────────

    group('delete()', () {
      test('sends DELETE to /guilds/:id/templates/:code', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _templatePayload()),
        ]);
        final (p, restore) = _buildPart(client);

        await p.delete(_guildId, _templateCode);
        restore();

        expect(client.calls, hasLength(1));
        expect(client.calls.single.method, equals('DELETE'));
        expect(client.calls.single.path,
            equals('/guilds/$_guildId/templates/$_templateCode'));
      });

      test('returns the deleted GuildTemplate', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _templatePayload()),
        ]);
        final (p, restore) = _buildPart(client);

        final t = await p.delete(_guildId, _templateCode);
        restore();

        expect(t, isA<GuildTemplate>());
        expect(t.code, equals(_templateCode));
      });
    });
  });
}
