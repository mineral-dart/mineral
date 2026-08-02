import 'package:mineral/api.dart';
import 'package:mineral/src/domains/common/utils/utils.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/guild_scheduled_event_part.dart';
import 'package:test/test.dart';

import '../../helpers/fake_datastore.dart';
import '../../helpers/fake_http_client.dart';
import '../../helpers/fake_marshaller.dart';
import '../../helpers/fake_response.dart';
import '../../helpers/ioc_test_helper.dart';

void main() {
  group('GuildScheduledEventPart', () {
    late FakeHttpClient http;
    late FakeDataStore dataStore;
    late GuildScheduledEventPart part;
    late void Function() restoreIoc;

    setUp(() {
      http = FakeHttpClient();
      dataStore = FakeDataStore(http);
      final iocResult = createTestIoc(dataStore: dataStore);
      restoreIoc = iocResult.restore;
      part = GuildScheduledEventPart(FakeMarshaller(), dataStore);
    });

    tearDown(() => restoreIoc());

    Map<String, dynamic> eventResponse() => {
      'id': '111111111111111111',
      'guild_id': '222222222222222222',
      'channel_id': '333333333333333333',
      'creator_id': '444444444444444444',
      'name': 'Stage event',
      'description': null,
      'scheduled_start_time': '2026-06-01T18:00:00.000Z',
      'scheduled_end_time': null,
      'privacy_level': 2,
      'status': 1,
      'entity_type': 2,
      'entity_id': null,
      'entity_metadata': null,
      'user_count': null,
      'image': null,
    };

    void rebuildWith(List<Object> outcomes) {
      restoreIoc();
      http = FakeHttpClient(outcomes);
      dataStore = FakeDataStore(http);
      final marshaller = FakeMarshaller();
      final iocResult = createTestIoc(
        dataStore: dataStore,
        marshaller: marshaller,
      );
      restoreIoc = iocResult.restore;
      part = GuildScheduledEventPart(marshaller, dataStore);
    }

    group('fetchForServer', () {
      test('sends GET to /guilds/:guildId/scheduled-events', () async {
        rebuildWith([
          FakeResponse<List<Map<String, dynamic>>>(200, [eventResponse()]),
        ]);

        final result = await part.fetchForServer('222222222222222222');

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('GET'));
        expect(
          http.calls.single.path,
          equals('/guilds/222222222222222222/scheduled-events'),
        );
        expect(result, hasLength(1));
      });
    });

    group('get', () {
      test('sends GET to /guilds/:guildId/scheduled-events/:id', () async {
        rebuildWith([FakeResponse<Map<String, dynamic>>(200, eventResponse())]);

        final result = await part.get(
          '222222222222222222',
          '111111111111111111',
          false,
        );

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('GET'));
        expect(
          http.calls.single.path,
          equals(
            '/guilds/222222222222222222/scheduled-events/111111111111111111',
          ),
        );
        expect(result, isNotNull);
      });
    });

    group('create', () {
      test('sends POST to /guilds/:guildId/scheduled-events', () async {
        rebuildWith([FakeResponse<Map<String, dynamic>>(200, eventResponse())]);

        final result = await part.create(
          guildId: '222222222222222222',
          channelId: '333333333333333333',
          name: 'Stage event',
          privacyLevel: GuildScheduledEventPrivacyLevel.guildOnly,
          scheduledStartTime: DateTime.parse('2026-06-01T18:00:00.000Z'),
          entityType: GuildScheduledEventEntityType.voice,
        );

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('POST'));
        expect(
          http.calls.single.path,
          equals('/guilds/222222222222222222/scheduled-events'),
        );
        expect(result.name, equals('Stage event'));
      });
    });

    group('update', () {
      test('sends PATCH to /guilds/:guildId/scheduled-events/:id', () async {
        rebuildWith([FakeResponse<Map<String, dynamic>>(200, eventResponse())]);

        await part.update(
          guildId: '222222222222222222',
          id: '111111111111111111',
          name: 'Renamed event',
        );

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('PATCH'));
        expect(
          http.calls.single.path,
          equals(
            '/guilds/222222222222222222/scheduled-events/111111111111111111',
          ),
        );
      });
    });

    group('delete', () {
      test('sends DELETE to /guilds/:guildId/scheduled-events/:id', () async {
        await part.delete(
          guildId: '222222222222222222',
          id: '111111111111111111',
        );

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('DELETE'));
        expect(
          http.calls.single.path,
          equals(
            '/guilds/222222222222222222/scheduled-events/111111111111111111',
          ),
        );
      });
    });

    group('outbound timestamps (A11)', () {
      // A11 — Discord expects an absolute instant. A bare local-zone
      // ISO-8601 string (no Z/offset) is misread as UTC on Discord's side,
      // shifting the event time by the host's UTC offset.
      test(
        'create sends scheduled_start_time/scheduled_end_time as UTC with a Z suffix',
        () async {
          rebuildWith([
            FakeResponse<Map<String, dynamic>>(200, eventResponse()),
          ]);

          final utcStart = DateTime.utc(2026, 6, 1, 18, 0, 0);
          final utcEnd = DateTime.utc(2026, 6, 1, 20, 0, 0);

          await part.create(
            guildId: '222222222222222222',
            channelId: '333333333333333333',
            name: 'Stage event',
            privacyLevel: GuildScheduledEventPrivacyLevel.guildOnly,
            scheduledStartTime: utcStart.toLocal(),
            scheduledEndTime: utcEnd.toLocal(),
            entityType: GuildScheduledEventEntityType.voice,
          );

          final body = http.requests.single.body as Map<String, dynamic>;
          expect(
            body['scheduled_start_time'],
            equals(toDiscordTimestamp(utcStart)),
          );
          expect(
            body['scheduled_end_time'],
            equals(toDiscordTimestamp(utcEnd)),
          );
          expect(body['scheduled_start_time'], endsWith('Z'));
          expect(body['scheduled_end_time'], endsWith('Z'));
        },
      );

      test(
        'update sends scheduled_start_time/scheduled_end_time as UTC with a Z suffix',
        () async {
          rebuildWith([
            FakeResponse<Map<String, dynamic>>(200, eventResponse()),
          ]);

          final utcStart = DateTime.utc(2026, 6, 1, 18, 0, 0);
          final utcEnd = DateTime.utc(2026, 6, 1, 20, 0, 0);

          await part.update(
            guildId: '222222222222222222',
            id: '111111111111111111',
            scheduledStartTime: utcStart.toLocal(),
            scheduledEndTime: utcEnd.toLocal(),
          );

          final body = http.requests.single.body as Map<String, dynamic>;
          expect(
            body['scheduled_start_time'],
            equals(toDiscordTimestamp(utcStart)),
          );
          expect(
            body['scheduled_end_time'],
            equals(toDiscordTimestamp(utcEnd)),
          );
          expect(body['scheduled_start_time'], endsWith('Z'));
          expect(body['scheduled_end_time'], endsWith('Z'));
        },
      );
    });

    group('fetchUsers', () {
      test('sends GET to /guilds/:guildId/scheduled-events/:id/users', () async {
        rebuildWith([
          FakeResponse<List<Map<String, dynamic>>>(200, [
            {
              'guild_scheduled_event_id': '111111111111111111',
              'user': {'id': '444444444444444444'},
            },
          ]),
        ]);

        final result = await part.fetchUsers(
          guildId: '222222222222222222',
          id: '111111111111111111',
        );

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('GET'));
        expect(
          http.calls.single.path,
          equals(
            '/guilds/222222222222222222/scheduled-events/111111111111111111/users',
          ),
        );
        expect(result, hasLength(1));
        expect(result.single.userId.value, equals('444444444444444444'));
      });
    });
  });
}
