import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class VoiceJoinPacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.voiceStateUpdate;

  final MarshallerContract _marshaller;

  VoiceJoinPacket({required MarshallerContract marshaller})
    : _marshaller = marshaller;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final payload = message.payload as Map<String, dynamic>;
    final cacheKey = _marshaller.cacheKey.voiceState(
      payload['guild_id'] as Object,
      payload['user_id'] as Object,
    );
    final before = await _marshaller.cache?.get(cacheKey);

    // Trigger VoiceJoinEvent whenever a user joins ANY channel (including moves)
    if (payload['channel_id'] != null &&
        (before == null || before['channel_id'] != payload['channel_id'])) {
      final rawVoiceState = await _marshaller.serializers.voice.normalize(
        payload,
      );
      final voiceState = await _marshaller.serializers.voice.serialize(
        rawVoiceState,
      );
      dispatch<VoiceJoinArgs>(
        event: Event.voiceJoin,
        payload: (state: voiceState),
      );
    }
  }
}
