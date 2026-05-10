import 'package:mineral/api.dart';
import 'package:mineral/src/api/server/audit_log/actions/thread.dart';
import 'package:mineral/src/api/server/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

Future<AuditLog> threadCreateAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return ThreadCreateAuditLog(
    serverId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    threadId: Snowflake.parse(json['target_id']),
    threadName: (json['changes'] as List<dynamic>)[0]['new_value'] as String,
    channelId: Snowflake.nullable(json['options']?['channel_id']),
    ctx: ctx,
  );
}

Future<AuditLog> threadUpdateAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return ThreadUpdateAuditLog(
    serverId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    threadId: Snowflake.parse(json['target_id']),
    changes: List<Map<String, dynamic>>.from(json['changes'] as Iterable<dynamic>)
        .map(Change.fromJson)
        .toList(),
    ctx: ctx,
  );
}

Future<AuditLog> threadDeleteAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return ThreadDeleteAuditLog(
    serverId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    threadId: Snowflake.parse(json['target_id']),
    threadName: (json['changes'] as List<dynamic>)[0]['old_value'] as String,
    channelId: Snowflake.nullable(json['options']?['channel_id']),
    ctx: ctx,
  );
}
