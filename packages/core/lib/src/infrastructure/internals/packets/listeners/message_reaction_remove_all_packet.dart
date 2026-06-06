import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class MessageReactionRemoveAllPacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.messageReactionRemoveAll;

  final DataStoreContract _dataStore;

  MessageReactionRemoveAllPacket({required DataStoreContract dataStore})
      : _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final serverId = Snowflake.nullable(message.payload['guild_id']);
    final channelId = Snowflake.parse(message.payload['channel_id']);
    final messageId = Snowflake.parse(message.payload['message_id']);

    if (serverId != null) {
      await _server(dispatch, serverId, channelId, messageId);
    } else {
      await _private(dispatch, channelId, messageId);
    }
  }

  Future<void> _server(DispatchEvent dispatch, Snowflake serverId,
      Snowflake channelId, Snowflake messageId) async {
    final channel =
        await _dataStore.channel.get<ServerTextChannel>(channelId.value, false);
    final message = await channel?.messages.get(messageId);
    final server = await _dataStore.server.get(serverId.value, false);

    dispatch<ServerMessageReactionRemoveAllArgs>(
        event: Event.serverMessageReactionRemoveAll,
        payload: (server: server, channel: channel!, message: message! as Message));
  }

  Future<void> _private(
      DispatchEvent dispatch, Snowflake channelId, Snowflake messageId) async {
    final channel =
        await _dataStore.channel.get<PrivateChannel>(channelId.value, false);
    final message = await channel?.messages.get(messageId);

    dispatch<PrivateMessageReactionRemoveAllArgs>(
        event: Event.privateMessageReactionRemoveAll,
        payload: (channel: channel!, message: message! as Message));
  }
}
