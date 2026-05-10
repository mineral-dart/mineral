import 'package:mineral/api.dart';
import 'package:mineral/src/api/server/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class StickerCreateAuditLog extends AuditLog {
  final Snowflake stickerId;
  final Sticker sticker;

  StickerCreateAuditLog({
    required Snowflake serverId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.stickerId,
    required this.sticker,
  }) : super(AuditLogType.stickerCreate, serverId, userId, ctx: ctx);
}

final class StickerUpdateAuditLog extends AuditLog {
  final Snowflake stickerId;
  final Sticker sticker;
  final List<Change> changes;

  StickerUpdateAuditLog({
    required Snowflake serverId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.stickerId,
    required this.changes,
    required this.sticker,
  }) : super(AuditLogType.stickerUpdate, serverId, userId, ctx: ctx);
}

final class StickerDeleteAuditLog extends AuditLog {
  final Snowflake stickerId;

  StickerDeleteAuditLog({
    required Snowflake serverId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.stickerId,
  }) : super(AuditLogType.stickerDelete, serverId, userId, ctx: ctx);
}
