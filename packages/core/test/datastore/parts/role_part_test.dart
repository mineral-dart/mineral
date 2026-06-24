import 'package:mineral/src/infrastructure/internals/datastore/parts/role_part.dart';
import 'package:test/test.dart';

import '../../helpers/fake_datastore.dart';
import '../../helpers/fake_http_client.dart';
import '../../helpers/fake_marshaller.dart';
import '../../helpers/ioc_test_helper.dart';

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
