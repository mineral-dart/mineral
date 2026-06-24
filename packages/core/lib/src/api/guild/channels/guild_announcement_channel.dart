import 'package:mineral/api.dart';
import 'package:mineral/src/api/common/managers/message_manager.dart';
import 'package:mineral/src/api/guild/managers/threads_manager.dart';

final class GuildAnnouncementChannel extends GuildChannel {
  @override
  final ChannelProperties properties;

  @override
  late final ChannelMethods methods;

  late final MessageManager<GuildMessage> messages;

  String? get description => properties.description;

  bool get isNsfw => properties.nsfw;

  ThreadsManager get threads => properties.threads;

  late final GuildCategoryChannel? category;

  GuildAnnouncementChannel(this.properties) {
    methods = ChannelMethods(properties.guildId!, properties.id,
        ctx: properties.ctx);
    messages = MessageManager(properties.id, ctx: properties.ctx);
  }

  Future<void> setDescription(String description, {String? reason}) =>
      methods.setDescription(description, reason);

  Future<void> setCategory(String categoryId, {String? reason}) =>
      methods.setCategory(categoryId, reason);

  Future<void> setNsfw(bool nsfw, {String? reason}) =>
      methods.setNsfw(nsfw, reason);

  Future<T> send<T extends Message>(MessageBuilder builder) =>
      methods.send(guildId: properties.guildId, builder: builder);

  Future<T> sendPoll<T extends Message>(Poll poll) => methods.sendPoll<T>(poll);
}
