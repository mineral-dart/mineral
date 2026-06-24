import 'package:mineral/api.dart';
import 'package:mineral/src/api/guild/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class ChannelOverwriteCreateAuditLog extends AuditLog {
  final Snowflake channelId;
  final Snowflake overwriteId;
  final String overwriteType;
  final List<Change> changes;

  ChannelOverwriteCreateAuditLog({
    required Snowflake guildId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.channelId,
    required this.overwriteId,
    required this.overwriteType,
    required this.changes,
  }) : super(AuditLogType.channelOverwriteCreate, guildId, userId, ctx: ctx);
}

final class ChannelOverwriteUpdateAuditLog extends AuditLog {
  final Snowflake channelId;
  final Snowflake overwriteId;
  final String overwriteType;
  final List<Change> changes;

  ChannelOverwriteUpdateAuditLog({
    required Snowflake guildId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.channelId,
    required this.overwriteId,
    required this.overwriteType,
    required this.changes,
  }) : super(AuditLogType.channelOverwriteUpdate, guildId, userId, ctx: ctx);
}

final class ChannelOverwriteDeleteAuditLog extends AuditLog {
  final Snowflake channelId;
  final Snowflake overwriteId;
  final String overwriteType;

  ChannelOverwriteDeleteAuditLog({
    required Snowflake guildId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.channelId,
    required this.overwriteId,
    required this.overwriteType,
  }) : super(AuditLogType.channelOverwriteDelete, guildId, userId, ctx: ctx);
}
