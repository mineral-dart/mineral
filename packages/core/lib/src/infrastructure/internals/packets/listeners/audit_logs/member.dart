import 'package:mineral/api.dart';
import 'package:mineral/src/api/guild/audit_log/actions/member.dart';
import 'package:mineral/src/api/guild/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

Future<AuditLog> memberKickAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return MemberKickAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.nullable(json['user_id']),
    memberId: Snowflake.nullable(json['target_id']),
    reason: json['reason'] as String?,
    ctx: ctx,
  );
}

Future<AuditLog> memberPruneAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  final options = json['options'] as Map<String, dynamic>?;
  return MemberPruneAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.nullable(json['user_id']),
    deleteMemberDays: options?['delete_member_days'] as int? ?? 0,
    membersRemoved: options?['members_removed'] as int? ?? 0,
    ctx: ctx,
  );
}

Future<AuditLog> memberBanAddAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return MemberBanAddAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.nullable(json['user_id']),
    memberId: Snowflake.nullable(json['target_id']),
    reason: json['reason'] as String?,
    ctx: ctx,
  );
}

Future<AuditLog> memberBanRemoveAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return MemberBanRemoveAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.nullable(json['user_id']),
    memberId: Snowflake.nullable(json['target_id']),
    ctx: ctx,
  );
}

Future<AuditLog> memberUpdateAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return MemberUpdateAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.nullable(json['user_id']),
    memberId: Snowflake.nullable(json['target_id']),
    changes: List<Map<String, dynamic>>.from(json['changes'] as Iterable<dynamic>)
        .map(Change.fromJson)
        .toList(),
    ctx: ctx,
  );
}

Future<AuditLog> memberRoleUpdateAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return MemberRoleUpdateAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.nullable(json['user_id']),
    memberId: Snowflake.nullable(json['target_id']),
    changes: List<Map<String, dynamic>>.from(json['changes'] as Iterable<dynamic>)
        .map(Change.fromJson)
        .toList(),
    ctx: ctx,
  );
}

Future<AuditLog> memberMoveAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return MemberMoveAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.nullable(json['user_id']),
    memberId: Snowflake.nullable(json['target_id']),
    channelId: Snowflake.nullable(json['options']?['channel_id']),
    ctx: ctx,
  );
}

Future<AuditLog> memberDisconnectAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return MemberDisconnectAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.nullable(json['user_id']),
    memberId: Snowflake.nullable(json['target_id']),
    ctx: ctx,
  );
}

Future<AuditLog> botAddAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return BotAddAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.nullable(json['user_id']),
    botId: Snowflake.nullable(json['target_id']),
    ctx: ctx,
  );
}
