import 'package:mineral/api.dart';
import 'package:mineral/src/api/server/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class AutoModerationRuleCreateAuditLog extends AuditLog {
  final Snowflake ruleId;

  AutoModerationRuleCreateAuditLog({
    required Snowflake serverId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.ruleId,
  }) : super(AuditLogType.autoModerationRuleCreate, serverId, userId, ctx: ctx);
}

final class AutoModerationRuleUpdateAuditLog extends AuditLog {
  final Snowflake ruleId;
  final List<Change> changes;

  AutoModerationRuleUpdateAuditLog({
    required Snowflake serverId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.ruleId,
    required this.changes,
  }) : super(AuditLogType.autoModerationRuleUpdate, serverId, userId, ctx: ctx);
}

final class AutoModerationRuleDeleteAuditLog extends AuditLog {
  final Snowflake ruleId;

  AutoModerationRuleDeleteAuditLog({
    required Snowflake serverId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.ruleId,
  }) : super(AuditLogType.autoModerationRuleDelete, serverId, userId, ctx: ctx);
}

final class AutoModerationBlockMessageAuditLog extends AuditLog {
  final Snowflake messageId;
  final String ruleTriggerType;

  AutoModerationBlockMessageAuditLog({
    required Snowflake serverId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.messageId,
    required this.ruleTriggerType,
  }) : super(AuditLogType.autoModerationBlockMessage, serverId, userId,
            ctx: ctx);
}

final class AutoModerationFlagToChannelAuditLog extends AuditLog {
  final Snowflake messageId;
  final Snowflake? channelId;

  AutoModerationFlagToChannelAuditLog({
    required Snowflake serverId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.messageId,
    this.channelId,
  }) : super(AuditLogType.autoModerationFlagToChannel, serverId, userId,
            ctx: ctx);
}

final class AutoModerationUserCommunicationDisabledAuditLog extends AuditLog {
  final int duration;

  AutoModerationUserCommunicationDisabledAuditLog({
    required Snowflake serverId,
    required Snowflake moderatorId,
    required EntityContext ctx,
    required this.duration,
    required Snowflake userId,
  }) : super(AuditLogType.autoModerationUserCommunicationDisabled, serverId,
            moderatorId,
            ctx: ctx);
}
