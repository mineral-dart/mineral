import 'package:mineral/api.dart';
import 'package:mineral/src/api/server/audit_log/actions/stage_instance.dart';
import 'package:mineral/src/api/server/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

Future<AuditLog> stageInstanceCreateAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return StageInstanceCreateAuditLog(
    serverId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    stageInstanceId: Snowflake.parse(json['target_id']),
    topic: (json['changes'] as List<dynamic>)[0]['new_value'] as String,
    channelId: Snowflake.nullable(json['options']?['channel_id']),
    ctx: ctx,
  );
}

Future<AuditLog> stageInstanceUpdateAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return StageInstanceUpdateAuditLog(
    serverId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    stageInstanceId: Snowflake.parse(json['target_id']),
    changes: List<Map<String, dynamic>>.from(json['changes'] as Iterable<dynamic>)
        .map(Change.fromJson)
        .toList(),
    ctx: ctx,
  );
}

Future<AuditLog> stageInstanceDeleteAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return StageInstanceDeleteAuditLog(
    serverId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    stageInstanceId: Snowflake.parse(json['target_id']),
    topic: (json['changes'] as List<dynamic>)[0]['old_value'] as String,
    channelId: Snowflake.nullable(json['options']?['channel_id']),
    ctx: ctx,
  );
}
