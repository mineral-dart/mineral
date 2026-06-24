import 'package:mineral/api.dart';
import 'package:mineral/src/api/common/managers/message_manager.dart';
import 'package:mineral/src/api/guild/managers/threads_manager.dart';

final class GuildStageChannel extends GuildChannel {
  @override
  final ChannelProperties properties;

  @override
  late final ChannelMethods methods;

  late final MessageManager<GuildMessage> messages;

  String? get description => properties.description;

  ThreadsManager get threads => properties.threads;

  late final GuildCategoryChannel? category;

  GuildStageChannel(this.properties) {
    methods = ChannelMethods(
      properties.guildId!,
      properties.id,
      ctx: properties.ctx,
    );
    messages = MessageManager(properties.id, ctx: properties.ctx);
  }

  Future<void> setDescription(String description, {String? reason}) =>
      methods.setDescription(description, reason);

  Future<void> setCategory(String categoryId, {String? reason}) =>
      methods.setCategory(categoryId, reason);

  Future<void> setNsfw(bool nsfw, {String? reason}) =>
      methods.setNsfw(nsfw, reason);

  Future<void> setRateLimitPerUser(Duration value, {String? reason}) =>
      methods.setRateLimitPerUser(value, reason);

  Future<void> setDefaultAutoArchiveDuration(
    Duration value, {
    String? reason,
  }) => methods.setDefaultAutoArchiveDuration(value, reason);

  Future<void> setDefaultThreadRateLimitPerUser(
    Duration value, {
    String? reason,
  }) => methods.setDefaultThreadRateLimitPerUser(value, reason);

  /// Starts a new stage instance for this channel.
  Future<StageInstance> startStageInstance({
    required String topic,
    StagePrivacyLevel? privacyLevel,
    bool? sendStartNotification,
    Object? guildScheduledEventId,
    String? reason,
  }) => properties.ctx.datastore.stageInstance.create(
    channelId: properties.id.value,
    topic: topic,
    privacyLevel: privacyLevel,
    sendStartNotification: sendStartNotification,
    guildScheduledEventId: guildScheduledEventId,
    reason: reason,
  );

  /// Fetches the current stage instance for this channel.
  Future<StageInstance> fetchStageInstance() =>
      properties.ctx.datastore.stageInstance.get(properties.id.value);

  /// Updates the stage instance for this channel.
  Future<StageInstance> editStageInstance({
    String? topic,
    StagePrivacyLevel? privacyLevel,
    String? reason,
  }) => properties.ctx.datastore.stageInstance.update(
    channelId: properties.id.value,
    topic: topic,
    privacyLevel: privacyLevel,
    reason: reason,
  );

  /// Ends (deletes) the stage instance for this channel.
  Future<void> endStageInstance({String? reason}) => properties
      .ctx
      .datastore
      .stageInstance
      .delete(channelId: properties.id.value, reason: reason);
}
