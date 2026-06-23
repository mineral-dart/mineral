import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/api/server/guild_scheduled_event.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class GuildScheduledEventUpdatePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.guildScheduledEventUpdate;

  final MarshallerContract _marshaller;
  final DataStoreContract _dataStore;

  GuildScheduledEventUpdatePacket({
    required MarshallerContract marshaller,
    required DataStoreContract dataStore,
  })  : _marshaller = marshaller,
        _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final server = await _dataStore.server
        .get(message.payload['guild_id'] as Object, false);

    // Retrieve the cached version as "before"
    final cacheKey = _marshaller.cacheKey.scheduledEvent(
      message.payload['guild_id'] as Object,
      message.payload['id'] as Object,
    );
    final rawBefore = await _marshaller.cache?.get(cacheKey);
    final GuildScheduledEvent? before = rawBefore != null
        ? await _marshaller.serializers.scheduledEvent.serialize(rawBefore)
        : null;

    // Serialize the incoming payload as "after"
    final rawAfter = await _marshaller.serializers.scheduledEvent
        .normalize(message.payload as Map<String, dynamic>);
    final after =
        await _marshaller.serializers.scheduledEvent.serialize(rawAfter);

    dispatch<ServerScheduledEventUpdateArgs>(
      event: Event.serverScheduledEventUpdate,
      payload: (server: server, before: before, after: after),
    );
  }
}
