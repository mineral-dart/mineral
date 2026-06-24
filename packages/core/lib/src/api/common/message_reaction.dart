import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

enum MessageReactionType {
  normal(0),
  burst(1);

  final int value;

  const MessageReactionType(this.value);
}

abstract class BaseMessageReaction {
  Snowflake get channelId;

  Snowflake get userId;

  Snowflake get messageId;

  PartialEmoji get emoji;

  bool get isBurst;

  MessageReactionType get type;

  Future<T> resolveChannel<T extends Channel>();

  Future<T> resolveMessage<T extends BaseMessage>({bool force = false});
}

abstract interface class GuildMessageReaction extends BaseMessageReaction {
  Snowflake? get guildId;

  Future<Member?> resolveMember();
}

abstract interface class PrivateMessageReaction extends BaseMessageReaction {
  Future<User> resolveUser();
}

final class MessageReaction
    implements GuildMessageReaction, PrivateMessageReaction {
  final EntityContext _ctx;
  DataStoreContract get _datastore => _ctx.datastore;

  @override
  final Snowflake? guildId;

  @override
  final Snowflake channelId;

  @override
  final Snowflake userId;

  @override
  final Snowflake messageId;

  @override
  final PartialEmoji emoji;

  @override
  final bool isBurst;

  @override
  final MessageReactionType type;

  MessageReaction({
    required EntityContext ctx,
    required this.guildId,
    required this.channelId,
    required this.userId,
    required this.messageId,
    required this.emoji,
    required this.isBurst,
    required this.type,
  }) : _ctx = ctx;

  /// Get related [User]
  /// ```dart
  /// final user = await reaction.resolveUser();
  /// ```
  @override
  Future<User> resolveUser() async {
    final user = await _datastore.user.get(userId.value, true);
    return user!;
  }

  /// Get related [Member]
  /// ```dart
  /// final member = await reaction.resolveMember();
  /// ```
  @override
  Future<Member?> resolveMember() =>
      _datastore.member.get(guildId!.value, userId.value, true);

  /// Get related [GuildVoiceChannel]
  /// ```dart
  /// final channel = await reaction.resolveChannel();
  /// ```
  @override
  Future<T> resolveChannel<T extends Channel>() async {
    final channel = await _datastore.channel.get<T>(messageId.value, true);
    return channel!;
  }

  /// Get related [Message]
  /// ```dart
  /// final message = await reaction.resolveMessage();
  /// ```
  @override
  Future<T> resolveMessage<T extends BaseMessage>({bool force = false}) async {
    final message = await _datastore.message
        .get<T>(channelId.value, messageId.value, force);
    return message!;
  }
}
