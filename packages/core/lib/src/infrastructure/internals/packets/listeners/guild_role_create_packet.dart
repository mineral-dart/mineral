import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/events/event.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class GuildRoleCreatePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.guildRoleCreate;

  final MarshallerContract _marshaller;
  final DataStoreContract _dataStore;

  GuildRoleCreatePacket({
    required MarshallerContract marshaller,
    required DataStoreContract dataStore,
  })  : _marshaller = marshaller,
        _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final server =
        await _dataStore.server.get(message.payload['guild_id'] as Object, false);
    final rawRole = await _marshaller.serializers.role.normalize({
      ...(message.payload['role'] as Map<String, dynamic>),
      'guild_id': server.id,
    });

    final role = await _marshaller.serializers.role.serialize(rawRole);
    dispatch<ServerRoleCreateArgs>(event: Event.serverRoleCreate, payload: (server: server, role: role));
  }
}
