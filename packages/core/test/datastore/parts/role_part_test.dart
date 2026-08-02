import 'package:mineral/api.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/role_part.dart';
import 'package:test/test.dart';

import '../../helpers/fake_datastore.dart';
import '../../helpers/fake_http_client.dart';
import '../../helpers/fake_marshaller.dart';
import '../../helpers/fake_response.dart';
import '../../helpers/ioc_test_helper.dart';

/// Mirrors the Discord wire format for a role object exactly as Discord
/// sends it (https://discord.com/developers/docs/topics/permissions#role-object).
/// Discord does NOT include `guild_id` here — RolePart must inject it before
/// handing the payload to `RoleSerializer.normalize`.
Map<String, dynamic> rawDiscordRolePayload({String id = '333'}) => {
  'id': id,
  'name': 'Test Role',
  'color': 0,
  'hoist': false,
  'position': 1,
  'permissions': '0',
  'managed': false,
  'mentionable': false,
  'flags': 0,
};

void main() {
  group('RolePart', () {
    late FakeHttpClient http;
    late FakeDataStore dataStore;
    late RolePart role;
    late void Function() restoreIoc;

    setUp(() {
      http = FakeHttpClient();
      dataStore = FakeDataStore(http);
      final iocResult = createTestIoc(dataStore: dataStore);
      restoreIoc = iocResult.restore;
      role = RolePart(FakeMarshaller(), dataStore);
    });

    tearDown(() => restoreIoc());

    group('get', () {
      test(
        'injects guild_id before normalize so the returned role is populated',
        () async {
          http = FakeHttpClient([
            FakeResponse<Map<String, dynamic>>(200, rawDiscordRolePayload()),
          ]);
          dataStore = FakeDataStore(http);
          role = RolePart(FakeMarshaller(), dataStore);

          final result = await role.get('222', '333', true);

          expect(result, isNotNull);
          expect(result!.id, equals(Snowflake('333')));
          expect(result.guildId, equals(Snowflake('222')));
        },
      );
    });

    group('create', () {
      test(
        'injects guild_id before normalize so the returned role is populated',
        () async {
          http = FakeHttpClient([
            FakeResponse<Map<String, dynamic>>(200, rawDiscordRolePayload()),
          ]);
          dataStore = FakeDataStore(http);
          role = RolePart(FakeMarshaller(), dataStore);

          final result = await role.create(
            '222',
            'Test Role',
            [],
            Color.of(0),
            false,
            false,
            null,
          );

          expect(result.id, equals(Snowflake('333')));
          expect(result.guildId, equals(Snowflake('222')));
        },
      );
    });

    group('update', () {
      test(
        'injects guild_id before normalize so the returned role is populated',
        () async {
          http = FakeHttpClient([
            FakeResponse<Map<String, dynamic>>(200, rawDiscordRolePayload()),
          ]);
          dataStore = FakeDataStore(http);
          role = RolePart(FakeMarshaller(), dataStore);

          final result = await role.update(
            id: '333',
            guildId: '222',
            payload: {'name': 'Updated'},
            reason: null,
          );

          expect(result, isNotNull);
          expect(result!.id, equals(Snowflake('333')));
          expect(result.guildId, equals(Snowflake('222')));
        },
      );
    });

    group('add', () {
      test(
        'sends PUT to /guilds/:guildId/members/:memberId/roles/:roleId',
        () async {
          await role.add(
            memberId: '111',
            guildId: '222',
            roleId: '333',
            reason: null,
          );

          expect(http.calls, hasLength(1));
          expect(http.calls.single.method, equals('PUT'));
          expect(
            http.calls.single.path,
            equals('/guilds/222/members/111/roles/333'),
          );
        },
      );
    });

    group('remove', () {
      test(
        'sends DELETE to /guilds/:guildId/members/:memberId/roles/:roleId',
        () async {
          await role.remove(
            memberId: '111',
            guildId: '222',
            roleId: '333',
            reason: null,
          );

          expect(http.calls, hasLength(1));
          expect(http.calls.single.method, equals('DELETE'));
          expect(
            http.calls.single.path,
            equals('/guilds/222/members/111/roles/333'),
          );
        },
      );
    });

    group('delete', () {
      test('sends DELETE to /guilds/:guildId/roles/:id', () async {
        await role.delete(id: '333', guildId: '222', reason: null);

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('DELETE'));
        expect(http.calls.single.path, equals('/guilds/222/roles/333'));
      });
    });

    group('sync', () {
      test('sends PATCH to /guilds/:guildId/members/:memberId', () async {
        await role.sync(
          memberId: '111',
          guildId: '222',
          roleIds: ['333', '444'],
          reason: null,
        );

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('PATCH'));
        expect(http.calls.single.path, equals('/guilds/222/members/111'));
      });
    });
  });
}
