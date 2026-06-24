import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class GuildSoundboardSoundUpdatePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.guildSoundboardSoundUpdate;

  final DataStoreContract _dataStore;

  GuildSoundboardSoundUpdatePacket({required DataStoreContract dataStore})
      : _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final payload = message.payload as Map<String, dynamic>;
    final guild =
        await _dataStore.guild.get(payload['guild_id'] as Object, false);
    final sound = SoundboardSound.fromJson(payload);

    dispatch<GuildSoundboardSoundUpdateArgs>(
      event: Event.guildSoundboardSoundUpdate,
      payload: (guild: guild, sound: sound),
    );
  }
}
