import 'package:mineral/src/infrastructure/internals/datastore/parts/guild_part.dart';
import 'package:test/test.dart';

import '../../helpers/fake_datastore.dart';
import '../../helpers/fake_http_client.dart';
import '../../helpers/fake_marshaller.dart';
import '../../helpers/ioc_test_helper.dart';

void main() {
  group('GuildPart', () {
    late FakeHttpClient http;
    late FakeDataStore dataStore;
    late GuildPart guild;
    late void Function() restoreIoc;

    setUp(() {
      http = FakeHttpClient();
      dataStore = FakeDataStore(http);
      final iocResult = createTestIoc(dataStore: dataStore);
      restoreIoc = iocResult.restore;
      guild = GuildPart(FakeMarshaller(), dataStore);
    });

    tearDown(() => restoreIoc());

    group('delete', () {
      test('sends DELETE to /guilds/:id', () async {
        await guild.delete('222', null);

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('DELETE'));
        expect(http.calls.single.path, equals('/guilds/222'));
      });
    });
  });
}
