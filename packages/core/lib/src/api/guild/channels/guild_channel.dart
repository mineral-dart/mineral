import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';

abstract class GuildChannel implements Channel {
  DataStoreContract get _dataStore => properties.ctx.datastore;

  ChannelProperties get properties;

  ChannelMethods get methods;

  @override
  Snowflake get id => properties.id;

  @override
  ChannelType get type => properties.type;

  String get name => properties.name!;

  @override
  DateTime get createdAt => id.createdAt;

  Snowflake get guildId => properties.guildId!;

  int get position => properties.position!;

  List<ChannelPermissionOverwrite> get permissions => properties.permissions;

  Snowflake? get categoryId => properties.categoryId;

  /// Resolves the [Guild] the channel belongs to.
  Future<Guild> resolveServer({bool force = true}) =>
      _dataStore.guild.get(guildId.value, force);

  /// Updates the channel.
  Future<void> update(ChannelBuilderContract builder, {String? reason}) =>
      _dataStore.channel.update(
        id.value,
        builder,
        guildId: guildId.value,
        reason: reason,
      );

  Future<void> setName(String name, {String? reason}) =>
      methods.setName(name, reason);

  Future<void> setPosition(int position, {String? reason}) =>
      methods.setPosition(position, reason);

  Future<void> delete({String? reason}) => methods.delete(reason);

  @override
  T cast<T extends Channel>() => this as T;
}
