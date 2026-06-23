import 'package:mineral/events.dart';
import 'package:mineral/src/api/common/monetization/entitlement.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class EntitlementDeletePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.entitlementDelete;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final entitlement =
        Entitlement.fromJson(message.payload as Map<String, dynamic>);

    dispatch<EntitlementDeleteArgs>(
      event: Event.entitlementDelete,
      payload: (entitlement: entitlement),
    );
  }
}
