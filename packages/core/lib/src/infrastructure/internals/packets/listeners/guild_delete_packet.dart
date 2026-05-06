import 'package:mineral/events.dart';
import 'package:mineral/src/domains/container/ioc_container.dart';
import 'package:mineral/src/domains/events/event.dart';
import 'package:mineral/src/domains/services/cache/cache_invalidation.dart';
import 'package:mineral/src/domains/services/marshaller/marshaller.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class GuildDeletePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.guildDelete;

  MarshallerContract get _marshaller => ioc.resolve<MarshallerContract>();

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final cacheKey = _marshaller.cacheKey.server(message.payload['id'] as Object);
    final rawServer = await _marshaller.cache?.get(cacheKey);
    final server = rawServer != null
        ? await _marshaller.serializers.server.serialize(rawServer)
        : null;

    await _marshaller.cache.invalidate(cacheKey);

    dispatch<ServerDeleteArgs>(event: Event.serverDelete, payload: (server: server));
  }
}
