import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/container/ioc_container.dart';
import 'package:mineral/src/domains/services/cache/cache_invalidation.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class MessageDeletePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.messageDelete;

  MarshallerContract get _marshaller => ioc.resolve<MarshallerContract>();

  DataStoreContract get _dataStore => ioc.resolve<DataStoreContract>();

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final payload = message.payload as Map<String, dynamic>;
    final messageId = Snowflake.parse(payload['id']);
    final channelId = Snowflake.parse(payload['channel_id']);

    final messageCacheKey =
        _marshaller.cacheKey.message(channelId.value, messageId.value);
    final rawMessage = await _marshaller.cache?.get(messageCacheKey);
    final cachedMessage = rawMessage != null
        ? await _marshaller.serializers.message.serialize(rawMessage)
        : null;

    await _marshaller.cache.invalidate(messageCacheKey);

    final guildId = Snowflake.nullable(payload['guild_id']);
    switch (guildId) {
      case Snowflake():
        final server = await _dataStore.server.get(guildId.value, false);
        final channel =
            await _dataStore.channel.get(channelId.value, false);
        if (channel is! ServerChannel) {
          return;
        }
        dispatch<ServerMessageDeleteArgs>(
            event: Event.serverMessageDelete,
            payload: (
              server: server,
              channel: channel,
              messageId: messageId,
              message: cachedMessage,
            ));
      default:
        final channel =
            await _dataStore.channel.get(channelId.value, false);
        if (channel is! PrivateChannel) {
          return;
        }
        dispatch<PrivateMessageDeleteArgs>(
            event: Event.privateMessageDelete,
            payload: (
              channel: channel,
              messageId: messageId,
              message: cachedMessage,
            ));
    }
  }
}
