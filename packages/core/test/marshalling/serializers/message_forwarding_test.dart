import 'package:mineral/api.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/message_part.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/message_serializer.dart';
import 'package:test/test.dart';

import '../../helpers/fake_cache_provider.dart';
import '../../helpers/fake_datastore.dart';
import '../../helpers/fake_entity_context.dart';
import '../../helpers/fake_http_client.dart';
import '../../helpers/fake_marshaller.dart';
import '../../helpers/fake_response.dart';

void main() {
  group('Message forwarding — serializer/entity', () {
    late MessageSerializer serializer;
    late FakeCacheProvider cache;

    setUp(() {
      cache = FakeCacheProvider();
      serializer = MessageSerializer(
        FakeMarshaller(cache: cache),
        fakeEntityContext(),
      );
    });

    // ── helpers ──────────────────────────────────────────────────────────────

    /// A normalized payload that looks like a forwarded message (type=1).
    Map<String, dynamic> forwardedNormalizedPayload() => {
          'id': '111222333444555666',
          'author_id': '987654321098765432',
          'content': '',
          'embeds': <Map<String, dynamic>>[],
          'channel_id': '777888999000111222',
          'server_id': '123456789012345678',
          'author_is_bot': false,
          'timestamp': '2024-06-01T12:00:00.000Z',
          'edited_timestamp': null,
          'message_reference': {
            'type': 1,
            'message_id': '999888777666555444',
            'channel_id': '444555666777888999',
          },
          'message_snapshots': [
            {
              'message': {
                'type': 0,
                'content': 'This is the original forwarded content',
                'embeds': <Map<String, dynamic>>[],
                'timestamp': '2024-05-31T10:00:00.000Z',
                'edited_timestamp': null,
                'flags': 0,
              },
            },
          ],
        };

    /// A normalized payload for a plain (non-forwarded) message.
    Map<String, dynamic> plainNormalizedPayload() => {
          'id': '111222333444555666',
          'author_id': '987654321098765432',
          'content': 'Hello world!',
          'embeds': <Map<String, dynamic>>[],
          'channel_id': '777888999000111222',
          'server_id': '123456789012345678',
          'author_is_bot': false,
          'timestamp': '2024-06-01T12:00:00.000Z',
          'edited_timestamp': null,
          // no message_reference or message_snapshots
        };

    // ── forwarded message parsing ─────────────────────────────────────────────

    test('isForwarded is true when message_reference.type == 1', () async {
      final message = await serializer.serialize(forwardedNormalizedPayload());

      expect(message.isForwarded, isTrue);
    });

    test('referenceType is MessageReferenceType.forward for type=1', () async {
      final message = await serializer.serialize(forwardedNormalizedPayload());

      expect(message.referenceType, equals(MessageReferenceType.forward));
    });

    test('snapshots is non-empty for a forwarded message', () async {
      final message = await serializer.serialize(forwardedNormalizedPayload());

      expect(message.snapshots, hasLength(1));
    });

    test('snapshot content matches original message content', () async {
      final message = await serializer.serialize(forwardedNormalizedPayload());

      expect(
        message.snapshots.first.content,
        equals('This is the original forwarded content'),
      );
    });

    test('snapshot timestamp is parsed correctly', () async {
      final message = await serializer.serialize(forwardedNormalizedPayload());

      expect(message.snapshots.first.timestamp, isA<DateTime>());
      expect(
        message.snapshots.first.timestamp,
        equals(DateTime.parse('2024-05-31T10:00:00.000Z')),
      );
    });

    test('snapshot embeds defaults to empty list when not provided', () async {
      final message = await serializer.serialize(forwardedNormalizedPayload());

      expect(message.snapshots.first.embeds, isEmpty);
    });

    test('snapshot type field is parsed', () async {
      final message = await serializer.serialize(forwardedNormalizedPayload());

      expect(message.snapshots.first.type, equals(0));
    });

    test('snapshot flags field is parsed', () async {
      final message = await serializer.serialize(forwardedNormalizedPayload());

      expect(message.snapshots.first.flags, equals(0));
    });

    // ── plain message (regression) ────────────────────────────────────────────

    test('isForwarded is false for a plain message', () async {
      final message = await serializer.serialize(plainNormalizedPayload());

      expect(message.isForwarded, isFalse);
    });

    test('referenceType is null for a plain message', () async {
      final message = await serializer.serialize(plainNormalizedPayload());

      expect(message.referenceType, isNull);
    });

    test('snapshots is empty for a plain message', () async {
      final message = await serializer.serialize(plainNormalizedPayload());

      expect(message.snapshots, isEmpty);
    });

    // ── normalize carries through forwarding fields ───────────────────────────

    test('normalize carries message_reference through to payload', () async {
      final rawDiscordPayload = {
        'id': '111222333444555666',
        'author': {'id': '987654321098765432', 'bot': false},
        'content': '',
        'embeds': <Map<String, dynamic>>[],
        'channel_id': '777888999000111222',
        'guild_id': '123456789012345678',
        'timestamp': '2024-06-01T12:00:00.000Z',
        'edited_timestamp': null,
        'message_reference': {
          'type': 1,
          'message_id': '999888777666555444',
          'channel_id': '444555666777888999',
        },
        'message_snapshots': [
          {
            'message': {
              'type': 0,
              'content': 'forwarded content',
              'embeds': <Map<String, dynamic>>[],
              'timestamp': '2024-05-31T10:00:00.000Z',
              'edited_timestamp': null,
              'flags': 0,
            },
          },
        ],
      };

      final normalized = await serializer.normalize(rawDiscordPayload);

      expect(normalized['message_reference'], isNotNull);
      expect(
        (normalized['message_reference'] as Map<String, dynamic>)['type'],
        equals(1),
      );
      expect(normalized['message_snapshots'], isNotNull);
      expect(normalized['message_snapshots'], isA<List>());
    });

    test(
        'message_reference.type=0 produces referenceType == MessageReferenceType.default_',
        () async {
      final payload = plainNormalizedPayload()
        ..['message_reference'] = {
          'type': 0,
          'message_id': '999888777666555444',
          'channel_id': '444555666777888999',
        };

      final message = await serializer.serialize(payload);

      expect(message.referenceType, equals(MessageReferenceType.default_));
      expect(message.isForwarded, isFalse);
    });
  });

  // ── forward send ─────────────────────────────────────────────────────────────

  group('MessagePart.forward()', () {
    late FakeHttpClient http;
    late FakeDataStore dataStore;
    late FakeMarshaller marshaller;
    late MessagePart messagePart;

    /// A minimal Discord message payload that the server would return after
    /// receiving a forward request. It looks like a forwarded message.
    Map<String, dynamic> fakeForwardResponse() => {
          'id': '222333444555666777',
          'author': {'id': '987654321098765432', 'bot': false},
          'content': '',
          'embeds': <Map<String, dynamic>>[],
          'channel_id': '555666777888999000',
          'guild_id': '123456789012345678',
          'timestamp': '2024-06-01T14:00:00.000Z',
          'edited_timestamp': null,
          'message_reference': {
            'type': 1,
            'message_id': '111222333444555666',
            'channel_id': '777888999000111222',
          },
          'message_snapshots': [
            {
              'message': {
                'type': 0,
                'content': 'original content',
                'embeds': <Map<String, dynamic>>[],
                'timestamp': '2024-06-01T12:00:00.000Z',
                'edited_timestamp': null,
                'flags': 0,
              },
            },
          ],
        };

    setUp(() {
      http = FakeHttpClient([
        FakeResponse<Map<String, dynamic>>(200, fakeForwardResponse()),
      ]);
      dataStore = FakeDataStore(http);
      marshaller = FakeMarshaller(dataStore: dataStore);
      messagePart = MessagePart(marshaller, dataStore);
    });

    test('POSTs to /channels/{targetChannelId}/messages', () async {
      final targetChannelId = Snowflake('555666777888999000');
      final messageId = Snowflake('111222333444555666');
      final sourceChannelId = Snowflake('777888999000111222');

      await messagePart.forward<Message>(
        targetChannelId,
        messageId: messageId,
        sourceChannelId: sourceChannelId,
      );

      expect(http.calls, hasLength(1));
      expect(http.calls.first.method, equals('POST'));
      expect(
        http.calls.first.path,
        equals('/channels/555666777888999000/messages'),
      );
    });

    test('request body contains message_reference with type=1', () async {
      final targetChannelId = Snowflake('555666777888999000');
      final messageId = Snowflake('111222333444555666');
      final sourceChannelId = Snowflake('777888999000111222');

      await messagePart.forward<Message>(
        targetChannelId,
        messageId: messageId,
        sourceChannelId: sourceChannelId,
      );

      final request = http.requests.first;
      final body = request.body as Map<String, dynamic>;
      final ref = body['message_reference'] as Map<String, dynamic>;

      expect(ref['type'], equals(1));
      expect(ref['message_id'], equals('111222333444555666'));
      expect(ref['channel_id'], equals('777888999000111222'));
    });

    test('guildId is included in message_reference when provided', () async {
      final targetChannelId = Snowflake('555666777888999000');
      final messageId = Snowflake('111222333444555666');
      final sourceChannelId = Snowflake('777888999000111222');
      final guildId = Snowflake('123456789012345678');

      await messagePart.forward<Message>(
        targetChannelId,
        messageId: messageId,
        sourceChannelId: sourceChannelId,
        guildId: guildId,
      );

      final request = http.requests.first;
      final body = request.body as Map<String, dynamic>;
      final ref = body['message_reference'] as Map<String, dynamic>;

      expect(ref['guild_id'], equals('123456789012345678'));
    });

    test('guildId is omitted from message_reference when not provided',
        () async {
      final targetChannelId = Snowflake('555666777888999000');
      final messageId = Snowflake('111222333444555666');
      final sourceChannelId = Snowflake('777888999000111222');

      await messagePart.forward<Message>(
        targetChannelId,
        messageId: messageId,
        sourceChannelId: sourceChannelId,
      );

      final request = http.requests.first;
      final body = request.body as Map<String, dynamic>;
      final ref = body['message_reference'] as Map<String, dynamic>;

      expect(ref.containsKey('guild_id'), isFalse);
    });

    test('returns a Message and isForwarded is true', () async {
      final targetChannelId = Snowflake('555666777888999000');
      final messageId = Snowflake('111222333444555666');
      final sourceChannelId = Snowflake('777888999000111222');

      final result = await messagePart.forward<Message>(
        targetChannelId,
        messageId: messageId,
        sourceChannelId: sourceChannelId,
      );

      expect(result, isA<Message>());
      expect(result.isForwarded, isTrue);
    });
  });
}
