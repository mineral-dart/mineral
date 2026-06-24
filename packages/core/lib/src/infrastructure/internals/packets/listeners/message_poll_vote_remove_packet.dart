import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class MessagePollVoteRemovePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.messagePollVoteRemove;

  final DataStoreContract _dataStore;

  MessagePollVoteRemovePacket({required DataStoreContract dataStore})
    : _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final payload = message.payload as Map<String, dynamic>;
    final user = await _dataStore.user.get(payload['user_id'] as String, false);

    if (payload['guild_id'] != null) {
      await _guild(payload, user!, dispatch);
    } else {
      await _private(payload, user!, dispatch);
    }
  }

  Future<void> _guild(
    Map<String, dynamic> payload,
    User user,
    DispatchEvent dispatch,
  ) async {
    final guild = await _dataStore.guild.get(
      payload['guild_id'] as String,
      false,
    );
    final message = await _dataStore.message.get<GuildMessage>(
      payload['channel_id'] as String,
      payload['message_id'] as String,
      false,
    );
    final answer = await _dataStore.message.getPollVotes(
      guild.id,
      Snowflake.parse(payload['channel_id']),
      message!.id,
      payload['answer_id'] as int,
    );

    dispatch<GuildPollVoteRemoveArgs>(
      event: Event.guildPollVoteRemove,
      payload: (answer: answer, user: user),
    );
  }

  Future<void> _private(
    Map<String, dynamic> payload,
    User user,
    DispatchEvent dispatch,
  ) async {
    final message = await _dataStore.message.get(
      payload['channel_id'] as String,
      payload['message_id'] as String,
      false,
    );
    final answer = await _dataStore.message.getPollVotes(
      null,
      Snowflake.parse(payload['channel_id']),
      message!.id,
      payload['answer_id'] as int,
    );

    dispatch<PrivatePollVoteRemoveArgs>(
      event: Event.privatePollVoteRemove,
      payload: (answer: answer, user: user),
    );
  }
}
