import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class GuildScheduledEventUserRemovePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.guildScheduledEventUserRemove;

  final DataStoreContract _dataStore;

  GuildScheduledEventUserRemovePacket({required DataStoreContract dataStore})
      : _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final guild = await _dataStore.guild
        .get(message.payload['guild_id'] as Object, false);

    final eventId =
        Snowflake.parse(message.payload['guild_scheduled_event_id'] as Object);

    final user = await _dataStore.user
        .get(message.payload['user_id'] as Object, false);

    if (user case User()) {
      dispatch<GuildScheduledEventUserRemoveArgs>(
        event: Event.guildScheduledEventUserRemove,
        payload: (guild: guild, eventId: eventId, user: user),
      );
    }
  }
}
