import 'package:mineral/api.dart';
import 'package:mineral/src/api/guild/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class StageInstanceCreateAuditLog extends AuditLog {
  final Snowflake stageInstanceId;
  final String topic;
  final Snowflake? channelId;

  StageInstanceCreateAuditLog({
    required Snowflake guildId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.stageInstanceId,
    required this.topic,
    this.channelId,
  }) : super(AuditLogType.stageInstanceCreate, guildId, userId, ctx: ctx);
}

final class StageInstanceUpdateAuditLog extends AuditLog {
  final Snowflake stageInstanceId;
  final List<Change> changes;

  StageInstanceUpdateAuditLog({
    required Snowflake guildId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.stageInstanceId,
    required this.changes,
  }) : super(AuditLogType.stageInstanceUpdate, guildId, userId, ctx: ctx);
}

final class StageInstanceDeleteAuditLog extends AuditLog {
  final Snowflake stageInstanceId;
  final String topic;
  final Snowflake? channelId;

  StageInstanceDeleteAuditLog({
    required Snowflake guildId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.stageInstanceId,
    required this.topic,
    this.channelId,
  }) : super(AuditLogType.stageInstanceDelete, guildId, userId, ctx: ctx);
}
