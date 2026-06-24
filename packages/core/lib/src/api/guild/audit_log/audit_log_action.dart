import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/api/guild/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

abstract interface class AuditLogChange<B, A> {
  B get before;

  A get after;
}

abstract class AuditLogActionContract {
  final EntityContext ctx;
  DataStoreContract get _datastore => ctx.datastore;

  AuditLogType type;
  Snowflake guildId;
  Snowflake? userId;

  AuditLogActionContract(this.type, this.guildId, this.userId,
      {required this.ctx});

  Future<Guild> resolveServer() => _datastore.guild.get(guildId.value, true);
}

final class UnknownAuditLogAction extends AuditLog {
  UnknownAuditLogAction({
    required Snowflake guildId,
    required Snowflake? userId,
    required EntityContext ctx,
  }) : super(AuditLogType.unknown, guildId, userId, ctx: ctx);
}
