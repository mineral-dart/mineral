import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class MessageReactionRemovePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.messageReactionRemove;

  final MarshallerContract _marshaller;

  MessageReactionRemovePacket({required MarshallerContract marshaller})
      : _marshaller = marshaller;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final raw =
        await _marshaller.serializers.reaction.normalize(message.payload as Map<String, dynamic>);
    final reaction = await _marshaller.serializers.reaction.serialize(raw);

    final serverId = Snowflake.nullable(message.payload['guild_id']);
    switch (serverId) {
      case String():
        dispatch<ServerMessageReactionRemoveArgs>(
            event: Event.serverMessageReactionRemove,
            payload: (reaction: reaction));
      default:
        dispatch<PrivateMessageReactionRemoveArgs>(
            event: Event.privateMessageReactionRemove,
            payload: (reaction: reaction));
    }
  }
}
