import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

enum TypingType { guild, private }

/// Represents a typing indicator in a channel.
final class Typing {
  final EntityContext _ctx;
  DataStoreContract get _datastore => _ctx.datastore;

  /// The ID of the guild where the typing occurred.
  final Snowflake? guildId;

  /// The ID of the channel where the typing occurred.
  final Snowflake channelId;

  /// The ID of the user who is typing.
  final Snowflake userId;

  /// The timestamp when the typing started.
  final DateTime timestamp;

  Typing({
    required EntityContext ctx,
    required this.guildId,
    required this.channelId,
    required this.userId,
    required this.timestamp,
  }) : _ctx = ctx;

  TypingType get type =>
      guildId == null ? TypingType.private : TypingType.guild;

  /// Represents a typing indicator in a channel.
  ///
  /// Example:
  /// ```dart
  /// client.events.typing((Typing typing) async {
  ///   final user = await typing.resolveUser();
  ///
  ///   print('${user?.username} is typing');
  /// });
  /// ```
  ///
  /// Parameters:
  /// - [force] Whether to force fetch the user from the API instead of cache. Defaults to false.
  Future<User?> resolveUser({bool force = false}) {
    return _datastore.user.get(userId.value, force);
  }

  /// Resolves the member who is typing.
  ///
  /// Example:
  /// ```dart
  /// client.events.typing((Typing typing) async {
  ///   final member = await typing.resolveMember();
  ///
  ///   print('${member?.nickname ?? member?.user.username} is typing');
  /// });
  /// ```
  ///
  /// Parameters:
  /// - [force] Whether to force fetch the member from the API instead of cache. Defaults to false.
  Future<Member?> resolveMember({bool force = false}) {
    return _datastore.member.get(guildId!.value, userId.value, force);
  }

  /// Resolves the guild where the typing occurred.
  ///
  /// Example:
  /// ```dart
  /// client.events.typing((Typing typing) async {
  ///   final guild = await typing.resolveServer();
  ///   print('Someone is typing in ${guild?.name}');
  /// });
  /// ```
  ///
  /// Parameters:
  /// - [force] Whether to force fetch the guild from the API instead of cache. Defaults to false.
  Future<Guild?> resolveServer({bool force = false}) {
    return _datastore.guild.get(guildId!.value, force);
  }

  /// Resolves the channel where the typing occurred.
  ///
  /// Example:
  /// ```dart
  /// client.events.typing((Typing typing) async {
  ///   final channel = await typing.resolveChannel<TextChannel>();
  ///   print('Someone is typing in #${channel?.name}');
  /// });
  /// ```
  ///
  /// Parameters:
  /// - [force] Whether to force fetch the channel from the API instead of cache. Defaults to false.
  /// - [T] The type of channel to resolve. Must extend [Channel].
  Future<T> resolveChannel<T extends Channel>({bool force = false}) async {
    final channel = await _datastore.channel.get<T>(channelId.value, force);
    return channel!;
  }
}
