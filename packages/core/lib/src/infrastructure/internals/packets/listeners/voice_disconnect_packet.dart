import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/services/cache/cache_invalidation.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class VoiceDisconnectPacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.voiceStateUpdate;

  final MarshallerContract _marshaller;

  VoiceDisconnectPacket({required MarshallerContract marshaller})
      : _marshaller = marshaller;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final payload = message.payload as Map<String, dynamic>;
    if (payload['channel_id'] == null) {
      final cacheKey = _marshaller.cacheKey.voiceState(
        payload['guild_id'] as Object,
        payload['user_id'] as Object,
      );

      final beforeRaw = await _marshaller.cache?.get(cacheKey);
      final before = beforeRaw != null
          ? await _marshaller.serializers.voice.serialize(beforeRaw)
          : null;

      await _marshaller.cache.invalidate(cacheKey);

      if (before != null) {
        dispatch<VoiceDisconnectArgs>(event: Event.voiceDisconnect, payload: (state: before));
      }
    }
  }
}
