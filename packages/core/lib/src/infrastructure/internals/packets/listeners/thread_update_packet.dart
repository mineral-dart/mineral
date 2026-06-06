import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class ThreadUpdatePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.threadUpdate;

  final MarshallerContract _marshaller;
  final DataStoreContract _dataStore;

  ThreadUpdatePacket({
    required MarshallerContract marshaller,
    required DataStoreContract dataStore,
  })  : _marshaller = marshaller,
        _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final payload = message.payload as Map<String, dynamic>;

    final server = await _dataStore.server.get(payload['guild_id'] as Object, false);
    final threadCacheKey = _marshaller.cacheKey.thread(payload['id'] as Object);

    final beforeRaw = await _marshaller.cache?.getOrFail(threadCacheKey);
    final before = beforeRaw != null
        ? await _marshaller.serializers.channels.serialize(beforeRaw)
        : null;

    final afterRaw = await _marshaller.serializers.channels.normalize(payload);
    final after = await _marshaller.serializers.channels.serialize(afterRaw);

    dispatch<ServerThreadUpdateArgs>(event: Event.serverThreadUpdate, payload: (server: server, before: before as ThreadChannel?, after: after as ThreadChannel));
  }
}
