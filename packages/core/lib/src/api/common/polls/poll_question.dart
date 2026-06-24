import 'package:mineral/src/api/common/partial_emoji.dart';

final class PollQuestion {
  String content;
  PartialEmoji? emoji;

  PollQuestion({required this.content, this.emoji});

  Map<String, dynamic> toJson() {
    return {'text': content};
  }
}
