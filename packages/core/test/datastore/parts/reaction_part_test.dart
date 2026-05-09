import 'package:mineral/src/api/common/partial_emoji.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/reaction_part.dart';
import 'package:test/test.dart';

import '../../helpers/fake_datastore.dart';
import '../../helpers/fake_http_client.dart';
import '../../helpers/fake_marshaller.dart';
import '../../helpers/ioc_test_helper.dart';

void main() {
  group('ReactionPart', () {
    late FakeHttpClient http;
    late FakeDataStore dataStore;
    late ReactionPart reaction;
    late void Function() restoreIoc;

    setUp(() {
      http = FakeHttpClient();
      dataStore = FakeDataStore(http);
      final iocResult = createTestIoc(dataStore: dataStore);
      restoreIoc = iocResult.restore;
      reaction = ReactionPart(FakeMarshaller(), dataStore);
    });

    tearDown(() => restoreIoc());

    final unicode = PartialEmoji.fromUnicode('🔥');

    group('add', () {
      test(
          'sends PUT to /channels/:channelId/messages/:messageId/reactions/:emoji/@me',
          () async {
        await reaction.add('111', '222', unicode);

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('PUT'));
        expect(
          http.calls.single.path,
          equals('/channels/111/messages/222/reactions/${Uri.encodeComponent('🔥')}/@me'),
        );
      });
    });

    group('remove', () {
      test(
          'sends DELETE to /channels/:channelId/messages/:messageId/reactions/:emoji/@me',
          () async {
        await reaction.remove('111', '222', unicode);

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('DELETE'));
        expect(
          http.calls.single.path,
          equals('/channels/111/messages/222/reactions/${Uri.encodeComponent('🔥')}/@me'),
        );
      });
    });

    group('removeAll', () {
      test(
          'sends DELETE to /channels/:channelId/messages/:messageId/reactions',
          () async {
        await reaction.removeAll('111', '222');

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('DELETE'));
        expect(http.calls.single.path,
            equals('/channels/111/messages/222/reactions'));
      });
    });

    group('removeForEmoji', () {
      test(
          'sends DELETE to /channels/:channelId/messages/:messageId/reactions/:emoji',
          () async {
        await reaction.removeForEmoji('111', '222', unicode);

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('DELETE'));
        expect(
          http.calls.single.path,
          equals('/channels/111/messages/222/reactions/${Uri.encodeComponent('🔥')}'),
        );
      });
    });

    group('removeForUser', () {
      test(
          'sends DELETE to /channels/:channelId/messages/:messageId/reactions/:emoji/:userId',
          () async {
        await reaction.removeForUser('999', '111', '222', unicode);

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('DELETE'));
        expect(
          http.calls.single.path,
          equals('/channels/111/messages/222/reactions/${Uri.encodeComponent('🔥')}/999'),
        );
      });
    });
  });
}
