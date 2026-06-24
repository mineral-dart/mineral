import 'package:mineral/api.dart';
import 'package:mineral/src/api/guild/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class IntegrationCreateAuditLog extends AuditLog {
  final Snowflake integrationId;
  final String integrationType;

  IntegrationCreateAuditLog({
    required Snowflake guildId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.integrationId,
    required this.integrationType,
  }) : super(AuditLogType.integrationCreate, guildId, userId, ctx: ctx);
}

final class IntegrationUpdateAuditLog extends AuditLog {
  final Snowflake integrationId;
  final List<Change> changes;

  IntegrationUpdateAuditLog({
    required Snowflake guildId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.integrationId,
    required this.changes,
  }) : super(AuditLogType.integrationUpdate, guildId, userId, ctx: ctx);
}

final class IntegrationDeleteAuditLog extends AuditLog {
  final Snowflake integrationId;
  final String integrationType;

  IntegrationDeleteAuditLog({
    required Snowflake guildId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.integrationId,
    required this.integrationType,
  }) : super(AuditLogType.integrationDelete, guildId, userId, ctx: ctx);
}
