import 'package:mineral/api.dart';
import 'package:mineral/src/api/server/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class ApplicationCommandPermissionUpdateAuditLog extends AuditLog {
  final Snowflake applicationId;
  final List<Change> changes;

  ApplicationCommandPermissionUpdateAuditLog({
    required Snowflake serverId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.applicationId,
    required this.changes,
  }) : super(AuditLogType.applicationCommandPermissionUpdate, serverId, userId,
            ctx: ctx);
}
