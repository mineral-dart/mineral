import 'package:mineral/api.dart';
import 'package:mineral/src/api/server/audit_log/actions/webhook.dart';
import 'package:mineral/src/api/server/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

Future<AuditLog> webhookCreateAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return WebhookCreateAuditLog(
    serverId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    webhookId: Snowflake.parse(json['target_id']),
    webhookName: (json['changes'] as List<dynamic>)[0]['new_value'] as String,
    channelId: Snowflake.nullable(json['options']?['channel_id']),
    ctx: ctx,
  );
}

Future<AuditLog> webhookUpdateAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return WebhookUpdateAuditLog(
    serverId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    webhookId: Snowflake.parse(json['target_id']),
    changes: List<Map<String, dynamic>>.from(json['changes'] as Iterable<dynamic>)
        .map(Change.fromJson)
        .toList(),
    ctx: ctx,
  );
}

Future<AuditLog> webhookDeleteAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return WebhookDeleteAuditLog(
    serverId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    webhookId: Snowflake.parse(json['target_id']),
    webhookName: (json['changes'] as List<dynamic>)[0]['old_value'] as String,
    channelId: Snowflake.nullable(json['options']?['channel_id']),
    ctx: ctx,
  );
}
