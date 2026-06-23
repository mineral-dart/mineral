import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class IntegrationDeletePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.integrationDelete;

  final DataStoreContract _dataStore;

  IntegrationDeletePacket({required DataStoreContract dataStore})
      : _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final server = await _dataStore.server
        .get(message.payload['guild_id'] as Object, false);

    final integrationId = Snowflake.parse(message.payload['id']);
    final applicationId = Snowflake.nullable(message.payload['application_id']);

    dispatch<ServerIntegrationDeleteArgs>(
      event: Event.serverIntegrationDelete,
      payload: (
        server: server,
        integrationId: integrationId,
        applicationId: applicationId
      ),
    );
  }
}
