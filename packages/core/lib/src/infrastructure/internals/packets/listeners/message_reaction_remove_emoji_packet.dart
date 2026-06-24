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
    final guildId = Snowflake.nullable(message.payload['guild_id']);
    final channelId = Snowflake.parse(message.payload['channel_id']);
    final messageId = Snowflake.parse(message.payload['message_id']);
    final emojiPayload = message.payload['emoji'] as Map<String, dynamic>?;
    final emoji = PartialEmoji(
      Snowflake.nullable(emojiPayload?['id']),
      (emojiPayload?['name'] as String?) ?? '',
      (emojiPayload?['animated'] as bool?) ?? false,
    );

    if (guildId != null) {
      await _guild(dispatch, guildId, channelId, messageId, emoji);
    } else {
      await _private(dispatch, channelId, messageId, emoji);
    }
  }

  Future<void> _guild(
    DispatchEvent dispatch,
    Snowflake guildId,
    Snowflake channelId,
    Snowflake messageId,
    PartialEmoji emoji,
  ) async {
    final channel = await _dataStore.channel.get<GuildTextChannel>(
      channelId.value,
      false,
    );
    final message = await channel?.messages.get(messageId);
    final guild = await _dataStore.guild.get(guildId.value, false);

    dispatch<GuildMessageReactionRemoveEmojiArgs>(
      event: Event.guildMessageReactionRemoveEmoji,
      payload: (
        guild: guild,
        channel: channel!,
        message: message! as Message,
        emoji: emoji,
      ),
    );
  }

  Future<void> _private(
    DispatchEvent dispatch,
    Snowflake channelId,
    Snowflake messageId,
    PartialEmoji emoji,
  ) async {
    final channel = await _dataStore.channel.get<PrivateChannel>(
      channelId.value,
      false,
    );
    final message = await channel?.messages.get(messageId);

    dispatch<PrivateMessageReactionRemoveEmojiArgs>(
      event: Event.privateMessageReactionRemoveEmoji,
      payload: (channel: channel!, message: message! as Message, emoji: emoji),
    );
  }
}
