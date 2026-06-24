import 'package:mineral/events.dart';
import 'package:mineral/src/domains/services/cache/cache_invalidation.dart';
import 'package:mineral/src/domains/services/marshaller/marshaller.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class GuildDeletePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.guildDelete;

  final MarshallerContract _marshaller;

  GuildDeletePacket({required MarshallerContract marshaller})
      : _marshaller = marshaller;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final cacheKey = _marshaller.cacheKey.guild(message.payload['id'] as Object);
    final rawServer = await _marshaller.cache?.get(cacheKey);
    final guild = rawServer != null
        ? await _marshaller.serializers.guild.serialize(rawServer)
        : null;

    await _marshaller.cache.invalidate(cacheKey);

    dispatch<GuildDeleteArgs>(event: Event.guildDelete, payload: (guild: guild));
  }
}
