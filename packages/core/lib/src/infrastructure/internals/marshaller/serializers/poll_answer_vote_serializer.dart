import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/api/common/polls/poll_answer_vote.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/types/serializer.dart';

final class PollAnswerVoteSerializer
    implements SerializerContract<PollAnswerVote> {
  final MarshallerContract _marshaller;
  final EntityContext _ctx;

  DataStoreContract get _datastore => _ctx.datastore;

  PollAnswerVoteSerializer(this._marshaller, this._ctx);

  @override
  Future<Map<String, dynamic>> normalize(Map<String, dynamic> json) async {
    final payload = {
      'id': json['id'],
      'users': json['users'],
      'message_id': json['message_id'],
      'channel_id': json['channel_id'],
      'guild_id': json['guild_id'],
    };

    return payload;
  }

  @override
  Future<PollAnswerVote> serialize(Map<String, dynamic> json) async {
    final List<User> voters = [];
    final message = await _datastore.message.get<Message>(
      json['channel_id'] as Object,
      json['message_id'] as Object,
      false,
    );
    Guild? guild;
    for (final voter in json['users'] as Iterable<dynamic>) {
      final payload = await _marshaller.serializers.user.normalize(
        voter as Map<String, dynamic>,
      );
      final user = await _marshaller.serializers.user.serialize(payload);
      voters.add(user);
    }

    if (json['guild_id'] != null) {
      guild = await _datastore.guild.get(json['guild_id'] as Object, false);
    }

    return PollAnswerVote(
      id: json['id'] as int,
      voters: voters,
      message: message!,
      guild: guild,
    );
  }

  @override
  Map<String, dynamic> deserialize(PollAnswerVote answer) {
    final users = answer.voters.map((user) {
      return _marshaller.serializers.user.deserialize(user);
    }).toList();

    return {
      'id': answer.id,
      'users': users,
      'message_id': answer.message.id.value,
      'channel_id': answer.message.channelId.value,
      'guild_id': answer.guild?.id,
    };
  }
}
