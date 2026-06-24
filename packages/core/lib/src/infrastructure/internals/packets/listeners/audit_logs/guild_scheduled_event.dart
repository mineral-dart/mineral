import 'package:mineral/api.dart';
import 'package:mineral/src/api/guild/audit_log/actions/guild_scheduled_event.dart';
import 'package:mineral/src/api/guild/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

Future<AuditLog> guildScheduledEventCreateAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return GuildScheduledEventCreateAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    eventId: Snowflake.parse(json['target_id']),
    ctx: ctx,
  );
}

Future<AuditLog> guildScheduledEventUpdateAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return GuildScheduledEventUpdateAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    eventId: Snowflake.parse(json['target_id']),
    changes: List<Map<String, dynamic>>.from(json['changes'] as Iterable<dynamic>)
        .map(Change.fromJson)
        .toList(),
    ctx: ctx,
  );
}

Future<AuditLog> guildScheduledEventDeleteAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return GuildScheduledEventDeleteAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    eventId: Snowflake.parse(json['target_id']),
    ctx: ctx,
  );
}
