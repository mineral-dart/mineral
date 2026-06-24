import 'package:mineral/api.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/services/marshaller/marshaller.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/types/serializer.dart';

final class VoiceStateSerializer implements SerializerContract<VoiceState> {
  final MarshallerContract _marshaller;
  final EntityContext _ctx;

  VoiceStateSerializer(this._marshaller, this._ctx);

  @override
  Future<Map<String, dynamic>> normalize(Map<String, dynamic> json) async {
    final payload = {
      'guild_id': json['guild_id'],
      'channel_id': json['channel_id'],
      'user_id': json['user_id'],
      'session_id': json['session_id'],
      'deaf': json['deaf'],
      'mute': json['mute'],
      'self_deaf': json['self_deaf'],
      'self_mute': json['self_mute'],
      'self_video': json['self_video'],
      'suppress': json['suppress'],
      'request_to_speak_timestamp': json['request_to_speak_timestamp'],
      'discoverable': json['discoverable'],
    };

    final cacheKey = _marshaller.cacheKey.voiceState(
      json['guild_id'] as String,
      json['user_id'] as String,
    );
    await _marshaller.cache?.put(cacheKey, payload);

    return payload;
  }

  @override
  Future<VoiceState> serialize(Map<String, dynamic> json) async {
    return VoiceState(
      ctx: _ctx,
      guildId: Snowflake.parse(json['guild_id']),
      channelId: Snowflake.nullable(json['channel_id'] as String?),
      userId: Snowflake.parse(json['user_id']),
      sessionId: json['session_id'] as String?,
      isDeaf: json['deaf'] as bool,
      isMute: json['mute'] as bool,
      isSelfDeaf: json['self_deaf'] as bool,
      isSelfMute: json['self_mute'] as bool,
      hasSelfVideo: json['self_video'] as bool,
      isSuppress: json['suppress'] as bool,
      requestToSpeakTimestamp: json['request_to_speak_timestamp'] != null
          ? DateTime.parse(json['request_to_speak_timestamp'] as String)
          : null,
      isDiscoverable: json['discoverable'] as bool,
    );
  }

  @override
  Map<String, dynamic> deserialize(VoiceState state) {
    return {
      'guild_id': state.guildId.value,
      'channel_id': state.channelId?.value,
      'user_id': state.userId.value,
      'session_id': state.sessionId,
      'deaf': state.isDeaf,
      'mute': state.isMute,
      'self_deaf': state.isSelfDeaf,
      'self_mute': state.isSelfMute,
      'self_stream': state.hasSelfVideo,
      'suppress': state.isSuppress,
      'request_to_speak_timestamp': state.requestToSpeakTimestamp
          ?.toIso8601String(),
      'discoverable': state.isDiscoverable,
    };
  }
}
