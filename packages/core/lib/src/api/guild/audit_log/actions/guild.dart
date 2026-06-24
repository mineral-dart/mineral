import 'package:mineral/api.dart';
import 'package:mineral/src/api/guild/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class GuildUpdateAuditLogAction extends AuditLog {
  final Guild guild;
  final List<Change> changes;

  GuildUpdateAuditLogAction(
      {required Snowflake guildId,
      required Snowflake userId,
      required EntityContext ctx,
      required this.guild,
      required this.changes})
      : super(AuditLogType.guildUpdate, guildId, userId, ctx: ctx);
}
