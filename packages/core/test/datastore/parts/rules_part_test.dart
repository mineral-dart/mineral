import 'package:mineral/src/infrastructure/internals/datastore/parts/rules_part.dart';
import 'package:test/test.dart';

import '../../helpers/fake_datastore.dart';
import '../../helpers/fake_http_client.dart';
import '../../helpers/fake_marshaller.dart';
import '../../helpers/ioc_test_helper.dart';

void main() {
  group('RulesPart', () {
    late FakeHttpClient http;
    late FakeDataStore dataStore;
    late RulesPart rules;
    late void Function() restoreIoc;

    setUp(() {
      http = FakeHttpClient();
      dataStore = FakeDataStore(http);
      final iocResult = createTestIoc(dataStore: dataStore);
      restoreIoc = iocResult.restore;
      rules = RulesPart(FakeMarshaller(), dataStore);
    });

    tearDown(() => restoreIoc());

    group('delete', () {
      test('sends DELETE to /guilds/:serverId/auto-moderation/rules/:ruleId',
          () async {
        await rules.delete('222', '333');

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('DELETE'));
        expect(http.calls.single.path,
            equals('/guilds/222/auto-moderation/rules/333'));
      });
    });
  });
}
