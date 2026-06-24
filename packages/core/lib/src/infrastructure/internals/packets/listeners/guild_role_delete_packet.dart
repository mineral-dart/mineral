import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/services/cache/cache_invalidation.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class GuildRoleDeletePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.guildRoleDelete;

  final MarshallerContract _marshaller;
  final DataStoreContract _dataStore;

  GuildRoleDeletePacket({
    required MarshallerContract marshaller,
    required DataStoreContract dataStore,
  })  : _marshaller = marshaller,
        _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final guild =
        await _dataStore.guild.get(message.payload['guild_id'] as Object, false);

    final roleId = message.payload['role_id'];

    final roleCacheKey =
        _marshaller.cacheKey.guildRole(guild.id.value, roleId as Object);
    final rawRole = await _marshaller.cache?.get(roleCacheKey);
    final role = rawRole != null
        ? await _marshaller.serializers.role.serialize(rawRole)
        : null;

    await _marshaller.cache.invalidate(roleCacheKey);

    dispatch<GuildRoleDeleteArgs>(event: Event.guildRoleDelete, payload: (guild: guild, role: role));
  }
}
