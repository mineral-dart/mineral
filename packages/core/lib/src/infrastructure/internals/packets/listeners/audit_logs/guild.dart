import 'package:mineral/api.dart';
import 'package:mineral/src/api/guild/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

Future<AuditLog> guildUpdateAuditLogHandler(
  Map<String, dynamic> json,
  EntityContext ctx,
) async {
  final guild = await ctx.datastore.guild.get(json['guild_id'] as Object, true);

  return GuildUpdateAuditLogAction(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    guild: guild,
    changes: List<Change>.from(
      (json['changes'] as Iterable<dynamic>).map(
        (e) => Change.fromJson(e as Map<String, dynamic>),
      ),
    ),
    ctx: ctx,
  );
}
