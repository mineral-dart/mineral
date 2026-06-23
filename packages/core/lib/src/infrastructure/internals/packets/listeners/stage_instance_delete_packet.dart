import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/api/server/stage_instance.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class StageInstanceDeletePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.stageInstanceDelete;

  final DataStoreContract _dataStore;

  StageInstanceDeletePacket({required DataStoreContract dataStore})
      : _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final server = await _dataStore.server
        .get(message.payload['guild_id'] as Object, false);

    final instance =
        StageInstance.fromJson(message.payload as Map<String, dynamic>);

    dispatch<ServerStageInstanceDeleteArgs>(
      event: Event.serverStageInstanceDelete,
      payload: (server: server, instance: instance),
    );
  }
}
