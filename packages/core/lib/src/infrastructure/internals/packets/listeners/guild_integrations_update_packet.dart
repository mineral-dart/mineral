import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class GuildIntegrationsUpdatePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.guildIntegrationsUpdate;

  final DataStoreContract _dataStore;

  GuildIntegrationsUpdatePacket({required DataStoreContract dataStore})
      : _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final server = await _dataStore.server
        .get(message.payload['guild_id'] as Object, false);

    dispatch<ServerIntegrationsUpdateArgs>(
      event: Event.serverIntegrationsUpdate,
      payload: (server: server),
    );
  }
}
