import 'package:mineral/src/api/common/message_reaction.dart';
import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/message_reaction_serializer.dart';
import 'package:test/test.dart';

import '../../helpers/fake_entity_context.dart';
import '../../helpers/fake_marshaller.dart';

void main() {
  group('MessageReactionSerializer', () {
    late MessageReactionSerializer serializer;

    setUp(() {
      serializer = MessageReactionSerializer(
        FakeMarshaller(),
        fakeEntityContext(),
      );
    });

    Map<String, dynamic> normalizedPayload() => {
          'guild_id': '987654321',
          'channel_id': '111222333',
          'author_id': '444555666',
          'message_id': '777888999',
          'emoji': {
            'id': '100200300',
            'name': 'thumbsup',
            'animated': true,
          },
          'is_burst': false,
          'type': 0,
        };

    Map<String, dynamic> rawDiscordPayload() => {
          'guild_id': '987654321',
          'channel_id': '111222333',
          'user_id': '444555666',
          'message_id': '777888999',
          'emoji': {
            'id': '100200300',
            'name': 'thumbsup',
            'animated': true,
          },
          'burst': false,
          'type': 0,
        };

    group('serialize()', () {
      test('maps all fields correctly', () async {
        final reaction = await serializer.serialize(normalizedPayload());

        expect(reaction, isA<MessageReaction>());
        expect(reaction.guildId, equals(Snowflake('987654321')));
        expect(reaction.channelId, equals(Snowflake('111222333')));
        expect(reaction.userId, equals(Snowflake('444555666')));
        expect(reaction.messageId, equals(Snowflake('777888999')));
        expect(reaction.isBurst, isFalse);
        expect(reaction.type, equals(MessageReactionType.normal));
      });

      test('constructs PartialEmoji from emoji sub-map', () async {
        final reaction = await serializer.serialize(normalizedPayload());

        expect(reaction.emoji.id, equals(Snowflake('100200300')));
        expect(reaction.emoji.name, equals('thumbsup'));
        expect(reaction.emoji.animated, isTrue);
      });

      test('defaults animated to false when absent', () async {
        final payload = normalizedPayload();
        final emoji = Map<String, dynamic>.from(payload['emoji'] as Map)
          ..remove('animated');
        payload['emoji'] = emoji;
        final reaction = await serializer.serialize(payload);

        expect(reaction.emoji.animated, isFalse);
      });

      test('defaults isBurst to false when null', () async {
        final payload = normalizedPayload()..['is_burst'] = null;
        final reaction = await serializer.serialize(payload);

        expect(reaction.isBurst, isFalse);
      });

      test('resolves MessageReactionType.burst for type 1', () async {
        final payload = normalizedPayload()..['type'] = 1;
        final reaction = await serializer.serialize(payload);

        expect(reaction.type, equals(MessageReactionType.burst));
      });

      test('handles nullable guildId', () async {
        final payload = normalizedPayload()..['guild_id'] = null;
        final reaction = await serializer.serialize(payload);

        expect(reaction.guildId, isNull);
      });
    });

    group('normalize()', () {
      test('renames guild_id to guild_id', () async {
        final result = await serializer.normalize(rawDiscordPayload());

        expect(result, containsPair('guild_id', '987654321'));
      });

      test('renames user_id to author_id', () async {
        final result = await serializer.normalize(rawDiscordPayload());

        expect(result, containsPair('author_id', '444555666'));
      });

      test('renames burst to is_burst', () async {
        final result = await serializer.normalize(rawDiscordPayload());

        expect(result, containsPair('is_burst', false));
      });

      test('preserves emoji sub-map', () async {
        final result = await serializer.normalize(rawDiscordPayload());

        expect(result['emoji'], isA<Map>());
        expect(result['emoji']['name'], equals('thumbsup'));
      });
    });

    group('deserialize()', () {
      // Anomaly: deserialize maps fields in a semantically inconsistent way
      // ('id' receives guildId, 'content' receives userId, etc.)
      test('produces a map with emoji sub-map', () async {
        final reaction = await serializer.serialize(normalizedPayload());
        final result = await serializer.deserialize(reaction);

        expect(result['emoji'], isA<Map>());
        expect(result['emoji']['id'], equals(Snowflake('100200300')));
        expect(result['emoji']['name'], equals('thumbsup'));
        expect(result['emoji']['animated'], isTrue);
      });

      test('preserves message_id', () async {
        final reaction = await serializer.serialize(normalizedPayload());
        final result = await serializer.deserialize(reaction);

        expect(result['message_id'], equals(Snowflake('777888999').value));
      });
    });
  });
}
