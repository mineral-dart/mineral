import 'package:mineral/api.dart';
import 'package:mineral/src/api/server/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

Future<AuditLog> channelCreateAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  final channel = await ctx.datastore.channel.get(json['target_id'] as String, false);

  return ChannelCreateAuditLogAction(
      serverId: Snowflake.parse(json['guild_id']),
      userId: Snowflake.parse(json['user_id']),
      channel: channel!,
      ctx: ctx);
}

Future<AuditLog> channelUpdateAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  final channel = await ctx.datastore.channel.get(json['target_id'] as String, false);

  return ChannelUpdateAuditLogAction(
      serverId: Snowflake.parse(json['guild_id']),
      userId: Snowflake.parse(json['user_id']),
      channel: channel!,
      changes:
          List<Change>.from((json['changes'] as Iterable<dynamic>).map((e) => Change.fromJson(e as Map<String, dynamic>))),
      ctx: ctx);
}

Future<AuditLog> channelDeleteAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return ChannelDeleteAuditLogAction(
      serverId: Snowflake.parse(json['guild_id']),
      userId: Snowflake.parse(json['user_id']),
      channelId: Snowflake.parse(json['target_id']),
      changes:
          List<Change>.from((json['changes'] as Iterable<dynamic>).map((e) => Change.fromJson(e as Map<String, dynamic>))),
      ctx: ctx);
}
