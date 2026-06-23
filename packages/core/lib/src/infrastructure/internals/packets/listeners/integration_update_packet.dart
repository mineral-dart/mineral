import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/api/server/integration.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class IntegrationUpdatePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.integrationUpdate;

  final DataStoreContract _dataStore;

  IntegrationUpdatePacket({required DataStoreContract dataStore})
      : _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final server = await _dataStore.server
        .get(message.payload['guild_id'] as Object, false);

    final integration = Integration.fromJson(
        Map<String, dynamic>.from(message.payload as Map));

    dispatch<ServerIntegrationUpdateArgs>(
      event: Event.serverIntegrationUpdate,
      payload: (server: server, integration: integration),
    );
  }
}
