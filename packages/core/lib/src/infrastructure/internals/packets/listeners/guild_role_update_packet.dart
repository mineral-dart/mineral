import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/events/event.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class GuildRoleUpdatePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.guildRoleUpdate;

  final MarshallerContract _marshaller;
  final DataStoreContract _dataStore;

  GuildRoleUpdatePacket({
    required MarshallerContract marshaller,
    required DataStoreContract dataStore,
  })  : _marshaller = marshaller,
        _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final server =
        await _dataStore.server.get(message.payload['guild_id'] as Object, false);
    final roleCacheKey = _marshaller.cacheKey
        .serverRole(server.id.value, (message.payload['role'] as Map<String, dynamic>)['id'] as Object);

    final rawBefore = await _marshaller.cache?.get(roleCacheKey);
    final before = rawBefore != null
        ? await _marshaller.serializers.role.serialize(rawBefore)
        : null;

    final rawRole = await _marshaller.serializers.role.normalize({
      'guild_id': server.id,
      ...(message.payload['role'] as Map<String, dynamic>),
    });

    final role = await _marshaller.serializers.role.serialize(rawRole);

    dispatch<ServerRoleUpdateArgs>(event: Event.serverRoleUpdate, payload: (server: server, before: before, after: role));
  }
}
