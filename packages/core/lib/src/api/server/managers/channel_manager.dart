import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class ChannelManager<C extends Channel> {
  final EntityContext _ctx;
  DataStoreContract get _datastore => _ctx.datastore;

  final Snowflake _serverId;
  final Snowflake? afkChannelId;
  final Snowflake? systemChannelId;
  final Snowflake? rulesChannelId;
  final Snowflake? publicUpdatesChannelId;
  final Snowflake? safetyAlertsChannelId;

  ChannelManager(
    this._serverId, {
    required EntityContext ctx,
    required this.afkChannelId,
    required this.systemChannelId,
    required this.rulesChannelId,
    required this.publicUpdatesChannelId,
    required this.safetyAlertsChannelId,
  }) : _ctx = ctx;

  /// Fetch the server's channels.
  /// ```dart
  /// final channels = await server.channels.fetch();
  /// ```
  Future<Map<Snowflake, C>> fetch({bool force = false}) =>
      _datastore.channel.fetch<C>(_serverId.value, force);

  /// Get a channel by its id.
  /// ```dart
  /// final channel = await server.channels.get('1091121140090535956');
  /// ```
  Future<T?> get<T extends C>(String id, {bool force = false}) =>
      _datastore.channel.get<T>(id, force);

  /// Create a channel.
  /// ```dart
  /// final channel = await server.channels.create<TextChannel>(builder, reason: 'Testing');
  /// ```
  Future<T> create<T extends C>(ChannelBuilderContract builder,
          {String? reason}) =>
      _datastore.channel.create<T>(_serverId.value, builder, reason: reason);

  /// Resolve the server's afk channel.
  /// ```dart
  /// final afkChannel = await server.channels.resolveAfkChannel();
  /// ```
  Future<ServerVoiceChannel?> resolveAfkChannel({bool force = false}) async {
    return switch (afkChannelId) {
      Snowflake(:final value) =>
        _datastore.channel.get<ServerVoiceChannel>(value, force),
      _ => null,
    };
  }

  /// Resolve the server's system channel.
  /// ```dart
  /// final systemChannel = await server.channels.resolveSystemChannel();
  /// ```
  Future<ServerTextChannel?> resolveSystemChannel({bool force = false}) async {
    return switch (systemChannelId) {
      Snowflake(:final value) =>
        _datastore.channel.get<ServerTextChannel>(value, force),
      _ => null,
    };
  }

  /// Resolve the server's rules channel.
  /// ```dart
  /// final rulesChannel = await server.channels.resolveRulesChannel();
  /// ```
  Future<ServerTextChannel?> resolveRulesChannel({bool force = false}) async {
    return switch (rulesChannelId) {
      Snowflake(:final value) =>
        _datastore.channel.get<ServerTextChannel>(value, force),
      _ => null,
    };
  }

  /// Resolve the server's public updates channel.
  /// ```dart
  /// final publicUpdatesChannel = await server.channels.resolvePublicUpdatesChannel();
  /// ```
  Future<ServerTextChannel?> resolvePublicUpdatesChannel(
      {bool force = false}) async {
    return switch (publicUpdatesChannelId) {
      Snowflake(:final value) =>
        _datastore.channel.get<ServerTextChannel>(value, force),
      _ => null,
    };
  }

  /// Resolve the server's safety alerts channel.
  /// ```dart
  /// final safetyAlertsChannel = await server.channels.resolveSafetyAlertsChannel();
  /// ```
  Future<ServerTextChannel?> resolveSafetyAlertsChannel(
      {bool force = false}) async {
    return switch (safetyAlertsChannelId) {
      Snowflake(:final value) =>
        _datastore.channel.get<ServerTextChannel>(value, force),
      _ => null,
    };
  }

  /// Set the server's afk channel.
  ///
  /// ```dart
  /// await server.setAfkChannel('1091121140090535956', reason: 'Testing');
  /// ```
  Future<void> setAfkChannel(String? channelId, {String? reason}) async {
    await _datastore.server
        .update(_serverId.value, {'afk_channel_id': channelId}, reason);
  }

  /// Set the server's system channel.
  ///
  /// ```dart
  /// await server.setSystemChannel('1091121140090535956', reason: 'Testing');
  /// ```
  Future<void> setSystemChannel(String? channelId, {String? reason}) async {
    await _datastore.server
        .update(_serverId.value, {'system_channel_id': channelId}, reason);
  }

  /// Set the server's rules channel.
  ///
  /// ```dart
  /// await server.setRulesChannel('1091121140090535956', reason: 'Testing');
  /// ```
  Future<void> setRulesChannel(String? channelId, {String? reason}) async {
    await _datastore.server
        .update(_serverId.value, {'rules_channel_id': channelId}, reason);
  }

  /// Set the server's public updates channel.
  ///
  /// ```dart
  /// await server.setPublicUpdatesChannel('1091121140090535956', reason: 'Testing');
  /// ```
  Future<void> setPublicUpdatesChannel(String? channelId,
      {String? reason}) async {
    await _datastore.server.update(
        _serverId.value, {'public_updates_channel_id': channelId}, reason);
  }

  factory ChannelManager.empty(String serverId, {required EntityContext ctx}) {
    return ChannelManager(
      Snowflake.parse(serverId),
      ctx: ctx,
      afkChannelId: null,
      systemChannelId: null,
      rulesChannelId: null,
      publicUpdatesChannelId: null,
      safetyAlertsChannelId: null,
    );
  }

  factory ChannelManager.fromMap(
      Object serverId, Map<String, dynamic> payload,
      {required EntityContext ctx}) {
    return ChannelManager(
      Snowflake.parse(serverId),
      ctx: ctx,
      afkChannelId: Snowflake.nullable(payload['afk_channel_id']),
      systemChannelId: Snowflake.nullable(payload['system_channel_id']),
      rulesChannelId: Snowflake.nullable(payload['rules_channel_id']),
      publicUpdatesChannelId:
          Snowflake.nullable(payload['public_updates_channel_id']),
      safetyAlertsChannelId:
          Snowflake.nullable(payload['safety_alerts_channel_id']),
    );
  }
}
