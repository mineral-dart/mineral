import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class SoundboardSoundsPacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.soundboardSounds;

  final DataStoreContract _dataStore;

  SoundboardSoundsPacket({required DataStoreContract dataStore})
      : _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final payload = message.payload as Map<String, dynamic>;
    final server =
        await _dataStore.server.get(payload['guild_id'] as Object, false);

    final rawSounds = (payload['soundboard_sounds'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final sounds = rawSounds.map(SoundboardSound.fromJson).toList();

    dispatch<ServerSoundboardSoundsArgs>(
      event: Event.serverSoundboardSounds,
      payload: (server: server, sounds: sounds),
    );
  }
}
