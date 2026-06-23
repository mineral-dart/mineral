import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class MessageUpdatePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.messageUpdate;

  final MarshallerContract _marshaller;

  MessageUpdatePacket({required MarshallerContract marshaller})
      : _marshaller = marshaller;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final payload = message.payload as Map<String, dynamic>;
    final messageId = payload['id'] as String;
    final channelId = payload['channel_id'] as String;

    // Read cached message as `before` (nullable — cache miss is expected)
    final messageCacheKey =
        _marshaller.cacheKey.message(channelId, messageId);
    final rawBefore = await _marshaller.cache?.get(messageCacheKey);
    final before = rawBefore != null
        ? await _marshaller.serializers.message.serialize(rawBefore)
        : null;

    // Normalize + serialize the incoming payload as `after`
    final rawAfter = await _marshaller.serializers.message
        .normalize(payload);
    final after = await _marshaller.serializers.message.serialize(rawAfter);

    final serverId = Snowflake.nullable(payload['guild_id']);
    switch (serverId) {
      case String():
        dispatch<ServerMessageUpdateArgs>(
            event: Event.serverMessageUpdate,
            payload: (before: before as ServerMessage?, after: after as ServerMessage));
      default:
        dispatch<PrivateMessageUpdateArgs>(
            event: Event.privateMessageUpdate,
            payload: (before: before as PrivateMessage?, after: after as PrivateMessage));
    }
  }
}
