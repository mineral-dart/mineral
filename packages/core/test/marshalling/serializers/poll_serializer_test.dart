import 'package:mineral/src/api/common/polls/poll.dart';
import 'package:mineral/src/api/common/polls/poll_layout.dart';
import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/poll_serializer.dart';
import 'package:test/test.dart';

import '../../helpers/fake_cache_provider.dart';
import '../../helpers/fake_marshaller.dart';

void main() {
  group('PollSerializer', () {
    late PollSerializer serializer;
    late FakeCacheProvider cache;

    setUp(() {
      cache = FakeCacheProvider();
      serializer = PollSerializer(FakeMarshaller(cache: cache));
    });

    Map<String, dynamic> serializePayload() => {
      'message_id': '777888999',
      'question_text': 'What is your favorite color?',
      'answers': [
        {'text': 'Red', 'emoji': null},
        {'text': 'Blue', 'emoji': null},
      ],
      'expiry': null,
      'allow_multiselect': false,
      'layout_type': 1,
    };

    Map<String, dynamic> rawDiscordPayload() => {
      'message_id': '777888999',
      'question': {'text': 'What is your favorite color?'},
      'answers': [
        {'text': 'Red'},
        {'text': 'Blue'},
      ],
      'expiry': null,
      'allow_multiselect': false,
      'layout_type': 1,
    };

    group('serialize()', () {
      test('maps question correctly', () {
        final poll = serializer.serialize(serializePayload());

        expect(poll, isA<Poll>());
        expect(poll.question.content, equals('What is your favorite color?'));
      });

      test('maps answers list', () {
        final poll = serializer.serialize(serializePayload());

        expect(poll.answers, hasLength(2));
        expect(poll.answers[0].content, equals('Red'));
        expect(poll.answers[1].content, equals('Blue'));
      });

      test('maps messageId', () {
        final poll = serializer.serialize(serializePayload());

        expect(poll.messageId, equals(Snowflake('777888999')));
      });

      test('handles null expiry', () {
        final poll = serializer.serialize(serializePayload());

        expect(poll.expireAt, isNull);
      });

      test('maps allow_multiselect', () {
        final poll = serializer.serialize(serializePayload());

        expect(poll.isAllowMultiple, isFalse);
      });

      test('resolves PollLayout.initial for layout_type 1', () {
        final poll = serializer.serialize(serializePayload());

        expect(poll.layout, equals(PollLayout.initial));
      });
    });

    group('deserialize()', () {
      test('produces map with expected keys', () {
        final poll = serializer.serialize(serializePayload());
        final result = serializer.deserialize(poll);

        expect(result['question_text'], equals('What is your favorite color?'));
        expect(result['allow_multiselect'], isFalse);
        expect(result['layout_type'], equals(PollLayout.initial.value));
      });

      test('question is serialized via toJson', () {
        final poll = serializer.serialize(serializePayload());
        final result = serializer.deserialize(poll);

        expect(result['question'], isA<Map>());
        expect(
          result['question']['text'],
          equals('What is your favorite color?'),
        );
      });

      test('answers are serialized as list', () {
        final poll = serializer.serialize(serializePayload());
        final result = serializer.deserialize(poll);

        expect(result['answers'], isA<List>());
        expect(result['answers'], hasLength(2));
      });
    });

    group('normalize()', () {
      test('writes to cache with poll key', () async {
        await serializer.normalize(rawDiscordPayload());

        expect(cache.store.isNotEmpty, isTrue);
      });

      test('extracts question text from nested object', () async {
        final result = await serializer.normalize(rawDiscordPayload());

        expect(result['question_text'], equals('What is your favorite color?'));
      });
    });

    group('round-trip', () {
      test('serialize then deserialize preserves key data', () {
        final json = serializePayload();
        final poll = serializer.serialize(json);
        final result = serializer.deserialize(poll);

        expect(result['allow_multiselect'], equals(json['allow_multiselect']));
        expect(result['layout_type'], equals(json['layout_type']));
        expect(result['question_text'], equals(json['question_text']));
      });
    });
  });
}
