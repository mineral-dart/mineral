import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class MessageCreatePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.messageCreate;

  final MarshallerContract _marshaller;

  MessageCreatePacket({required MarshallerContract marshaller})
    : _marshaller = marshaller;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    if (![
      MessageType.initial.value,
      MessageType.reply.value,
    ].contains(message.payload['type'])) {
      return;
    }

    final payload = await _marshaller.serializers.message.normalize(
      message.payload as Map<String, dynamic>,
    );
    final serializedMessage = await _marshaller.serializers.message.serialize(
      payload,
    );

    final guildId = Snowflake.nullable(message.payload['guild_id']);
    switch (guildId) {
      case String():
        dispatch<GuildMessageCreateArgs>(
          event: Event.guildMessageCreate,
          payload: (message: serializedMessage as GuildMessage),
        );
      default:
        dispatch<PrivateMessageCreateArgs>(
          event: Event.privateMessageCreate,
          payload: (message: serializedMessage as PrivateMessage),
        );
    }
  }
}
