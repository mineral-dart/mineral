import 'package:mineral/api.dart';
import 'package:mineral/src/api/guild/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class ThreadCreateAuditLog extends AuditLog {
  final Snowflake threadId;
  final String threadName;
  final Snowflake? channelId;

  ThreadCreateAuditLog({
    required Snowflake guildId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.threadId,
    required this.threadName,
    this.channelId,
  }) : super(AuditLogType.threadCreate, guildId, userId, ctx: ctx);
}

final class ThreadUpdateAuditLog extends AuditLog {
  final Snowflake threadId;
  final List<Change> changes;

  ThreadUpdateAuditLog({
    required Snowflake guildId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.threadId,
    required this.changes,
  }) : super(AuditLogType.threadUpdate, guildId, userId, ctx: ctx);
}

final class ThreadDeleteAuditLog extends AuditLog {
  final Snowflake threadId;
  final String threadName;
  final Snowflake? channelId;

  ThreadDeleteAuditLog({
    required Snowflake guildId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.threadId,
    required this.threadName,
    this.channelId,
  }) : super(AuditLogType.threadDelete, guildId, userId, ctx: ctx);
}
