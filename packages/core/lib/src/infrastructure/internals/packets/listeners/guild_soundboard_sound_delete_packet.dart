import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class GuildSoundboardSoundDeletePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.guildSoundboardSoundDelete;

  final DataStoreContract _dataStore;

  GuildSoundboardSoundDeletePacket({required DataStoreContract dataStore})
      : _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final payload = message.payload as Map<String, dynamic>;
    final server =
        await _dataStore.server.get(payload['guild_id'] as Object, false);
    final soundId = Snowflake.parse(payload['sound_id'] as Object);

    dispatch<ServerSoundboardSoundDeleteArgs>(
      event: Event.serverSoundboardSoundDelete,
      payload: (server: server, soundId: soundId),
    );
  }
}
