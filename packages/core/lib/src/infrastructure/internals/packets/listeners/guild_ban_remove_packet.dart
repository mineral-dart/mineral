import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/services/cache/cache_invalidation.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class GuildBanRemovePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.guildBanRemove;

  final MarshallerContract _marshaller;
  final DataStoreContract _dataStore;

  GuildBanRemovePacket({
    required MarshallerContract marshaller,
    required DataStoreContract dataStore,
  })  : _marshaller = marshaller,
        _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final guild =
        await _dataStore.guild.get(message.payload['guild_id'] as Object, false);
    final user =
        await _dataStore.user.get((message.payload['user'] as Map<String, dynamic>)['id'] as Object, false);

    if (user case User(:final id)) {
      final memberCacheKey =
          _marshaller.cacheKey.member(guild.id.value, id.value);
      await _marshaller.cache.invalidate(memberCacheKey);

      dispatch<GuildBanRemoveArgs>(event: Event.guildBanRemove, payload: (user: user, guild: guild));
    }
  }
}
