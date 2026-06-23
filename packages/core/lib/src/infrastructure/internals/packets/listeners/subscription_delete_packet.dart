import 'package:mineral/events.dart';
import 'package:mineral/src/api/common/monetization/subscription.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class SubscriptionDeletePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.subscriptionDelete;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final subscription =
        Subscription.fromJson(message.payload as Map<String, dynamic>);

    dispatch<SubscriptionDeleteArgs>(
      event: Event.subscriptionDelete,
      payload: (subscription: subscription),
    );
  }
}
