import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class MessageReactionRemoveEmojiPacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.messageReactionRemoveEmoji;

  final DataStoreContract _dataStore;

  MessageReactionRemoveEmojiPacket({required DataStoreContract dataStore})
      : _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final serverId = Snowflake.nullable(message.payload['guild_id']);
    final channelId = Snowflake.parse(message.payload['channel_id']);
    final messageId = Snowflake.parse(message.payload['message_id']);
    final emojiPayload = message.payload['emoji'] as Map<String, dynamic>?;
    final emoji = PartialEmoji(
      Snowflake.nullable(emojiPayload?['id']),
      (emojiPayload?['name'] as String?) ?? '',
      (emojiPayload?['animated'] as bool?) ?? false,
    );

    if (serverId != null) {
      await _server(dispatch, serverId, channelId, messageId, emoji);
    } else {
      await _private(dispatch, channelId, messageId, emoji);
    }
  }

  Future<void> _server(
      DispatchEvent dispatch,
      Snowflake serverId,
      Snowflake channelId,
      Snowflake messageId,
      PartialEmoji emoji) async {
    final channel =
        await _dataStore.channel.get<ServerTextChannel>(channelId.value, false);
    final message = await channel?.messages.get(messageId);
    final server = await _dataStore.server.get(serverId.value, false);

    dispatch<ServerMessageReactionRemoveEmojiArgs>(
        event: Event.serverMessageReactionRemoveEmoji,
        payload: (
          server: server,
          channel: channel!,
          message: message! as Message,
          emoji: emoji
        ));
  }

  Future<void> _private(
      DispatchEvent dispatch,
      Snowflake channelId,
      Snowflake messageId,
      PartialEmoji emoji) async {
    final channel =
        await _dataStore.channel.get<PrivateChannel>(channelId.value, false);
    final message = await channel?.messages.get(messageId);

    dispatch<PrivateMessageReactionRemoveEmojiArgs>(
        event: Event.privateMessageReactionRemoveEmoji,
        payload: (
          channel: channel!,
          message: message! as Message,
          emoji: emoji
        ));
  }
}
