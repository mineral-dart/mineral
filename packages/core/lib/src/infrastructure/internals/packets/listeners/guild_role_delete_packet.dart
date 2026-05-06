import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/container/ioc_container.dart';
import 'package:mineral/src/domains/events/event.dart';
import 'package:mineral/src/domains/services/cache/cache_invalidation.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class GuildRoleDeletePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.guildRoleDelete;

  MarshallerContract get _marshaller => ioc.resolve<MarshallerContract>();

  DataStoreContract get _dataStore => ioc.resolve<DataStoreContract>();

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final server =
        await _dataStore.server.get(message.payload['guild_id'] as Object, false);

    final roleId = message.payload['role_id'];

    final roleCacheKey =
        _marshaller.cacheKey.serverRole(server.id.value, roleId as Object);
    final rawRole = await _marshaller.cache?.get(roleCacheKey);
    final role = rawRole != null
        ? await _marshaller.serializers.role.serialize(rawRole)
        : null;

    await _marshaller.cache.invalidate(roleCacheKey);

    dispatch<ServerRoleDeleteArgs>(event: Event.serverRoleDelete, payload: (server: server, role: role));
  }
}
