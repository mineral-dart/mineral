import 'package:mineral/api.dart';
import 'package:mineral/src/api/guild/audit_log/actions/auto_moderation.dart';
import 'package:mineral/src/api/guild/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

Future<AuditLog> autoModerationRuleCreateAuditLogHandler(
  Map<String, dynamic> json,
  EntityContext ctx,
) async {
  return AutoModerationRuleCreateAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    ruleId: Snowflake.parse(json['target_id']),
    ctx: ctx,
  );
}

Future<AuditLog> autoModerationRuleUpdateAuditLogHandler(
  Map<String, dynamic> json,
  EntityContext ctx,
) async {
  return AutoModerationRuleUpdateAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    ruleId: Snowflake.parse(json['target_id']),
    changes: List<Map<String, dynamic>>.from(
      json['changes'] as Iterable<dynamic>,
    ).map(Change.fromJson).toList(),
    ctx: ctx,
  );
}

Future<AuditLog> autoModerationRuleDeleteAuditLogHandler(
  Map<String, dynamic> json,
  EntityContext ctx,
) async {
  return AutoModerationRuleDeleteAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    ruleId: Snowflake.parse(json['target_id']),
    ctx: ctx,
  );
}

Future<AuditLog> autoModerationBlockMessageAuditLogHandler(
  Map<String, dynamic> json,
  EntityContext ctx,
) async {
  return AutoModerationBlockMessageAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    messageId: Snowflake.parse(json['target_id']),
    ruleTriggerType:
        json['options']?['rule_trigger_type'] as String? ?? 'Unknown',
    ctx: ctx,
  );
}

Future<AuditLog> autoModerationFlagToChannelAuditLogHandler(
  Map<String, dynamic> json,
  EntityContext ctx,
) async {
  return AutoModerationFlagToChannelAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    messageId: Snowflake.parse(json['target_id']),
    channelId: json['options']?['channel_id'] != null
        ? Snowflake.parse(json['options']['channel_id'])
        : null,
    ctx: ctx,
  );
}

Future<AuditLog> autoModerationUserCommunicationDisabledAuditLogHandler(
  Map<String, dynamic> json,
  EntityContext ctx,
) async {
  return AutoModerationUserCommunicationDisabledAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    moderatorId: Snowflake.parse(json['user_id']),
    userId: Snowflake.parse(json['target_id']),
    duration: json['options']?['duration'] as int? ?? 0,
    ctx: ctx,
  );
}
