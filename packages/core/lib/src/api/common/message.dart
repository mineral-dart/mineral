import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/api/common/managers/reaction_manager.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

abstract interface class BaseMessage {
  ReactionManger get reactions;

  Snowflake get id;

  String get content;

  bool get authorIsBot;

  List<MessageEmbed> get embeds;

  Snowflake get channelId;

  Snowflake? get authorId;

  DateTime get createdAt;

  DateTime? get updatedAt;

  Future<T> resolveChannel<T extends Channel>();

  /// Reply to the message with a new message.
  ///
  /// ```dart
  /// {@macro message_component_builder}
  ///
  /// await message.reply(builder);
  /// ```
  Future<T> reply<T extends Message>(MessageBuilder builder);

  /// Edit the message with a new message.
  ///
  /// ```dart
  /// {@macro message_component_builder}
  ///
  /// await message.edit(builder);
  /// ```
  Future<void> edit(MessageBuilder builder);
}

abstract interface class ServerMessage implements BaseMessage {
  Snowflake get serverId;

  Future<Member> resolveMember({bool force = false});

  /// Resolve the server where the message was sent.
  /// ```dart
  /// final server = await message.resolveServer();
  /// ```
  /// This will return a [Server] object.
  /// If the server is not cached, you can force the fetch by passing `force: true`.
  /// ```dart
  /// final server = await message.resolveServer(force: true);
  /// ```
  Future<Server> resolveServer({bool force = false});
}

abstract interface class PrivateMessage implements BaseMessage {
  Future<User> resolveUser({bool force = false});
}

final class Message implements ServerMessage, PrivateMessage, BaseMessage {
  final EntityContext _ctx;
  DataStoreContract get _datastore => _ctx.datastore;
  final MessageProperties _properties;

  @override
  final ReactionManger reactions;

  @override
  Snowflake get id => _properties.id;

  @override
  String get content => _properties.content;

  @override
  bool get authorIsBot => _properties.authorIsBot;

  @override
  List<MessageEmbed> get embeds => _properties.embeds;

  @override
  Snowflake get channelId => _properties.channelId;

  @override
  Snowflake get serverId => _properties.serverId!;

  @override
  Snowflake? get authorId => _properties.authorId;

  @override
  DateTime get createdAt => _properties.createdAt;

  @override
  DateTime? get updatedAt => _properties.updatedAt;

  Message(this._properties, {required EntityContext ctx})
      : _ctx = ctx,
        reactions = ReactionManger(_properties.id.value,
            _properties.channelId.value,
            ctx: ctx);

  @override
  Future<void> edit(MessageBuilder builder) async {
    await _datastore.message
        .update(id: id.value, channelId: channelId.value, builder: builder);
  }

  @override
  Future<Member> resolveMember({bool force = false}) async {
    final member =
        await _datastore.member.get(serverId!.value, authorId!.value, force);
    return member!;
  }

  @override
  Future<User> resolveUser({bool force = false}) async {
    final user = await _datastore.user.get(authorId!.value, force);
    return user!;
  }

  @override
  Future<T> resolveChannel<T extends Channel>() async {
    final channel = await _datastore.channel.get<T>(channelId.value, false);
    return channel!;
  }

  @override
  Future<Server> resolveServer({bool force = false}) =>
      _datastore.server.get(serverId!.value, force);

  @override
  Future<T> reply<T extends Message>(MessageBuilder builder) async {
    return _datastore.message.reply(id, channelId, builder);
  }

  /// Pin the message.
  ///
  /// ```dart
  /// await message.pin();
  /// ```
  Future<void> pin() async {
    await _datastore.message.pin(channelId, id);
  }

  /// Unpin the message.
  ///
  /// ```dart
  /// await message.unpin();
  /// ```
  Future<void> unpin() async {
    await _datastore.message.unpin(channelId, id);
  }

  /// Crosspost the message.
  ///
  /// ```dart
  /// await message.crosspost(); // only works for guild announcements
  /// ```
  Future<void> crosspost() async {
    final channel = await resolveChannel();
    if (channel.type != ChannelType.guildAnnouncement) {
      return;
    }

    await _datastore.message.crosspost(channelId, id);
  }

  /// Delete the message.
  ///
  /// ```dart
  /// await message.delete();
  /// ```
  Future<void> delete() => _datastore.message.delete(channelId, id);

  /// Create a thread from the message.
  /// ```dart
  /// final thread = await message.createThread<PublicThreadChannel>(builder);
  /// ```
  /// This will return a [ThreadChannel] object.
  /// The `builder` parameter is a [ThreadChannelBuilder] object.
  /// ```dart
  /// final builder = ChannelBuilder.thread(ChannelType.guildPublicThread)
  ///   ..setDefaultAutoArchiveDuration(Duration(seconds: 3600));
  ///
  ///  final thread = await message.createThread<PublicThreadChannel>(builder);
  ///  ```
  Future<T> createThread<T extends ThreadChannel>(
          ThreadChannelBuilder builder) =>
      _datastore.thread.createFromMessage<T>(
          serverId.value, channelId.value, id?.value, builder);
}
