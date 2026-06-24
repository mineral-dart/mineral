import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class ThreadListSyncPacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.threadListSync;

  final MarshallerContract _marshaller;
  final DataStoreContract _dataStore;

  ThreadListSyncPacket({
    required MarshallerContract marshaller,
    required DataStoreContract dataStore,
  })  : _marshaller = marshaller,
        _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final payload = message.payload as Map<String, dynamic>;

    final guild = await _dataStore.guild.get(payload['guild_id'] as Object, false);
    final threadChannels = payload['threads'] as List<Map<String, dynamic>>;

    final threads = await threadChannels.map((element) async {
      final threadRaw =
          await _marshaller.serializers.channels.normalize(element);
      return _marshaller.serializers.channels.serialize(threadRaw);
    }).wait;

    dispatch<GuildThreadListSyncArgs>(event: Event.guildThreadListSync, payload: (threads: threads.cast<ThreadChannel>(), guild: guild));
  }
}
