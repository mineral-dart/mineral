import 'package:mineral/api.dart';
import 'package:mineral/src/api/server/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class InviteCreateAuditLog extends AuditLog {
  final String inviteCode;
  final int maxAge;
  final int maxUses;
  final bool temporary;
  final Snowflake? channelId;

  InviteCreateAuditLog({
    required Snowflake serverId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.inviteCode,
    required this.maxAge,
    required this.maxUses,
    required this.temporary,
    this.channelId,
  }) : super(AuditLogType.inviteCreate, serverId, userId, ctx: ctx);
}

final class InviteUpdateAuditLog extends AuditLog {
  final String inviteCode;
  final List<Change> changes;

  InviteUpdateAuditLog({
    required Snowflake serverId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.inviteCode,
    required this.changes,
  }) : super(AuditLogType.inviteUpdate, serverId, userId, ctx: ctx);
}

final class InviteDeleteAuditLog extends AuditLog {
  final String inviteCode;
  final Snowflake? channelId;

  InviteDeleteAuditLog({
    required Snowflake serverId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.inviteCode,
    this.channelId,
  }) : super(AuditLogType.inviteDelete, serverId, userId, ctx: ctx);
}
