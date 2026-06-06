import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/api/common/presence.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class PresenceUpdatePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.presenceUpdate;

  final DataStoreContract _dataStore;

  PresenceUpdatePacket({required DataStoreContract dataStore})
      : _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final payload = message.payload as Map<String, dynamic>;
    final member = await _dataStore.member
        .get(payload['guild_id'] as Object, (payload['user'] as Map<String, dynamic>)['id'] as Object, false);
    final presence = Presence.fromJson(payload);

    dispatch<ServerPresenceUpdateArgs>(event: Event.serverPresenceUpdate, payload: (member: member!, presence: presence));
  }
}
