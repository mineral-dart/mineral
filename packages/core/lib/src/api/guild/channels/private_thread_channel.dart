import 'package:mineral/api.dart';
import 'package:mineral/src/api/common/managers/message_manager.dart';
import 'package:mineral/src/api/guild/threads/thread_metadata.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

class PrivateThreadChannel extends GuildChannel implements ThreadChannel {
  @override
  late final ChannelProperties properties;

  @override
  late final ChannelMethods methods;

  late final MessageManager<GuildMessage> messages;

  @override
  ChannelType get type => ChannelType.guildPrivateThread;

  @override
  Snowflake get id => _id;

  @override
  String get name => _name;

  @override
  Snowflake get guildId => _guildId;

  final Snowflake _id;
  final String _name;
  final Snowflake _guildId;

  final String channelId;

  final ThreadMetadata metadata;

  final String? lastMessageId;

  final int rateLimitPerUser;

  final DateTime? lastPinTimestamp;

  final int messageCount;

  final int flags;

  final String ownerId;

  @override
  int get position => 0;

  @override
  List<ChannelPermissionOverwrite> get permissions => _permissions;

  final List<ChannelPermissionOverwrite> _permissions;

  PrivateThreadChannel({
    required EntityContext ctx,
    required Snowflake id,
    required String name,
    required Snowflake guildId,
    required this.channelId,
    required this.metadata,
    required this.lastMessageId,
    required this.rateLimitPerUser,
    required this.lastPinTimestamp,
    required this.messageCount,
    required this.flags,
    required this.ownerId,
    required List<ChannelPermissionOverwrite> permissions,
  })  : _id = id,
        _name = name,
        _guildId = guildId,
        _permissions = permissions {
    methods = ChannelMethods(null, id, ctx: ctx);
    messages = MessageManager(id, ctx: ctx);
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

  Future<void> send(MessageBuilder builder) =>
      methods.send(guildId: guildId, builder: builder);
}
