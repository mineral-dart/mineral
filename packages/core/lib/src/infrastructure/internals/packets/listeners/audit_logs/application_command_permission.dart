import 'package:mineral/api.dart';
import 'package:mineral/src/api/guild/audit_log/actions/application_command_permission.dart';
import 'package:mineral/src/api/guild/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

Future<AuditLog> applicationCommandPermissionUpdateAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return ApplicationCommandPermissionUpdateAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    applicationId: Snowflake.parse(json['target_id']),
    changes: List<Map<String, dynamic>>.from(json['changes'] as Iterable<dynamic>)
        .map(Change.fromJson)
        .toList(),
    ctx: ctx,
  );
}
