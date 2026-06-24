import 'package:mineral/events.dart';
import 'package:mineral/src/domains/services/marshaller/marshaller.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class GuildUpdatePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.guildUpdate;

  final MarshallerContract _marshaller;

  GuildUpdatePacket({required MarshallerContract marshaller})
      : _marshaller = marshaller;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final guildCacheKey =
        _marshaller.cacheKey.guild(message.payload['id'] as Object);
    final rawServer = await _marshaller.cache?.get(guildCacheKey);
    final before = rawServer != null
        ? await _marshaller.serializers.guild.serialize(rawServer)
        : null;

    final rawAfter = await _marshaller.serializers.guild
        .normalize(message.payload as Map<String, dynamic>);
    final after = await _marshaller.serializers.guild.serialize(rawAfter);

    dispatch<GuildUpdateArgs>(
        event: Event.guildUpdate, payload: (before: before, after: after));
  }
}
