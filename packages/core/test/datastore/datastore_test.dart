import 'package:mineral/src/infrastructure/internals/datastore/datastore.dart';
import 'package:mineral/src/infrastructure/internals/datastore/request_bucket.dart';
import 'package:mineral/src/infrastructure/services/http/http_client.dart';
import 'package:mineral/src/infrastructure/services/http/http_client_config.dart';
import 'package:mineral/src/testing/fake_logger.dart';
import 'package:test/test.dart';

import '../helpers/fake_marshaller.dart';

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('DataStore', () {
    late DataStore dataStore;

    setUp(() {
      final config = HttpClientConfigImpl(
        uri: Uri.parse('https://discord.com/api/v10'),
      );
      final client = HttpClient(config: config);
      dataStore = DataStore(
        client: client,
        marshaller: FakeMarshaller(),
        logger: FakeLogger(),
        httpLogger: FakeLogger(),
      );
    });

    test('stores the HttpClient', () {
      expect(dataStore.client, isA<HttpClient>());
    });

    test('requestBucket is initialized', () {
      expect(dataStore.requestBucket, isA<RequestBucket>());
    });

    test('requestBucket queue is empty', () {
      expect(dataStore.requestBucket.queue, isEmpty);
    });

    test('requestBucket has no global lock', () {
      expect(dataStore.requestBucket.registry.globalLockedUntil, isNull);
    });

    test('all parts are initialized', () {
      expect(dataStore.channel, isNotNull);
      expect(dataStore.guild, isNotNull);
      expect(dataStore.member, isNotNull);
      expect(dataStore.user, isNotNull);
      expect(dataStore.role, isNotNull);
      expect(dataStore.message, isNotNull);
      expect(dataStore.interaction, isNotNull);
      expect(dataStore.sticker, isNotNull);
      expect(dataStore.emoji, isNotNull);
      expect(dataStore.reaction, isNotNull);
      expect(dataStore.thread, isNotNull);
      expect(dataStore.rules, isNotNull);
      expect(dataStore.invite, isNotNull);
    });
  });
}
