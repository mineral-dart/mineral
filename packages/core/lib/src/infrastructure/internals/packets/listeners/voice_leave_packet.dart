import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/events/event.dart';
import 'package:mineral/src/domains/services/cache/cache_invalidation.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class VoiceLeavePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.voiceStateUpdate;

  final MarshallerContract _marshaller;

  VoiceLeavePacket({required MarshallerContract marshaller})
      : _marshaller = marshaller;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final payload = message.payload as Map<String, dynamic>;
    final cacheKey = _marshaller.cacheKey.voiceState(
      payload['guild_id'] as Object,
      payload['user_id'] as Object,
    );
    final beforeRaw = await _marshaller.cache?.get(cacheKey);

    // Trigger VoiceLeaveEvent whenever a user leaves ANY channel (including moves and disconnects)
    if (beforeRaw != null &&
        beforeRaw['channel_id'] != null &&
        beforeRaw['channel_id'] != payload['channel_id']) {
      final before = await _marshaller.serializers.voice.serialize(beforeRaw);
      dispatch<VoiceLeaveArgs>(event: Event.voiceLeave, payload: (state: before));

      await _marshaller.cache.invalidate(cacheKey);
    }
  }
}
