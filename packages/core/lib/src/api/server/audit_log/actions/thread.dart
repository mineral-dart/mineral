import 'package:mineral/api.dart';
import 'package:mineral/src/api/server/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class ThreadCreateAuditLog extends AuditLog {
  final Snowflake threadId;
  final String threadName;
  final Snowflake? channelId;

  ThreadCreateAuditLog({
    required Snowflake serverId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.threadId,
    required this.threadName,
    this.channelId,
  }) : super(AuditLogType.threadCreate, serverId, userId, ctx: ctx);
}

final class ThreadUpdateAuditLog extends AuditLog {
  final Snowflake threadId;
  final List<Change> changes;

  ThreadUpdateAuditLog({
    required Snowflake serverId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.threadId,
    required this.changes,
  }) : super(AuditLogType.threadUpdate, serverId, userId, ctx: ctx);
}

final class ThreadDeleteAuditLog extends AuditLog {
  final Snowflake threadId;
  final String threadName;
  final Snowflake? channelId;

  ThreadDeleteAuditLog({
    required Snowflake serverId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.threadId,
    required this.threadName,
    this.channelId,
  }) : super(AuditLogType.threadDelete, serverId, userId, ctx: ctx);
}
