import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/container/ioc_container.dart';
import 'package:mineral/src/domains/events/event.dart';
import 'package:mineral/src/domains/services/cache/cache_invalidation.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class ThreadDeletePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.threadDelete;

  MarshallerContract get _marshaller => ioc.resolve<MarshallerContract>();

  DataStoreContract get _dataStore => ioc.resolve<DataStoreContract>();

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final payload = message.payload as Map<String, dynamic>;

    final server = await _dataStore.server.get(payload['guild_id'] as Object, false);

    final threadCacheKey = _marshaller.cacheKey.thread(payload['id'] as Object);
    final threadRaw = await _marshaller.cache?.getOrFail(threadCacheKey);
    final thread = threadRaw != null
        ? await _marshaller.serializers.channels.serialize(threadRaw)
        : null;

    await _marshaller.cache.invalidate(threadCacheKey);

    dispatch<ServerThreadDeleteArgs>(event: Event.serverThreadDelete, payload: (thread: thread as ThreadChannel?, server: server));
  }
}
