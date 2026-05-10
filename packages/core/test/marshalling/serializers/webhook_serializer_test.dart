import 'package:mineral/api.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/webhook_serializer.dart';
import 'package:test/test.dart';

import '../../helpers/fake_cache_provider.dart';
import '../../helpers/fake_entity_context.dart';
import '../../helpers/fake_marshaller.dart';

void main() {
  group('WebhookSerializer', () {
    late WebhookSerializer serializer;
    late FakeCacheProvider cache;

    setUp(() {
      cache = FakeCacheProvider();
      serializer = WebhookSerializer(
        FakeMarshaller(cache: cache),
        fakeEntityContext(),
      );
    });

    Map<String, dynamic> discordPayload() => {
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

    test('normalize maps Discord fields and writes cache', () async {
      final result = await serializer.normalize(discordPayload());
      expect(result['id'], equals('111111111111111111'));
      expect(result['type'], equals(1));
      expect(result['user_id'], equals('444444444444444444'));
      expect(result['name'], equals('My Webhook'));
      expect(cache.store.containsKey('webhooks/111111111111111111'), isTrue);
    });

    test('normalize handles missing user', () async {
      final payload = discordPayload()..remove('user');
      final result = await serializer.normalize(payload);
      expect(result['user_id'], isNull);
    });

    test('serialize builds a Webhook', () async {
      final raw = await serializer.normalize(discordPayload());
      final webhook = await serializer.serialize(raw);
      expect(webhook.id.value, equals('111111111111111111'));
      expect(webhook.type, equals(WebhookType.incoming));
      expect(webhook.name, equals('My Webhook'));
      expect(webhook.token, equals('secret-token'));
    });

    test('deserialize round-trips', () async {
      final raw = await serializer.normalize(discordPayload());
      final webhook = await serializer.serialize(raw);
      final back = serializer.deserialize(webhook);
      expect(back['id'], equals('111111111111111111'));
      expect(back['type'], equals(1));
      expect(back['name'], equals('My Webhook'));
    });
  });
}
