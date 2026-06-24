import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/message_part.dart';
import 'package:test/test.dart';

import '../../helpers/fake_datastore.dart';
import '../../helpers/fake_http_client.dart';
import '../../helpers/fake_marshaller.dart';
import '../../helpers/ioc_test_helper.dart';

void main() {
  group('MessagePart', () {
    late FakeHttpClient http;
    late FakeDataStore dataStore;
    late MessagePart message;
    late void Function() restoreIoc;

    setUp(() {
      http = FakeHttpClient();
      dataStore = FakeDataStore(http);
      final iocResult = createTestIoc(dataStore: dataStore);
      restoreIoc = iocResult.restore;
      message = MessagePart(FakeMarshaller(), dataStore);
    });

    tearDown(() => restoreIoc());

    final channelId = Snowflake('111');
    final messageId = Snowflake('222');

    group('pin', () {
      test('sends PUT to /channels/:channelId/pins/:messageId', () async {
        await message.pin(channelId, messageId);

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('PUT'));
        expect(http.calls.single.path, equals('/channels/111/pins/222'));
      });
    });

    group('unpin', () {
      test('sends DELETE to /channels/:channelId/pins/:messageId', () async {
        await message.unpin(channelId, messageId);

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('DELETE'));
        expect(http.calls.single.path, equals('/channels/111/pins/222'));
      });
    });

    group('crosspost', () {
      test(
        'sends POST to /channels/:channelId/messages/:messageId/crosspost',
        () async {
          await message.crosspost(channelId, messageId);

          expect(http.calls, hasLength(1));
          expect(http.calls.single.method, equals('POST'));
          expect(
            http.calls.single.path,
            equals('/channels/111/messages/222/crosspost'),
          );
        },
      );
    });

    group('delete', () {
      test(
        'sends DELETE to /channels/:channelId/messages/:messageId',
        () async {
          await message.delete(channelId, messageId);

          expect(http.calls, hasLength(1));
          expect(http.calls.single.method, equals('DELETE'));
          expect(http.calls.single.path, equals('/channels/111/messages/222'));
        },
      );
    });
  });
}
