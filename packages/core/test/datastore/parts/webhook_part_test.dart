import 'package:mineral/api.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/webhook_part.dart';
import 'package:test/test.dart';

import '../../helpers/fake_datastore.dart';
import '../../helpers/fake_http_client.dart';
import '../../helpers/fake_marshaller.dart';
import '../../helpers/fake_response.dart';
import '../../helpers/ioc_test_helper.dart';

void main() {
  group('WebhookPart', () {
    late FakeHttpClient http;
    late FakeDataStore dataStore;
    late WebhookPart webhook;
    late void Function() restoreIoc;

    setUp(() {
      http = FakeHttpClient();
      dataStore = FakeDataStore(http);
      final iocResult = createTestIoc(dataStore: dataStore);
      restoreIoc = iocResult.restore;
      webhook = WebhookPart(FakeMarshaller(), dataStore);
    });

    tearDown(() => restoreIoc());

    Map<String, dynamic> webhookResponse() => {
          'id': '111111111111111111',
          'type': 1,
          'guild_id': '222222222222222222',
          'channel_id': '333333333333333333',
          'user': {'id': '444444444444444444'},
          'name': 'My Webhook',
          'avatar': null,
          'token': 'secret-token',
          'application_id': null,
          'url':
              'https://discord.com/api/webhooks/111111111111111111/secret-token',
        };

    Map<String, dynamic> messageResponse() => {
          'id': '999999999999999999',
          'channel_id': '333333333333333333',
          'author': {'id': '444444444444444444'},
          'content': 'hello',
          'timestamp': '2024-01-01T00:00:00.000Z',
          'edited_timestamp': null,
          'tts': false,
          'mention_everyone': false,
          'mentions': <dynamic>[],
          'mention_roles': <dynamic>[],
          'attachments': <dynamic>[],
          'embeds': <dynamic>[],
          'pinned': false,
          'type': 0,
        };

    void rebuildWith(List<Object> outcomes) {
      restoreIoc();
      http = FakeHttpClient(outcomes);
      dataStore = FakeDataStore(http);
      final marshaller = FakeMarshaller();
      final iocResult =
          createTestIoc(dataStore: dataStore, marshaller: marshaller);
      restoreIoc = iocResult.restore;
      webhook = WebhookPart(marshaller, dataStore);
    }

    group('fetchForChannel', () {
      test('sends GET to /channels/:channelId/webhooks', () async {
        rebuildWith([
          FakeResponse<List<Map<String, dynamic>>>(200, [webhookResponse()]),
        ]);

        final result = await webhook.fetchForChannel('333333333333333333');

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('GET'));
        expect(http.calls.single.path,
            equals('/channels/333333333333333333/webhooks'));
        expect(result, hasLength(1));
      });
    });

    group('fetchForServer', () {
      test('sends GET to /guilds/:serverId/webhooks', () async {
        rebuildWith([
          FakeResponse<List<Map<String, dynamic>>>(200, [webhookResponse()]),
        ]);

        final result = await webhook.fetchForServer('222222222222222222');

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('GET'));
        expect(http.calls.single.path,
            equals('/guilds/222222222222222222/webhooks'));
        expect(result, hasLength(1));
      });
    });

    group('get', () {
      test('sends GET to /webhooks/:id when not cached', () async {
        rebuildWith(
            [FakeResponse<Map<String, dynamic>>(200, webhookResponse())]);

        final result = await webhook.get('111111111111111111', false);

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('GET'));
        expect(http.calls.single.path, equals('/webhooks/111111111111111111'));
        expect(result, isNotNull);
      });
    });

    group('getWithToken', () {
      test('sends GET to /webhooks/:id/:token', () async {
        rebuildWith(
            [FakeResponse<Map<String, dynamic>>(200, webhookResponse())]);

        await webhook.getWithToken('111111111111111111', 'secret-token');

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('GET'));
        expect(http.calls.single.path,
            equals('/webhooks/111111111111111111/secret-token'));
      });
    });

    group('create', () {
      test('sends POST to /channels/:channelId/webhooks', () async {
        rebuildWith(
            [FakeResponse<Map<String, dynamic>>(200, webhookResponse())]);

        final result = await webhook.create(
          channelId: '333333333333333333',
          name: 'My Webhook',
        );

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('POST'));
        expect(http.calls.single.path,
            equals('/channels/333333333333333333/webhooks'));
        expect(result.name, equals('My Webhook'));
      });
    });

    group('update', () {
      test('sends PATCH to /webhooks/:id', () async {
        rebuildWith(
            [FakeResponse<Map<String, dynamic>>(200, webhookResponse())]);

        await webhook.update(id: '111111111111111111', name: 'New Name');

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('PATCH'));
        expect(http.calls.single.path, equals('/webhooks/111111111111111111'));
      });
    });

    group('updateWithToken', () {
      test('sends PATCH to /webhooks/:id/:token', () async {
        rebuildWith(
            [FakeResponse<Map<String, dynamic>>(200, webhookResponse())]);

        await webhook.updateWithToken(
          id: '111111111111111111',
          token: 'secret-token',
          name: 'New Name',
        );

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('PATCH'));
        expect(http.calls.single.path,
            equals('/webhooks/111111111111111111/secret-token'));
      });
    });

    group('delete', () {
      test('sends DELETE to /webhooks/:id', () async {
        await webhook.delete(id: '111111111111111111');

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('DELETE'));
        expect(http.calls.single.path, equals('/webhooks/111111111111111111'));
      });
    });

    group('deleteWithToken', () {
      test('sends DELETE to /webhooks/:id/:token', () async {
        await webhook.deleteWithToken(
          id: '111111111111111111',
          token: 'secret-token',
        );

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('DELETE'));
        expect(http.calls.single.path,
            equals('/webhooks/111111111111111111/secret-token'));
      });
    });

    group('execute', () {
      test('sends POST to /webhooks/:id/:token and returns null when wait=false',
          () async {
        final builder = MessageBuilder()..addText('hello');

        final result = await webhook.execute(
          id: '111111111111111111',
          token: 'secret-token',
          builder: builder,
          wait: false,
        );

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('POST'));
        expect(http.calls.single.path,
            equals('/webhooks/111111111111111111/secret-token'));
        expect(result, isNull);
      });

      test('returns a Message when wait=true and response is not empty',
          () async {
        rebuildWith(
            [FakeResponse<Map<String, dynamic>>(200, messageResponse())]);
        final builder = MessageBuilder()..addText('hello');

        final result = await webhook.execute(
          id: '111111111111111111',
          token: 'secret-token',
          builder: builder,
        );

        expect(result, isNotNull);
      });
    });

    group('getMessage', () {
      test(
          'sends GET to /webhooks/:id/:token/messages/:messageId and returns null on empty body',
          () async {
        final result = await webhook.getMessage(
          id: '111111111111111111',
          token: 'secret-token',
          messageId: '999999999999999999',
        );

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('GET'));
        expect(
            http.calls.single.path,
            equals(
                '/webhooks/111111111111111111/secret-token/messages/999999999999999999'));
        expect(result, isNull);
      });
    });

    group('editMessage', () {
      test(
          'sends PATCH to /webhooks/:id/:token/messages/:messageId and returns null on empty body',
          () async {
        final builder = MessageBuilder()..addText('edited');

        final result = await webhook.editMessage(
          id: '111111111111111111',
          token: 'secret-token',
          messageId: '999999999999999999',
          builder: builder,
        );

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('PATCH'));
        expect(
            http.calls.single.path,
            equals(
                '/webhooks/111111111111111111/secret-token/messages/999999999999999999'));
        expect(result, isNull);
      });
    });

    group('deleteMessage', () {
      test(
          'sends DELETE to /webhooks/:id/:token/messages/:messageId',
          () async {
        await webhook.deleteMessage(
          id: '111111111111111111',
          token: 'secret-token',
          messageId: '999999999999999999',
        );

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('DELETE'));
        expect(
            http.calls.single.path,
            equals(
                '/webhooks/111111111111111111/secret-token/messages/999999999999999999'));
      });
    });

    group('executeGithub', () {
      test('sends POST to /webhooks/:id/:token/github', () async {
        await webhook.executeGithub(
          id: '111111111111111111',
          token: 'secret-token',
          payload: {'foo': 'bar'},
        );

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('POST'));
        expect(http.calls.single.path,
            equals('/webhooks/111111111111111111/secret-token/github'));
      });
    });

    group('executeSlack', () {
      test('sends POST to /webhooks/:id/:token/slack', () async {
        await webhook.executeSlack(
          id: '111111111111111111',
          token: 'secret-token',
          payload: {'text': 'hi'},
        );

        expect(http.calls, hasLength(1));
        expect(http.calls.single.method, equals('POST'));
        expect(http.calls.single.path,
            equals('/webhooks/111111111111111111/secret-token/slack'));
      });
    });
  });
}
