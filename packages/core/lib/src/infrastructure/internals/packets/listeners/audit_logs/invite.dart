import 'package:mineral/api.dart';
import 'package:mineral/src/api/guild/audit_log/actions/invite.dart';
import 'package:mineral/src/api/guild/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

Future<AuditLog> inviteCreateAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  final changes = json['changes'] as List<dynamic>;
  final options = json['options'] as Map<String, dynamic>?;
  return InviteCreateAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    inviteCode: (changes[0] as Map<String, dynamic>)['new_value'] as String,
    maxAge: options?['max_age'] as int? ?? 0,
    maxUses: options?['max_uses'] as int? ?? 0,
    temporary: options?['temporary'] as bool? ?? false,
    channelId: Snowflake.nullable(options?['channel_id'] as String?),
    ctx: ctx,
  );
}

Future<AuditLog> inviteUpdateAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return InviteUpdateAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    inviteCode: json['target_id'] as String,
    changes: List<Map<String, dynamic>>.from(json['changes'] as Iterable<dynamic>)
        .map(Change.fromJson)
        .toList(),
    ctx: ctx,
  );
}

Future<AuditLog> inviteDeleteAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  final options = json['options'] as Map<String, dynamic>?;
  final code = List.from(json['changes'] as Iterable<dynamic>).firstWhere(
    (change) => (change as Map<String, dynamic>)['key'] == 'code',
  ) as Map<String, dynamic>;

  return InviteDeleteAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    inviteCode: code['old_value'] as String? ?? 'Unknown',
    channelId: Snowflake.nullable(options?['channel_id'] as String?),
    ctx: ctx,
  );
}
