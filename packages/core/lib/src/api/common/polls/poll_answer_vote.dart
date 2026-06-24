import 'package:mineral/api.dart';

final class PollAnswerVote<T extends Message> {
  int id;
  List<User> voters;
  Guild? guild;
  T message;

  PollAnswerVote({
    required this.id,
    required this.voters,
    required this.message,
    this.guild,
  });
}
