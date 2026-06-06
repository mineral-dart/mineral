import 'package:mineral/src/api/common/partial_emoji.dart';
import 'package:mineral/src/api/common/polls/poll.dart';
import 'package:mineral/src/api/common/polls/poll_answer.dart';
import 'package:mineral/src/api/common/polls/poll_layout.dart';
import 'package:mineral/src/api/common/polls/poll_question.dart';
import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/domains/common/utils/helper.dart';
import 'package:mineral/src/domains/common/utils/utils.dart';
import 'package:mineral/src/domains/services/marshaller/marshaller.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/types/serializer.dart';

final class PollSerializer implements SerializerContract<Poll> {
  final MarshallerContract _marshaller;

  PollSerializer(this._marshaller);

  @override
  Future<Map<String, dynamic>> normalize(Map<String, dynamic> json) async {
    final payload = {
      'message_id': json['message_id'],
      'question_text': (json['question'] as Map<String, dynamic>)['text'],
      'answers':
          List.from(json['answers'] as Iterable<dynamic>).map((element) => (element as Map<String, dynamic>)['text']).toList(),
      'expiry': json['expiry'],
      'allow_multiselect': json['allow_multiselect'],
      'layout_type': json['layout_type'],
    };

    final cacheKey = _marshaller.cacheKey.poll(json['message_id'] as String);
    await _marshaller.cache?.put(cacheKey, payload);

    return payload;
  }

  @override
  Poll serialize(Map<String, dynamic> json) {
    return Poll(
        messageId: Snowflake.nullable(json['message_id'] as String?),
        question: PollQuestion(content: json['question_text'] as String),
        answers: List.from(json['answers'] as Iterable<dynamic>)
            .map((element) {
              final el = element as Map<String, dynamic>;
              return PollAnswer(
                content: el['text'] as String,
                emoji: Helper.createOrNull(
                    field: el['emoji'],
                    fn: () => PartialEmoji.fromUnicode(el['emoji'] as String)));
            })
            .toList(),
        expireAt: Helper.createOrNull(
            field: json['expiry'],
            fn: () =>
                DateTime.parse(json['expiry'] as String).difference(DateTime.now())),
        isAllowMultiple: json['allow_multiselect'] as bool,
        layout: findInEnum(PollLayout.values, json['layout_type'],
            orElse: PollLayout.unknown));
  }

  @override
  Map<String, dynamic> deserialize(Poll poll) {
    final answers = poll.answers.map((element) {
      return element.toJson();
    }).toList();

    return {
      'message_id': poll.messageId?.value,
      'question': poll.question.toJson(),
      'question_text': poll.question.content,
      'answers': answers,
      'expiry': poll.expireAt?.inMilliseconds,
      'allow_multiselect': poll.isAllowMultiple,
      'layout_type': poll.layout.value,
    };
  }
}
