import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/api/common/managers/message_manager.dart';
import 'package:mineral/src/api/server/threads/thread_metadata.dart';

class PublicThreadChannel extends ServerChannel implements ThreadChannel {
  DataStoreContract get _datastore => properties.ctx.datastore;

  @override
  final ChannelProperties properties;

  @override
  late final ChannelMethods methods;

  late final MessageManager<ServerMessage> messages;

  final ThreadMetadata metadata;

  int get rateLimitPerUser => properties.rateLimitPerUser!;

  Snowflake? get lastMessageId => properties.lastMessageId;

  int get bitrate => properties.bitrate!;

  int get userLimit => properties.userLimit!;

  String? get rtcRegion => properties.rtcRegion;

  Snowflake get ownerId => Snowflake.parse(properties.ownerId!);

  DateTime? get lastPinTimestamp => properties.lastPinTimestamp != null
      ? DateTime.tryParse(properties.lastPinTimestamp!)
      : null;

  int get messageCount => properties.messageCount!;

  int get flags => properties.flags!;

  int get memberCount => properties.memberCount!;

  int get totalMessageSent => properties.totalMessageSent!;

  Snowflake? get parentId => properties.categoryId;

  PublicThreadChannel(this.properties, this.metadata) {
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

  Future<User> resolveOwner() async {
    final user = await _datastore.user.get(ownerId.value, false);
    return user!;
  }

  Future<void> send(MessageBuilder builder) =>
      methods.send(serverId: serverId, builder: builder);
}
