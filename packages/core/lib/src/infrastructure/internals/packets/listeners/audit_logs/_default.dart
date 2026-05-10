import 'package:mineral/api.dart';
import 'package:mineral/src/api/server/audit_log/audit_log.dart';
import 'package:mineral/src/api/server/audit_log/audit_log_action.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

Future<AuditLog> unknownAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return UnknownAuditLogAction(
      serverId: Snowflake.parse(json['guild_id']),
      userId: Snowflake.nullable(json['user_id']),
      ctx: ctx);
}
