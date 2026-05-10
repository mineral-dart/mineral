import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class InviteDeletePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.inviteDelete;

  final DataStoreContract _datastore;

  InviteDeletePacket({required DataStoreContract dataStore})
      : _datastore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final code = message.payload['code'];
    final channel =
        await _datastore.channel.get(message.payload['channel_id'] as Object, false);

    dispatch<InviteDeleteArgs>(event: Event.inviteDelete, payload: (code: code, channel: channel));
  }
}
