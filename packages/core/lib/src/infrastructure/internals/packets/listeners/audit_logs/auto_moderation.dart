import 'package:mineral/api.dart';
import 'package:mineral/src/api/server/audit_log/actions/auto_moderation.dart';
import 'package:mineral/src/api/server/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

Future<AuditLog> autoModerationRuleCreateAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return AutoModerationRuleCreateAuditLog(
    serverId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    ruleId: Snowflake.parse(json['target_id']),
    ctx: ctx,
  );
}

Future<AuditLog> autoModerationRuleUpdateAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return AutoModerationRuleUpdateAuditLog(
    serverId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    ruleId: Snowflake.parse(json['target_id']),
    changes: List<Map<String, dynamic>>.from(json['changes'] as Iterable<dynamic>)
        .map(Change.fromJson)
        .toList(),
    ctx: ctx,
  );
}

Future<AuditLog> autoModerationRuleDeleteAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return AutoModerationRuleDeleteAuditLog(
    serverId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    ruleId: Snowflake.parse(json['target_id']),
    ctx: ctx,
  );
}

Future<AuditLog> autoModerationBlockMessageAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return AutoModerationBlockMessageAuditLog(
    serverId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    messageId: Snowflake.parse(json['target_id']),
    ruleTriggerType: json['options']?['rule_trigger_type'] as String? ?? 'Unknown',
    ctx: ctx,
  );
}

Future<AuditLog> autoModerationFlagToChannelAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return AutoModerationFlagToChannelAuditLog(
    serverId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    messageId: Snowflake.parse(json['target_id']),
    channelId: json['options']?['channel_id'] != null
        ? Snowflake.parse(json['options']['channel_id'])
        : null,
    ctx: ctx,
  );
}

Future<AuditLog> autoModerationUserCommunicationDisabledAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return AutoModerationUserCommunicationDisabledAuditLog(
    serverId: Snowflake.parse(json['guild_id']),
    moderatorId: Snowflake.parse(json['user_id']),
    userId: Snowflake.parse(json['target_id']),
    duration: json['options']?['duration'] as int? ?? 0,
    ctx: ctx,
  );
}
