import 'package:mineral/api.dart';
import 'package:mineral/src/api/guild/audit_log/actions/channel_overwrite.dart';
import 'package:mineral/src/api/guild/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

Future<AuditLog> channelOverwriteCreateAuditLogHandler(
  Map<String, dynamic> json,
  EntityContext ctx,
) async {
  final options = json['options'] as Map<String, dynamic>?;
  return ChannelOverwriteCreateAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    channelId: Snowflake.parse(options?['channel_id'] ?? json['target_id']),
    overwriteId: Snowflake.parse(json['target_id']),
    overwriteType: options?['type'] as String? ?? 'role',
    changes: List<Map<String, dynamic>>.from(
      json['changes'] as Iterable<dynamic>,
    ).map(Change.fromJson).toList(),
    ctx: ctx,
  );
}

Future<AuditLog> channelOverwriteUpdateAuditLogHandler(
  Map<String, dynamic> json,
  EntityContext ctx,
) async {
  final options = json['options'] as Map<String, dynamic>?;
  return ChannelOverwriteUpdateAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    channelId: Snowflake.parse(options?['channel_id'] ?? json['target_id']),
    overwriteId: Snowflake.parse(json['target_id']),
    overwriteType: options?['type'] as String? ?? 'role',
    changes: List<Map<String, dynamic>>.from(
      json['changes'] as Iterable<dynamic>,
    ).map(Change.fromJson).toList(),
    ctx: ctx,
  );
}

Future<AuditLog> channelOverwriteDeleteAuditLogHandler(
  Map<String, dynamic> json,
  EntityContext ctx,
) async {
  final options = json['options'] as Map<String, dynamic>?;
  return ChannelOverwriteDeleteAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    channelId: Snowflake.parse(options?['channel_id'] ?? json['target_id']),
    overwriteId: Snowflake.parse(json['target_id']),
    overwriteType: options?['type'] as String? ?? 'role',
    ctx: ctx,
  );
}
