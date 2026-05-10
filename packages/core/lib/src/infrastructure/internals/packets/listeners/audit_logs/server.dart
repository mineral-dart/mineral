import 'package:mineral/api.dart';
import 'package:mineral/src/api/server/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

Future<AuditLog> serverUpdateAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  final server = await ctx.datastore.server.get(json['guild_id'] as Object, true);

  return ServerUpdateAuditLogAction(
      serverId: Snowflake.parse(json['guild_id']),
      userId: Snowflake.parse(json['user_id']),
      server: server,
      changes:
          List<Change>.from((json['changes'] as Iterable<dynamic>).map((e) => Change.fromJson(e as Map<String, dynamic>))),
      ctx: ctx);
}
