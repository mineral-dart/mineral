import 'package:mineral/src/infrastructure/internals/datastore/parts/invite_part.dart';
import 'package:test/test.dart';

import '../../helpers/fake_datastore.dart';
import '../../helpers/fake_http_client.dart';
import '../../helpers/fake_marshaller.dart';
import '../../helpers/fake_response.dart';
import '../../helpers/ioc_test_helper.dart';

void main() {
  group('InvitePart', () {
    late FakeHttpClient http;
    late FakeDataStore dataStore;
    late InvitePart invite;
    late void Function() restoreIoc;

    setUp(() {
      http = FakeHttpClient();
      dataStore = FakeDataStore(http);
      final iocResult = createTestIoc(dataStore: dataStore);
      restoreIoc = iocResult.restore;
      invite = InvitePart(FakeMarshaller(), dataStore);
    });

    tearDown(() => restoreIoc());

    group('delete', () {
      test('sends DELETE to /invites/:code', () async {
        await invite.delete('abc123', null);

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('DELETE'));
        expect(http.calls.single.path, equals('/invites/abc123'));
      });
    });

    group('create', () {
      Map<String, dynamic> inviteResponse() => {
            'code': 'abc123',
            'type': 0,
            'channel_id': '111111111111111111',
            'guild_id': '222222222222222222',
            'inviter': {'id': '333333333333333333'},
            'max_age': 86400,
            'max_uses': 0,
            'temporary': false,
            'created_at': '2024-01-01T00:00:00.000Z',
            'expires_at': null,
          };

      void rebuild(Map<String, dynamic> body) {
        restoreIoc();
        http = FakeHttpClient([FakeResponse<Map<String, dynamic>>(200, body)]);
        dataStore = FakeDataStore(http);
        final marshaller = FakeMarshaller();
        final iocResult =
            createTestIoc(dataStore: dataStore, marshaller: marshaller);
        restoreIoc = iocResult.restore;
        invite = InvitePart(marshaller, dataStore);
      }

      test('sends POST to /channels/:channelId/invites', () async {
        rebuild(inviteResponse());

        await invite.create(channelId: '111111111111111111');

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('POST'));
        expect(http.calls.single.path,
            equals('/channels/111111111111111111/invites'));
      });

      test('returns the created Invite', () async {
        rebuild(inviteResponse());

        final result =
            await invite.create(channelId: '111111111111111111');

        expect(result.code, equals('abc123'));
        expect(result.maxUses, equals(0));
        expect(result.isTemporary, isFalse);
      });
    });
  });
}
