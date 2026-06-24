import 'package:mineral/api.dart';
import 'package:mineral/src/api/guild/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class StickerCreateAuditLog extends AuditLog {
  final Snowflake stickerId;
  final Sticker sticker;

  StickerCreateAuditLog({
    required Snowflake guildId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.stickerId,
    required this.sticker,
  }) : super(AuditLogType.stickerCreate, guildId, userId, ctx: ctx);
}

final class StickerUpdateAuditLog extends AuditLog {
  final Snowflake stickerId;
  final Sticker sticker;
  final List<Change> changes;

  StickerUpdateAuditLog({
    required Snowflake guildId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.stickerId,
    required this.changes,
    required this.sticker,
  }) : super(AuditLogType.stickerUpdate, guildId, userId, ctx: ctx);
}

final class StickerDeleteAuditLog extends AuditLog {
  final Snowflake stickerId;

  StickerDeleteAuditLog({
    required Snowflake guildId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.stickerId,
  }) : super(AuditLogType.stickerDelete, guildId, userId, ctx: ctx);
}
