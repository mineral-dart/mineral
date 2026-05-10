import 'package:mineral/events.dart';
import 'package:mineral/src/domains/events/event.dart';
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
    final serverCacheKey =
        _marshaller.cacheKey.server(message.payload['id'] as Object);
    final rawServer = await _marshaller.cache?.get(serverCacheKey);
    final before = rawServer != null
        ? await _marshaller.serializers.server.serialize(rawServer)
        : null;

    final rawAfter = await _marshaller.serializers.server
        .normalize(message.payload as Map<String, dynamic>);
    final after = await _marshaller.serializers.server.serialize(rawAfter);

    dispatch<ServerUpdateArgs>(
        event: Event.serverUpdate, payload: (before: before, after: after));
  }
}
