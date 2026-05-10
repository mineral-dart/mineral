import 'package:mineral/api.dart';
import 'package:mineral/src/api/server/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class ChannelOverwriteCreateAuditLog extends AuditLog {
  final Snowflake channelId;
  final Snowflake overwriteId;
  final String overwriteType;
  final List<Change> changes;

  ChannelOverwriteCreateAuditLog({
    required Snowflake serverId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.channelId,
    required this.overwriteId,
    required this.overwriteType,
    required this.changes,
  }) : super(AuditLogType.channelOverwriteCreate, serverId, userId, ctx: ctx);
}

final class ChannelOverwriteUpdateAuditLog extends AuditLog {
  final Snowflake channelId;
  final Snowflake overwriteId;
  final String overwriteType;
  final List<Change> changes;

  ChannelOverwriteUpdateAuditLog({
    required Snowflake serverId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.channelId,
    required this.overwriteId,
    required this.overwriteType,
    required this.changes,
  }) : super(AuditLogType.channelOverwriteUpdate, serverId, userId, ctx: ctx);
}

final class ChannelOverwriteDeleteAuditLog extends AuditLog {
  final Snowflake channelId;
  final Snowflake overwriteId;
  final String overwriteType;

  ChannelOverwriteDeleteAuditLog({
    required Snowflake serverId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.channelId,
    required this.overwriteId,
    required this.overwriteType,
  }) : super(AuditLogType.channelOverwriteDelete, serverId, userId, ctx: ctx);
}
