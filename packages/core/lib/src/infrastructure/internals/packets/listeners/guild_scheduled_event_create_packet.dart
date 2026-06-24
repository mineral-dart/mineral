import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class GuildScheduledEventCreatePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.guildScheduledEventCreate;

  final MarshallerContract _marshaller;
  final DataStoreContract _dataStore;

  GuildScheduledEventCreatePacket({
    required MarshallerContract marshaller,
    required DataStoreContract dataStore,
  })  : _marshaller = marshaller,
        _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final guild = await _dataStore.guild
        .get(message.payload['guild_id'] as Object, false);

    final raw = await _marshaller.serializers.scheduledEvent
        .normalize(message.payload as Map<String, dynamic>);
    final event = await _marshaller.serializers.scheduledEvent.serialize(raw);

    dispatch<GuildScheduledEventCreateArgs>(
      event: Event.guildScheduledEventCreate,
      payload: (guild: guild, event: event),
    );
  }
}
