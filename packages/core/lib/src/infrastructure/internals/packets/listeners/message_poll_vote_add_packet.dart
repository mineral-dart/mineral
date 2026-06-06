import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class MessagePollVoteAddPacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.messagePollVoteAdd;

  final DataStoreContract _dataStore;

  MessagePollVoteAddPacket({required DataStoreContract dataStore})
      : _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final payload = message.payload as Map<String, dynamic>;
    final user = await _dataStore.user.get(payload['user_id'] as String, false);

    if (payload['guild_id'] != null) {
      await _server(payload, user!, dispatch);
    } else {
      await _private(payload, user!, dispatch);
    }
  }

  Future<void> _server(
      Map<String, dynamic> payload, User user, DispatchEvent dispatch) async {
    final server = await _dataStore.server.get(payload['guild_id'] as String, false);
    final message = await _dataStore.message.get<ServerMessage>(
        payload['channel_id'] as String, payload['message_id'] as String, false);
    final answer = await _dataStore.message.getPollVotes(
        server.id,
        Snowflake.parse(payload['channel_id']),
        message!.id,
        payload['answer_id'] as int);

    dispatch<ServerPollVoteAddArgs>(event: Event.serverPollVoteAdd, payload: (answer: answer, user: user));
  }

  Future<void> _private(
      Map<String, dynamic> payload, User user, DispatchEvent dispatch) async {
    final message = await _dataStore.message
        .get(payload['channel_id'] as String, payload['message_id'] as String, false);
    final answer = await _dataStore.message.getPollVotes(
        null,
        Snowflake.parse(payload['channel_id']),
        message!.id,
        payload['answer_id'] as int);

    dispatch<PrivatePollVoteAddArgs>(event: Event.privatePollVoteAdd, payload: (answer: answer, user: user));
  }
}
