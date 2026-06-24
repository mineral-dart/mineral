import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class VoiceMovePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.voiceStateUpdate;

  final MarshallerContract _marshaller;

  VoiceMovePacket({required MarshallerContract marshaller})
    : _marshaller = marshaller;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final payload = message.payload as Map<String, dynamic>;
    final cacheKey = _marshaller.cacheKey.voiceState(
      payload['guild_id'] as Object,
      payload['user_id'] as Object,
    );
    final rawBefore = await _marshaller.cache?.get(cacheKey);

    final rawVoiceState = await _marshaller.serializers.voice.normalize(
      payload,
    );
    final voiceState = await _marshaller.serializers.voice.serialize(
      rawVoiceState,
    );

    if (rawBefore != null &&
        rawBefore['channel_id'] != null &&
        voiceState.channelId != null) {
      final before = await _marshaller.serializers.voice.serialize(rawBefore);
      dispatch<VoiceMoveArgs>(
        event: Event.voiceMove,
        payload: (before: before, after: voiceState),
      );
    }

    dispatch<VoiceStateUpdateArgs>(
      event: Event.voiceStateUpdate,
      payload: (state: voiceState),
    );
  }
}
