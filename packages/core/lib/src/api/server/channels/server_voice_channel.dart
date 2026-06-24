import 'package:mineral/api.dart';
import 'package:mineral/src/api/common/managers/message_manager.dart';
import 'package:mineral/src/api/server/managers/threads_manager.dart';

final class ServerVoiceChannel extends ServerChannel {
  @override
  final ChannelProperties properties;

  @override
  late final ChannelMethods methods;

  late final MessageManager<ServerMessage> messages;

  ThreadsManager get threads => properties.threads;

  late final ServerCategoryChannel? category;

  late final List<VoiceState> members;

  ServerVoiceChannel(this.properties) {
    methods = ChannelMethods(properties.serverId!, properties.id,
        ctx: properties.ctx);
    messages = MessageManager(properties.id, ctx: properties.ctx);
  }

  Future<void> setCategory(String categoryId, {String? reason}) =>
      methods.setCategory(categoryId, reason);

  Future<void> setNsfw(bool nsfw, {String? reason}) =>
      methods.setNsfw(nsfw, reason);

  Future<void> setRateLimitPerUser(Duration value, {String? reason}) =>
      methods.setRateLimitPerUser(value, reason);

  Future<void> setBitrate(int bitrate, {String? reason}) =>
      methods.setBitrate(bitrate, reason);

  Future<void> setUserLimit(int userLimit, {String? reason}) =>
      methods.setUserLimit(userLimit, reason);

  Future<void> setRtcRegion(String rtcRegion, {String? reason}) =>
      methods.setRtcRegion(rtcRegion, reason);

  Future<void> setVideoQuality(VideoQuality quality, {String? reason}) =>
      methods.setVideoQuality(quality, reason);

  /// Send a soundboard sound to this voice channel.
  ///
  /// ```dart
  /// await voiceChannel.sendSoundboardSound(soundId);
  /// ```
  Future<void> sendSoundboardSound(
    Snowflake soundId, {
    Snowflake? sourceGuildId,
  }) =>
      properties.ctx.datastore.soundboard.sendToChannel(
        properties.id.value,
        soundId: soundId.value,
        sourceGuildId: sourceGuildId?.value,
      );
}
