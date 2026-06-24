import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/services/cache/cache_invalidation.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class GuildMemberRemovePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.guildMemberRemove;

  final MarshallerContract _marshaller;
  final DataStoreContract _dataStore;

  GuildMemberRemovePacket({
    required MarshallerContract marshaller,
    required DataStoreContract dataStore,
  }) : _marshaller = marshaller,
       _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final guild = await _dataStore.guild.get(
      message.payload['guild_id'] as Object,
      false,
    );
    final userId =
        (message.payload['user'] as Map<String, dynamic>)['id'] as Object;
    final user = await _dataStore.user.get(userId, false);

    final memberCacheKey = _marshaller.cacheKey.member(guild.id.value, userId);
    await _marshaller.cache.invalidate(memberCacheKey);

    dispatch<GuildMemberRemoveArgs>(
      event: Event.guildMemberRemove,
      payload: (user: user, guild: guild),
    );
  }
}
