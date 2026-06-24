import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class VoiceConnectPacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.voiceStateUpdate;

  final MarshallerContract _marshaller;

  VoiceConnectPacket({required MarshallerContract marshaller})
    : _marshaller = marshaller;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final payload = message.payload as Map<String, dynamic>;
    final cacheKey = _marshaller.cacheKey.voiceState(
      payload['guild_id'] as Object,
      payload['user_id'] as Object,
    );
    final before = await _marshaller.cache?.get(cacheKey);

    final rawVoiceState = await _marshaller.serializers.voice.normalize(
      payload,
    );
    final voiceState = await _marshaller.serializers.voice.serialize(
      rawVoiceState,
    );

    if (before == null && payload['channel_id'] != null) {
      dispatch<VoiceConnectArgs>(
        event: Event.voiceConnect,
        payload: (state: voiceState),
      );
    }
  }
}
