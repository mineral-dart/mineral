import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class Bot {
  final WebsocketOrchestratorContract _wss;
  final EntityContext? _ctx;

  final Snowflake id;
  final String? discriminator;
  final int version;
  final String username;
  final bool hasEnabledMfa;
  final String? globalName;
  final int flags;
  final String? avatar;
  final String sessionType;
  final List<dynamic> privateChannels;
  final List<dynamic> presences;
  final List<String> guildIds;
  final PartialApplication application;

  Bot._({
    required WebsocketOrchestratorContract wss,
    required this.id,
    required this.discriminator,
    required this.version,
    required this.username,
    required this.hasEnabledMfa,
    required this.globalName,
    required this.flags,
    required this.avatar,
    required this.sessionType,
    required this.privateChannels,
    required this.presences,
    required this.guildIds,
    required this.application,
    EntityContext? ctx,
  })  : _wss = wss,
        _ctx = ctx;

  /// Manager for application-owned emojis (usable across all servers).
  /// ```dart
  /// final emojis = await bot.emojis.fetch();
  /// ```
  ApplicationEmojiManager get emojis {
    final ctx = _ctx;
    if (ctx == null) {
      throw StateError(
          'Bot.emojis requires an EntityContext. '
          'Pass entityContext: to Bot.fromJson().');
    }
    return ApplicationEmojiManager(application.id, ctx: ctx);
  }

  /// Manager for application monetization (SKUs, Entitlements, Subscriptions).
  /// ```dart
  /// final skus = await bot.monetization.fetchSkus();
  /// ```
  MonetizationManager get monetization {
    final ctx = _ctx;
    if (ctx == null) {
      throw StateError(
          'Bot.monetization requires an EntityContext. '
          'Pass entityContext: to Bot.fromJson().');
    }
    return MonetizationManager(application.id, ctx: ctx);
  }

  /// Updates presence of this
  void setPresence(
          {List<BotActivity>? activities, StatusType? status, bool? afk}) =>
      _wss.setBotPresence(activities, status, afk);

  @override
  String toString() => '<@$id>';

  factory Bot.fromJson(
    Map<String, dynamic> json, {
    required WebsocketOrchestratorContract wss,
    EntityContext? entityContext,
  }) {
    final user = json['user'] as Map<String, dynamic>;
    final application = json['application'] as Map<String, dynamic>;
    return Bot._(
        wss: wss,
        ctx: entityContext,
        id: Snowflake.parse(user['id']),
        discriminator: user['discriminator'] as String?,
        version: json['v'] as int,
        username: user['username'] as String,
        hasEnabledMfa: user['mfa_enabled'] as bool,
        globalName: user['global_name'] as String?,
        flags: user['flags'] as int,
        avatar: user['avatar'] as String?,
        sessionType: json['session_type'] as String,
        privateChannels: List.unmodifiable(json['private_channels'] as List<dynamic>),
        presences: List.unmodifiable(json['presences'] as List<dynamic>),
        guildIds: List.unmodifiable(
            (json['guilds'] as Iterable<dynamic>).map((element) => Snowflake.parse((element as Map<String, dynamic>)['id']))),
        application: PartialApplication(
          id: Snowflake.parse(application['id']),
          flags: application['flags'] as int,
        ),
    );
  }
}
