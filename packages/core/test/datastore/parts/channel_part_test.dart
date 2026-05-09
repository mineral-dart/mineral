import 'package:mineral/src/infrastructure/internals/datastore/parts/channel_part.dart';
import 'package:test/test.dart';

import '../../helpers/fake_datastore.dart';
import '../../helpers/fake_http_client.dart';
import '../../helpers/fake_marshaller.dart';
import '../../helpers/ioc_test_helper.dart';

void main() {
  group('ChannelPart', () {
    late FakeHttpClient http;
    late FakeDataStore dataStore;
    late ChannelPart channel;
    late void Function() restoreIoc;

    setUp(() {
      http = FakeHttpClient();
      dataStore = FakeDataStore(http);
      final iocResult = createTestIoc(dataStore: dataStore);
      restoreIoc = iocResult.restore;
      channel = ChannelPart(FakeMarshaller(), dataStore);
    });

    tearDown(() => restoreIoc());

    group('delete', () {
      test('sends DELETE to /channels/:id', () async {
        await channel.delete('123', null);

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('DELETE'));
        expect(http.calls.single.path, equals('/channels/123'));
      });
    });
  });
}
