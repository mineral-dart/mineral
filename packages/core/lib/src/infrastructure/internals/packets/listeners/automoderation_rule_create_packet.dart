import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class AutomoderationRuleCreatePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.autoModerationRuleCreate;

  final MarshallerContract _marshaller;

  AutomoderationRuleCreatePacket({required MarshallerContract marshaller})
      : _marshaller = marshaller;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final rawRule =
        await _marshaller.serializers.rules.normalize(message.payload as Map<String, dynamic>);
    final rule = await _marshaller.serializers.rules.serialize(rawRule);

    dispatch<GuildRuleCreateArgs>(event: Event.guildRuleCreate, payload: (rule: rule));
  }
}
