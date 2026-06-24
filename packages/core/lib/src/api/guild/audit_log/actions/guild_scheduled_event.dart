import 'package:mineral/api.dart';
import 'package:mineral/src/api/guild/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class GuildScheduledEventCreateAuditLog extends AuditLog {
  final Snowflake eventId;

  GuildScheduledEventCreateAuditLog({
    required Snowflake guildId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.eventId,
  }) : super(AuditLogType.guildScheduledEventCreate, guildId, userId, ctx: ctx);
}

final class GuildScheduledEventUpdateAuditLog extends AuditLog {
  final Snowflake eventId;
  final List<Change> changes;

  GuildScheduledEventUpdateAuditLog({
    required Snowflake guildId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.eventId,
    required this.changes,
  }) : super(AuditLogType.guildScheduledEventUpdate, guildId, userId, ctx: ctx);
}

final class GuildScheduledEventDeleteAuditLog extends AuditLog {
  final Snowflake eventId;

  GuildScheduledEventDeleteAuditLog({
    required Snowflake guildId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.eventId,
  }) : super(AuditLogType.guildScheduledEventDelete, guildId, userId, ctx: ctx);
}
