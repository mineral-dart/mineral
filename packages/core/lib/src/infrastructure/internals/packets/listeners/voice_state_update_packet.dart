import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/services/cache/cache_invalidation.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

/// Single listener for `VOICE_STATE_UPDATE`.
///
/// Reads the previous voice state once, writes the new one at most once, and
/// derives every voice event from that single transition. It replaces the
/// former connect, join, move, leave and disconnect listeners.
///
/// `b` is the cached previous state, `b.ch` its channel, `ch` the channel of
/// the incoming payload, `a` the serialized incoming state.
///
/// | Event               | Fires when                                         | Payload                  |
/// |---------------------|----------------------------------------------------|--------------------------|
/// | `voiceConnect`      | `ch != null` and `b == null`                       | `(state: a)`             |
/// | `voiceJoin`         | `ch != null` and (`b == null` or `b.ch != ch`)     | `(state: a)`             |
/// | `voiceMove`         | `b != null`, `b.ch != null` and `ch != null`       | `(before: b, after: a)`  |
/// | `voiceLeave`        | `b != null`, `b.ch != null` and `b.ch != ch`       | `(state: b)`             |
/// | `voiceDisconnect`   | `ch == null` and `b != null`                       | `(state: b)`             |
/// | `voiceStateUpdate`  | always                                             | `(state: a)`             |
///
/// Cache effects: `ch != null` writes the new state once; `ch == null`
/// invalidates the entry and does not write.
///
/// Deliberately preserved from the former listeners: `voiceMove` also fires
/// when the channel is unchanged (mute/deaf updates).
///
/// Intentional difference: the former leave listener invalidated the entry on
/// a channel move, racing with the write of the new state. The entry is now
/// only invalidated on disconnect.
final class VoiceStateUpdatePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.voiceStateUpdate;

  final MarshallerContract _marshaller;

  VoiceStateUpdatePacket({required MarshallerContract marshaller})
    : _marshaller = marshaller;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final payload = message.payload as Map<String, dynamic>;
    final serializer = _marshaller.serializers.voice;
    final cacheKey = _marshaller.cacheKey.voiceState(
      payload['guild_id'] as Object,
      payload['user_id'] as Object,
    );

    final rawBefore = await _marshaller.cache?.get(cacheKey);
    final before = rawBefore != null
        ? await serializer.serialize(rawBefore)
        : null;
    final channelId = payload['channel_id'];

    if (channelId == null) {
      final after = await serializer.serialize(payload);
      await _marshaller.cache.invalidate(cacheKey);
      final guildId = payload['guild_id'];
      if (guildId != null) {
        await _marshaller.serializers.voiceStateIndex.remove(
          guildId.toString(),
          payload['user_id'].toString(),
        );
      }

      if (before != null) {
        dispatch<VoiceDisconnectArgs>(
          event: Event.voiceDisconnect,
          payload: (state: before),
        );
        if (before.channelId != null) {
          dispatch<VoiceLeaveArgs>(
            event: Event.voiceLeave,
            payload: (state: before),
          );
        }
      }

      dispatch<VoiceStateUpdateArgs>(
        event: Event.voiceStateUpdate,
        payload: (state: after),
      );
      return;
    }

    final after = await serializer.serialize(
      await serializer.normalize(payload),
    );
    final hadChannel = before != null && before.channelId != null;
    final changedChannel =
        rawBefore == null || rawBefore['channel_id'] != channelId;

    if (before == null) {
      dispatch<VoiceConnectArgs>(
        event: Event.voiceConnect,
        payload: (state: after),
      );
    }

    if (changedChannel) {
      dispatch<VoiceJoinArgs>(event: Event.voiceJoin, payload: (state: after));
    }

    if (hadChannel) {
      dispatch<VoiceMoveArgs>(
        event: Event.voiceMove,
        payload: (before: before, after: after),
      );
    }

    dispatch<VoiceStateUpdateArgs>(
      event: Event.voiceStateUpdate,
      payload: (state: after),
    );

    if (hadChannel && changedChannel) {
      dispatch<VoiceLeaveArgs>(
        event: Event.voiceLeave,
        payload: (state: before),
      );
    }
  }
}
