import 'package:mineral/src/infrastructure/internals/datastore/parts/member_part.dart';
import 'package:test/test.dart';

import '../../helpers/fake_datastore.dart';
import '../../helpers/fake_http_client.dart';
import '../../helpers/fake_marshaller.dart';
import '../../helpers/ioc_test_helper.dart';

void main() {
  group('MemberPart', () {
    late FakeHttpClient http;
    late FakeDataStore dataStore;
    late MemberPart member;
    late void Function() restoreIoc;

    setUp(() {
      http = FakeHttpClient();
      dataStore = FakeDataStore(http);
      final iocResult = createTestIoc(dataStore: dataStore);
      restoreIoc = iocResult.restore;
      member = MemberPart(FakeMarshaller(), dataStore);
    });

    tearDown(() => restoreIoc());

    group('ban', () {
      test('sends PUT to /guilds/:guildId/bans/:memberId', () async {
        await member.ban(
          guildId: '222',
          memberId: '111',
          deleteSince: null,
        );

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('PUT'));
        expect(http.calls.single.path, equals('/guilds/222/bans/111'));
      });
    });

    group('kick', () {
      test('sends DELETE to /guilds/:guildId/members/:memberId', () async {
        await member.kick(guildId: '222', memberId: '111');

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('DELETE'));
        expect(http.calls.single.path, equals('/guilds/222/members/111'));
      });
    });
  });
}
