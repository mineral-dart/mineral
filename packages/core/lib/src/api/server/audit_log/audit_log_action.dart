import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/api/server/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

abstract interface class AuditLogChange<B, A> {
  B get before;

  A get after;
}

abstract class AuditLogActionContract {
  final EntityContext ctx;
  DataStoreContract get _datastore => ctx.datastore;

  AuditLogType type;
  Snowflake serverId;
  Snowflake? userId;

  AuditLogActionContract(this.type, this.serverId, this.userId,
      {required this.ctx});

  Future<Server> resolveServer() => _datastore.server.get(serverId.value, true);
}

final class UnknownAuditLogAction extends AuditLog {
  UnknownAuditLogAction({
    required Snowflake serverId,
    required Snowflake? userId,
    required EntityContext ctx,
  }) : super(AuditLogType.unknown, serverId, userId, ctx: ctx);
}
