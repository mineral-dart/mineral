import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/api/guild/integration.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class IntegrationCreatePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.integrationCreate;

  final DataStoreContract _dataStore;

  IntegrationCreatePacket({required DataStoreContract dataStore})
      : _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final guild = await _dataStore.guild
        .get(message.payload['guild_id'] as Object, false);

    final integration = Integration.fromJson(
        Map<String, dynamic>.from(message.payload as Map));

    dispatch<GuildIntegrationCreateArgs>(
      event: Event.guildIntegrationCreate,
      payload: (guild: guild, integration: integration),
    );
  }
}
