import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class ChannelManager<C extends Channel> {
  final EntityContext _ctx;
  DataStoreContract get _datastore => _ctx.datastore;

  final Snowflake _guildId;
  final Snowflake? afkChannelId;
  final Snowflake? systemChannelId;
  final Snowflake? rulesChannelId;
  final Snowflake? publicUpdatesChannelId;
  final Snowflake? safetyAlertsChannelId;

  ChannelManager(
    this._guildId, {
    required EntityContext ctx,
    required this.afkChannelId,
    required this.systemChannelId,
    required this.rulesChannelId,
    required this.publicUpdatesChannelId,
    required this.safetyAlertsChannelId,
  }) : _ctx = ctx;

  /// Fetch the guild's channels.
  /// ```dart
  /// final channels = await guild.channels.fetch();
  /// ```
  Future<Map<Snowflake, C>> fetch({bool force = false}) =>
      _datastore.channel.fetch<C>(_guildId.value, force);

  /// Get a channel by its id.
  /// ```dart
  /// final channel = await guild.channels.get('1091121140090535956');
  /// ```
  Future<T?> get<T extends C>(String id, {bool force = false}) =>
      _datastore.channel.get<T>(id, force);

  /// Create a channel.
  /// ```dart
  /// final channel = await guild.channels.create<TextChannel>(builder, reason: 'Testing');
  /// ```
  Future<T> create<T extends C>(
    ChannelBuilderContract builder, {
    String? reason,
  }) => _datastore.channel.create<T>(_guildId.value, builder, reason: reason);

  /// Resolve the guild's afk channel.
  /// ```dart
  /// final afkChannel = await guild.channels.resolveAfkChannel();
  /// ```
  Future<GuildVoiceChannel?> resolveAfkChannel({bool force = false}) async {
    return switch (afkChannelId) {
      Snowflake(:final value) => _datastore.channel.get<GuildVoiceChannel>(
        value,
        force,
      ),
      _ => null,
    };
  }

  /// Resolve the guild's system channel.
  /// ```dart
  /// final systemChannel = await guild.channels.resolveSystemChannel();
  /// ```
  Future<GuildTextChannel?> resolveSystemChannel({bool force = false}) async {
    return switch (systemChannelId) {
      Snowflake(:final value) => _datastore.channel.get<GuildTextChannel>(
        value,
        force,
      ),
      _ => null,
    };
  }

  /// Resolve the guild's rules channel.
  /// ```dart
  /// final rulesChannel = await guild.channels.resolveRulesChannel();
  /// ```
  Future<GuildTextChannel?> resolveRulesChannel({bool force = false}) async {
    return switch (rulesChannelId) {
      Snowflake(:final value) => _datastore.channel.get<GuildTextChannel>(
        value,
        force,
      ),
      _ => null,
    };
  }

  /// Resolve the guild's public updates channel.
  /// ```dart
  /// final publicUpdatesChannel = await guild.channels.resolvePublicUpdatesChannel();
  /// ```
  Future<GuildTextChannel?> resolvePublicUpdatesChannel({
    bool force = false,
  }) async {
    return switch (publicUpdatesChannelId) {
      Snowflake(:final value) => _datastore.channel.get<GuildTextChannel>(
        value,
        force,
      ),
      _ => null,
    };
  }

  /// Resolve the guild's safety alerts channel.
  /// ```dart
  /// final safetyAlertsChannel = await guild.channels.resolveSafetyAlertsChannel();
  /// ```
  Future<GuildTextChannel?> resolveSafetyAlertsChannel({
    bool force = false,
  }) async {
    return switch (safetyAlertsChannelId) {
      Snowflake(:final value) => _datastore.channel.get<GuildTextChannel>(
        value,
        force,
      ),
      _ => null,
    };
  }

  /// Set the guild's afk channel.
  ///
  /// ```dart
  /// await guild.setAfkChannel('1091121140090535956', reason: 'Testing');
  /// ```
  Future<void> setAfkChannel(String? channelId, {String? reason}) async {
    await _datastore.guild.update(_guildId.value, {
      'afk_channel_id': channelId,
    }, reason);
  }

  /// Set the guild's system channel.
  ///
  /// ```dart
  /// await guild.setSystemChannel('1091121140090535956', reason: 'Testing');
  /// ```
  Future<void> setSystemChannel(String? channelId, {String? reason}) async {
    await _datastore.guild.update(_guildId.value, {
      'system_channel_id': channelId,
    }, reason);
  }

  /// Set the guild's rules channel.
  ///
  /// ```dart
  /// await guild.setRulesChannel('1091121140090535956', reason: 'Testing');
  /// ```
  Future<void> setRulesChannel(String? channelId, {String? reason}) async {
    await _datastore.guild.update(_guildId.value, {
      'rules_channel_id': channelId,
    }, reason);
  }

  /// Set the guild's public updates channel.
  ///
  /// ```dart
  /// await guild.setPublicUpdatesChannel('1091121140090535956', reason: 'Testing');
  /// ```
  Future<void> setPublicUpdatesChannel(
    String? channelId, {
    String? reason,
  }) async {
    await _datastore.guild.update(_guildId.value, {
      'public_updates_channel_id': channelId,
    }, reason);
  }

  factory ChannelManager.empty(String guildId, {required EntityContext ctx}) {
    return ChannelManager(
      Snowflake.parse(guildId),
      ctx: ctx,
      afkChannelId: null,
      systemChannelId: null,
      rulesChannelId: null,
      publicUpdatesChannelId: null,
      safetyAlertsChannelId: null,
    );
  }

  factory ChannelManager.fromMap(
    Object guildId,
    Map<String, dynamic> payload, {
    required EntityContext ctx,
  }) {
    return ChannelManager(
      Snowflake.parse(guildId),
      ctx: ctx,
      afkChannelId: Snowflake.nullable(payload['afk_channel_id']),
      systemChannelId: Snowflake.nullable(payload['system_channel_id']),
      rulesChannelId: Snowflake.nullable(payload['rules_channel_id']),
      publicUpdatesChannelId: Snowflake.nullable(
        payload['public_updates_channel_id'],
      ),
      safetyAlertsChannelId: Snowflake.nullable(
        payload['safety_alerts_channel_id'],
      ),
    );
  }
}
