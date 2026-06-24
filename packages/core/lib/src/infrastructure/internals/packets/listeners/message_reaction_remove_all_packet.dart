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
    final guildId = Snowflake.nullable(message.payload['guild_id']);
    final channelId = Snowflake.parse(message.payload['channel_id']);
    final messageId = Snowflake.parse(message.payload['message_id']);

    if (guildId != null) {
      await _guild(dispatch, guildId, channelId, messageId);
    } else {
      await _private(dispatch, channelId, messageId);
    }
  }

  Future<void> _guild(DispatchEvent dispatch, Snowflake guildId,
      Snowflake channelId, Snowflake messageId) async {
    final channel =
        await _dataStore.channel.get<GuildTextChannel>(channelId.value, false);
    final message = await channel?.messages.get(messageId);
    final guild = await _dataStore.guild.get(guildId.value, false);

    dispatch<GuildMessageReactionRemoveAllArgs>(
        event: Event.guildMessageReactionRemoveAll,
        payload: (guild: guild, channel: channel!, message: message! as Message));
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
