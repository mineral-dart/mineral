import 'package:mineral/api.dart';
import 'package:mineral/src/api/guild/audit_log/actions/integration.dart';
import 'package:mineral/src/api/guild/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

Future<AuditLog> integrationCreateAuditLogHandler(
  Map<String, dynamic> json,
  EntityContext ctx,
) async {
  return IntegrationCreateAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    integrationId: Snowflake.parse(json['target_id']),
    integrationType: json['options']?['type'] as String? ?? 'unknown',
    ctx: ctx,
  );
}

Future<AuditLog> integrationUpdateAuditLogHandler(
  Map<String, dynamic> json,
  EntityContext ctx,
) async {
  return IntegrationUpdateAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    integrationId: Snowflake.parse(json['target_id']),
    changes: List<Map<String, dynamic>>.from(
      json['changes'] as Iterable<dynamic>,
    ).map(Change.fromJson).toList(),
    ctx: ctx,
  );
}

Future<AuditLog> integrationDeleteAuditLogHandler(
  Map<String, dynamic> json,
  EntityContext ctx,
) async {
  return IntegrationDeleteAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    integrationId: Snowflake.parse(json['target_id']),
    integrationType: json['options']?['type'] as String? ?? 'unknown',
    ctx: ctx,
  );
}
