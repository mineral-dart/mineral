import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class ThreadMemberUpdatePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.threadMemberUpdate;

  final DataStoreContract _dataStore;

  ThreadMemberUpdatePacket({required DataStoreContract dataStore})
    : _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final payload = message.payload as Map<String, dynamic>;
    final guild = await _dataStore.guild.get(
      payload['guild_id'] as Object,
      false,
    );
    final thread = await _dataStore.channel.get(payload['id'] as Object, false);

    final member = await _dataStore.member.get(
      guild.id.value,
      payload['user_id'] as Object,
      false,
    );

    dispatch<GuildThreadMemberArgs>(
      event: Event.guildThreadMemberUpdate,
      payload: (
        thread: thread! as ThreadChannel,
        guild: guild,
        member: member!,
      ),
    );
  }
}
