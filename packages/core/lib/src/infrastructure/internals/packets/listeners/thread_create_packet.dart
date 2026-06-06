import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class ThreadCreatePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.threadCreate;

  final MarshallerContract _marshaller;
  final DataStoreContract _dataStore;

  ThreadCreatePacket({
    required MarshallerContract marshaller,
    required DataStoreContract dataStore,
  })  : _marshaller = marshaller,
        _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final payload = message.payload as Map<String, dynamic>;

    final server = await _dataStore.server.get(payload['guild_id'] as Object, false);
    final threadRaw = await _marshaller.serializers.channels.normalize(payload);
    final thread = await _marshaller.serializers.channels.serialize(threadRaw);

    dispatch<ServerThreadCreateArgs>(event: Event.serverThreadCreate, payload: (server: server, channel: thread as ThreadChannel));
  }
}
