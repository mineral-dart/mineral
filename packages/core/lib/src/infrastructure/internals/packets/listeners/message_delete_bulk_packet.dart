import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/services/cache/cache_invalidation.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class MessageDeleteBulkPacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.messageDeleteBulk;

  final MarshallerContract _marshaller;
  final DataStoreContract _dataStore;

  MessageDeleteBulkPacket({
    required MarshallerContract marshaller,
    required DataStoreContract dataStore,
  })  : _marshaller = marshaller,
        _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final payload = message.payload as Map<String, dynamic>;
    final guildId = Snowflake.nullable(payload['guild_id']);
    if (guildId == null) {
      return;
    }

    final channelId = Snowflake.parse(payload['channel_id']);
    final messageIds =
        (payload['ids'] as List<dynamic>).map(Snowflake.parse).toList();

    final messages = <Snowflake, Message>{};
    for (final messageId in messageIds) {
      final messageCacheKey =
          _marshaller.cacheKey.message(channelId.value, messageId.value);
      final rawMessage = await _marshaller.cache?.get(messageCacheKey);
      if (rawMessage != null) {
        final cachedMessage =
            await _marshaller.serializers.message.serialize(rawMessage);
        messages[messageId] = cachedMessage;
      }
      await _marshaller.cache.invalidate(messageCacheKey);
    }

    final guild = await _dataStore.guild.get(guildId.value, false);
    final channel = await _dataStore.channel.get(channelId.value, false);
    if (channel is! GuildChannel) {
      return;
    }

    dispatch<GuildMessageDeleteBulkArgs>(
        event: Event.guildMessageDeleteBulk,
        payload: (
          guild: guild,
          channel: channel,
          messageIds: messageIds,
          messages: messages,
        ));
  }
}
