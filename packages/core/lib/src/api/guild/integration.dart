import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/api/guild/enums/integration_expire_behavior.dart';

/// Minimal account info bundled with every Integration.
final class IntegrationAccount {
  /// The account id (string — not a snowflake on Discord's side).
  final String id;

  /// The account name.
  final String name;

  const IntegrationAccount({required this.id, required this.name});

  factory IntegrationAccount.fromJson(Map<String, dynamic> json) {
    return IntegrationAccount(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

/// Minimal application info optionally bundled with an Integration.
final class IntegrationApplication {
  /// The application id.
  final Snowflake id;

  /// The application name.
  final String name;

  /// Optional icon hash.
  final String? icon;

  /// The application description.
  final String description;

  const IntegrationApplication({
    required this.id,
    required this.name,
    required this.description,
    this.icon,
  });

  factory IntegrationApplication.fromJson(Map<String, dynamic> json) {
    return IntegrationApplication(
      id: Snowflake.parse(json['id']),
      name: json['name'] as String,
      icon: json['icon'] as String?,
      description: json['description'] as String,
    );
  }
}

/// A Discord guild integration (Twitch, YouTube, Discord, guild_subscription…).
final class Integration {
  final Snowflake id;
  final String name;

  /// Type string: `twitch`, `youtube`, `discord`, or `guild_subscription`.
  final String type;

  final bool enabled;
  final bool? syncing;
  final Snowflake? roleId;
  final bool? enableEmoticons;
  final IntegrationExpireBehavior? expireBehavior;
  final int? expireGracePeriod;

  /// The id of the user associated with the integration (if any).
  final Snowflake? userId;

  final IntegrationAccount account;
  final DateTime? syncedAt;
  final int? subscriberCount;
  final bool? revoked;
  final IntegrationApplication? application;
  final List<String>? scopes;

  const Integration({
    required this.id,
    required this.name,
    required this.type,
    required this.enabled,
    required this.account,
    this.syncing,
    this.roleId,
    this.enableEmoticons,
    this.expireBehavior,
    this.expireGracePeriod,
    this.userId,
    this.syncedAt,
    this.subscriberCount,
    this.revoked,
    this.application,
    this.scopes,
  });

  factory Integration.fromJson(Map<String, dynamic> json) {
    final expireBehaviorRaw = json['expire_behavior'] as int?;
    final expireBehavior = expireBehaviorRaw == null
        ? null
        : IntegrationExpireBehavior.values.firstWhere(
            (e) => e.value == expireBehaviorRaw,
            orElse: () => throw ArgumentError(
                'Unknown IntegrationExpireBehavior value: $expireBehaviorRaw'),
          );

    final userRaw = json['user'] as Map<String, dynamic>?;
    final userId =
        userRaw != null ? Snowflake.nullable(userRaw['id']) : null;

    final applicationRaw = json['application'] as Map<String, dynamic>?;
    final application = applicationRaw != null
        ? IntegrationApplication.fromJson(applicationRaw)
        : null;

    final syncedAtRaw = json['synced_at'] as String?;
    final syncedAt =
        syncedAtRaw != null ? DateTime.parse(syncedAtRaw) : null;

    final rawScopes = json['scopes'] as List<dynamic>?;
    final scopes = rawScopes?.cast<String>();

    return Integration(
      id: Snowflake.parse(json['id']),
      name: json['name'] as String,
      type: json['type'] as String,
      enabled: json['enabled'] as bool,
      syncing: json['syncing'] as bool?,
      roleId: Snowflake.nullable(json['role_id']),
      enableEmoticons: json['enable_emoticons'] as bool?,
      expireBehavior: expireBehavior,
      expireGracePeriod: json['expire_grace_period'] as int?,
      userId: userId,
      account: IntegrationAccount.fromJson(
          Map<String, dynamic>.from(json['account'] as Map)),
      syncedAt: syncedAt,
      subscriberCount: json['subscriber_count'] as int?,
      revoked: json['revoked'] as bool?,
      application: application,
      scopes: scopes,
    );
  }
}
