import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/api/guild/enums/application_command_permission_type.dart';

/// A single permission entry for a guild application command.
final class ApplicationCommandPermission {
  /// The id of the role, user, or channel — or a guild permission constant.
  final Snowflake id;

  /// Whether this entry targets a role, user, or channel.
  final ApplicationCommandPermissionType type;

  /// Whether the permission is allowed (`true`) or denied (`false`).
  final bool permission;

  const ApplicationCommandPermission({
    required this.id,
    required this.type,
    required this.permission,
  });

  factory ApplicationCommandPermission.fromJson(Map<String, dynamic> json) {
    final typeValue = json['type'] as int;
    final type = ApplicationCommandPermissionType.values.firstWhere(
      (e) => e.value == typeValue,
      orElse: () => throw ArgumentError(
        'Unknown ApplicationCommandPermissionType value: $typeValue',
      ),
    );

    return ApplicationCommandPermission(
      id: Snowflake.parse(json['id']),
      type: type,
      permission: json['permission'] as bool,
    );
  }
}

/// The full permissions object for a guild application command as sent by
/// the [APPLICATION_COMMAND_PERMISSIONS_UPDATE] gateway event.
final class GuildApplicationCommandPermissions {
  /// The id of the command, or the application id when it applies to all commands.
  final Snowflake id;

  /// The id of the application.
  final Snowflake applicationId;

  /// The id of the guild.
  final Snowflake guildId;

  /// The permissions for the command in the guild.
  final List<ApplicationCommandPermission> permissions;

  const GuildApplicationCommandPermissions({
    required this.id,
    required this.applicationId,
    required this.guildId,
    required this.permissions,
  });

  factory GuildApplicationCommandPermissions.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawPerms = json['permissions'] as List<dynamic>;
    return GuildApplicationCommandPermissions(
      id: Snowflake.parse(json['id']),
      applicationId: Snowflake.parse(json['application_id']),
      guildId: Snowflake.parse(json['guild_id']),
      permissions: rawPerms
          .cast<Map<String, dynamic>>()
          .map(ApplicationCommandPermission.fromJson)
          .toList(),
    );
  }
}
