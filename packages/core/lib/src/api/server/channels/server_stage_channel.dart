import 'package:mineral/api.dart';
import 'package:mineral/src/api/common/managers/message_manager.dart';
import 'package:mineral/src/api/server/managers/threads_manager.dart';

final class ServerStageChannel extends ServerChannel {
  @override
  final ChannelProperties properties;

  @override
  late final ChannelMethods methods;

  late final MessageManager<ServerMessage> messages;

  String? get description => properties.description;

  ThreadsManager get threads => properties.threads;

  late final ServerCategoryChannel? category;

  ServerStageChannel(this.properties) {
    methods = ChannelMethods(properties.serverId!, properties.id,
        ctx: properties.ctx);
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

  Future<void> setDefaultAutoArchiveDuration(Duration value,
          {String? reason}) =>
      methods.setDefaultAutoArchiveDuration(value, reason);

  Future<void> setDefaultThreadRateLimitPerUser(Duration value,
          {String? reason}) =>
      methods.setDefaultThreadRateLimitPerUser(value, reason);
}
