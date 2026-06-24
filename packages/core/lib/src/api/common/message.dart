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

  /// The type of the message reference, if present.
  /// `null` for messages with no reference. [MessageReferenceType.forward]
  /// when the message is a forwarded message.
  MessageReferenceType? get referenceType;

  /// Snapshots of the forwarded messages, when [isForwarded] is `true`.
  List<MessageSnapshot> get snapshots;

  /// Whether this message is a forwarded message.
  bool get isForwarded;

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

  /// Forward this message to another channel.
  ///
  /// ```dart
  /// final forwarded = await message.forward<Message>(targetChannelId);
  /// ```
  Future<T> forward<T extends Message>(Snowflake targetChannelId);
}

abstract interface class GuildMessage implements BaseMessage {
  Snowflake get guildId;

  Future<Member> resolveMember({bool force = false});

  /// Resolve the guild where the message was sent.
  /// ```dart
  /// final guild = await message.resolveServer();
  /// ```
  /// This will return a [Guild] object.
  /// If the guild is not cached, you can force the fetch by passing `force: true`.
  /// ```dart
  /// final guild = await message.resolveServer(force: true);
  /// ```
  Future<Guild> resolveServer({bool force = false});
}

abstract interface class PrivateMessage implements BaseMessage {
  Future<User> resolveUser({bool force = false});
}

final class Message implements GuildMessage, PrivateMessage, BaseMessage {
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
  Snowflake get guildId => _properties.guildId!;

  @override
  Snowflake? get authorId => _properties.authorId;

  @override
  DateTime get createdAt => _properties.createdAt;

  @override
  DateTime? get updatedAt => _properties.updatedAt;

  @override
  MessageReferenceType? get referenceType => _properties.referenceType;

  @override
  List<MessageSnapshot> get snapshots => _properties.snapshots;

  @override
  bool get isForwarded => referenceType == MessageReferenceType.forward;

  Message(this._properties, {required EntityContext ctx})
    : _ctx = ctx,
      reactions = ReactionManger(
        _properties.id.value,
        _properties.channelId.value,
        ctx: ctx,
      );

  @override
  Future<void> edit(MessageBuilder builder) async {
    await _datastore.message.update(
      id: id.value,
      channelId: channelId.value,
      builder: builder,
    );
  }

  @override
  Future<Member> resolveMember({bool force = false}) async {
    final member = await _datastore.member.get(
      guildId!.value,
      authorId!.value,
      force,
    );
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
  Future<Guild> resolveServer({bool force = false}) =>
      _datastore.guild.get(guildId!.value, force);

  @override
  Future<T> reply<T extends Message>(MessageBuilder builder) async {
    return _datastore.message.reply(id, channelId, builder);
  }

  @override
  Future<T> forward<T extends Message>(Snowflake targetChannelId) async {
    return _datastore.message.forward<T>(
      targetChannelId,
      messageId: id,
      sourceChannelId: channelId,
    );
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
    ThreadChannelBuilder builder,
  ) => _datastore.thread.createFromMessage<T>(
    guildId.value,
    channelId.value,
    id?.value,
    builder,
  );
}
