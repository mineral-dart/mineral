import 'package:mineral/api.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/stage_instance_part.dart';
import 'package:test/test.dart';

import '../../helpers/fake_datastore.dart';
import '../../helpers/fake_http_client.dart';
import '../../helpers/fake_marshaller.dart';
import '../../helpers/fake_response.dart';
import '../../helpers/ioc_test_helper.dart';

const _channelId = '111222333444555666';
const _guildId = '123456789012345678';
const _instanceId = '999888777666555444';

Map<String, dynamic> _stageInstancePayload({
  String? topic,
  int privacyLevel = 2,
  String? guildScheduledEventId,
}) =>
    {
      'id': _instanceId,
      'guild_id': _guildId,
      'channel_id': _channelId,
      'topic': topic ?? 'Test Topic',
      'privacy_level': privacyLevel,
      'guild_scheduled_event_id': ?guildScheduledEventId,
    };

(StageInstancePart, void Function() restore) _buildPart(FakeHttpClient client) {
  final ds = FakeDataStore(client);
  final ioc = createTestIoc(dataStore: ds);
  return (StageInstancePart(FakeMarshaller(), ds), ioc.restore);
}

void main() {
  group('StageInstancePart', () {
    late void Function() restoreIoc;

    setUp(() {
      final http = FakeHttpClient();
      final dataStore = FakeDataStore(http);
      final iocResult = createTestIoc(dataStore: dataStore);
      restoreIoc = iocResult.restore;
    });

    tearDown(() => restoreIoc());

    // ── get ───────────────────────────────────────────────────────────────────

    group('get()', () {
      test('sends GET to /stage-instances/:channelId', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _stageInstancePayload()),
        ]);
        final (p, restore) = _buildPart(client);

        await p.get(_channelId);
        restore();

        expect(client.calls, hasLength(1));
        expect(client.calls.single.method, equals('GET'));
        expect(client.calls.single.path,
            equals('/stage-instances/$_channelId'));
      });

      test('returns a correctly parsed StageInstance', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(
              200, _stageInstancePayload(topic: 'Hello World', privacyLevel: 2)),
        ]);
        final (p, restore) = _buildPart(client);

        final instance = await p.get(_channelId);
        restore();

        expect(instance.id, equals(Snowflake.parse(_instanceId)));
        expect(instance.guildId, equals(Snowflake.parse(_guildId)));
        expect(instance.channelId, equals(Snowflake.parse(_channelId)));
        expect(instance.topic, equals('Hello World'));
        expect(instance.privacyLevel, equals(StagePrivacyLevel.guildOnly));
        expect(instance.guildScheduledEventId, isNull);
      });

      test('parses public privacy level correctly', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(
              200, _stageInstancePayload(privacyLevel: 1)),
        ]);
        final (p, restore) = _buildPart(client);

        final instance = await p.get(_channelId);
        restore();

        expect(instance.privacyLevel, equals(StagePrivacyLevel.public));
      });

      test('parses guildScheduledEventId when present', () async {
        final eventId = '777666555444333222';
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(
              200,
              _stageInstancePayload(guildScheduledEventId: eventId)),
        ]);
        final (p, restore) = _buildPart(client);

        final instance = await p.get(_channelId);
        restore();

        expect(instance.guildScheduledEventId,
            equals(Snowflake.parse(eventId)));
      });
    });

    // ── create ────────────────────────────────────────────────────────────────

    group('create()', () {
      test('sends POST to /stage-instances', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _stageInstancePayload()),
        ]);
        final (p, restore) = _buildPart(client);

        await p.create(channelId: _channelId, topic: 'Test Topic');
        restore();

        expect(client.calls, hasLength(1));
        expect(client.calls.single.method, equals('POST'));
        expect(client.calls.single.path, equals('/stage-instances'));
      });

      test('returns correctly parsed StageInstance', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(
              200, _stageInstancePayload(topic: 'My Stage')),
        ]);
        final (p, restore) = _buildPart(client);

        final instance =
            await p.create(channelId: _channelId, topic: 'My Stage');
        restore();

        expect(instance, isA<StageInstance>());
        expect(instance.topic, equals('My Stage'));
        expect(instance.channelId, equals(Snowflake.parse(_channelId)));
      });

      test('sends only required fields when optional params absent', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _stageInstancePayload()),
        ]);
        final (p, restore) = _buildPart(client);

        await p.create(channelId: _channelId, topic: 'Minimal');
        restore();

        final body = client.requests.single.body as Map<String, dynamic>;
        expect(body.containsKey('channel_id'), isTrue);
        expect(body.containsKey('topic'), isTrue);
        expect(body.containsKey('privacy_level'), isFalse);
        expect(body.containsKey('send_start_notification'), isFalse);
        expect(body.containsKey('guild_scheduled_event_id'), isFalse);
      });

      test('sends privacyLevel when provided', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(
              200, _stageInstancePayload(privacyLevel: 1)),
        ]);
        final (p, restore) = _buildPart(client);

        await p.create(
          channelId: _channelId,
          topic: 'Test',
          privacyLevel: StagePrivacyLevel.public,
        );
        restore();

        final body = client.requests.single.body as Map<String, dynamic>;
        expect(body['privacy_level'], equals(1));
      });

      test('sends sendStartNotification when provided', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _stageInstancePayload()),
        ]);
        final (p, restore) = _buildPart(client);

        await p.create(
          channelId: _channelId,
          topic: 'Test',
          sendStartNotification: true,
        );
        restore();

        final body = client.requests.single.body as Map<String, dynamic>;
        expect(body['send_start_notification'], isTrue);
      });

      test('sends guildScheduledEventId when provided', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _stageInstancePayload()),
        ]);
        final (p, restore) = _buildPart(client);
        const eventId = '777666555444333222';

        await p.create(
          channelId: _channelId,
          topic: 'Test',
          guildScheduledEventId: eventId,
        );
        restore();

        final body = client.requests.single.body as Map<String, dynamic>;
        expect(body.containsKey('guild_scheduled_event_id'), isTrue);
      });

      test('sends audit log reason header when reason provided', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _stageInstancePayload()),
        ]);
        final (p, restore) = _buildPart(client);

        await p.create(
          channelId: _channelId,
          topic: 'Test',
          reason: 'starting stage',
        );
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
      test('sends PATCH to /stage-instances/:channelId', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(
              200, _stageInstancePayload(topic: 'New Topic')),
        ]);
        final (p, restore) = _buildPart(client);

        await p.update(channelId: _channelId, topic: 'New Topic');
        restore();

        expect(client.calls, hasLength(1));
        expect(client.calls.single.method, equals('PATCH'));
        expect(client.calls.single.path,
            equals('/stage-instances/$_channelId'));
      });

      test('returns updated StageInstance', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(
              200, _stageInstancePayload(topic: 'Updated')),
        ]);
        final (p, restore) = _buildPart(client);

        final instance = await p.update(channelId: _channelId, topic: 'Updated');
        restore();

        expect(instance.topic, equals('Updated'));
      });

      test('sends only provided fields — topic only', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _stageInstancePayload()),
        ]);
        final (p, restore) = _buildPart(client);

        await p.update(channelId: _channelId, topic: 'Only Topic');
        restore();

        final body = client.requests.single.body as Map<String, dynamic>;
        expect(body.containsKey('topic'), isTrue);
        expect(body.containsKey('privacy_level'), isFalse);
      });

      test('sends only provided fields — privacyLevel only', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _stageInstancePayload()),
        ]);
        final (p, restore) = _buildPart(client);

        await p.update(
            channelId: _channelId,
            privacyLevel: StagePrivacyLevel.guildOnly);
        restore();

        final body = client.requests.single.body as Map<String, dynamic>;
        expect(body.containsKey('privacy_level'), isTrue);
        expect(body.containsKey('topic'), isFalse);
      });

      test('sends audit log reason header when reason provided', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _stageInstancePayload()),
        ]);
        final (p, restore) = _buildPart(client);

        await p.update(
          channelId: _channelId,
          topic: 'Updated',
          reason: 'topic change',
        );
        restore();

        final headers = client.requests.single.headers;
        final auditHeader = headers.firstWhere(
          (h) => h.key == 'X-Audit-Log-Reason',
          orElse: () => throw StateError('Audit-Log-Reason header not found'),
        );
        expect(auditHeader.value, isNotEmpty);
      });

      test('sends both topic and privacyLevel when both provided', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(
              200, _stageInstancePayload(topic: 'Both', privacyLevel: 1)),
        ]);
        final (p, restore) = _buildPart(client);

        final instance = await p.update(
          channelId: _channelId,
          topic: 'Both',
          privacyLevel: StagePrivacyLevel.public,
        );
        restore();

        final body = client.requests.single.body as Map<String, dynamic>;
        expect(body.containsKey('topic'), isTrue);
        expect(body.containsKey('privacy_level'), isTrue);
        expect(body['privacy_level'], equals(1));
        expect(instance.topic, equals('Both'));
      });
    });

    // ── delete ────────────────────────────────────────────────────────────────

    group('delete()', () {
      test('sends DELETE to /stage-instances/:channelId', () async {
        final client = FakeHttpClient([
          FakeResponse<void>(204, null),
        ]);
        final (p, restore) = _buildPart(client);

        await p.delete(channelId: _channelId);
        restore();

        expect(client.calls, hasLength(1));
        expect(client.calls.single.method, equals('DELETE'));
        expect(client.calls.single.path,
            equals('/stage-instances/$_channelId'));
      });

      test('sends audit log reason header when reason provided', () async {
        final client = FakeHttpClient([
          FakeResponse<void>(204, null),
        ]);
        final (p, restore) = _buildPart(client);

        await p.delete(channelId: _channelId, reason: 'ending stage');
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

        await expectLater(
            p.delete(channelId: _channelId), completes);
        restore();
      });
    });
  });
}
