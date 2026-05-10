import 'package:mineral/api.dart';
import 'package:mineral/src/api/server/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class EmojiCreateAuditLog extends AuditLog {
  final String emojiName;

  EmojiCreateAuditLog(
      {required Snowflake serverId,
      required Snowflake userId,
      required EntityContext ctx,
      required this.emojiName})
      : super(AuditLogType.emojiCreate, serverId, userId, ctx: ctx);
}

final class EmojiUpdateAuditLog extends AuditLog {
  final String beforeEmojiName;
  final String afterEmojiName;

  EmojiUpdateAuditLog(
      {required Snowflake serverId,
      required Snowflake userId,
      required EntityContext ctx,
      required this.beforeEmojiName,
      required this.afterEmojiName})
      : super(AuditLogType.emojiUpdate, serverId, userId, ctx: ctx);
}

final class EmojiDeleteAuditLog extends AuditLog {
  final String emojiName;

  EmojiDeleteAuditLog(
      {required Snowflake serverId,
      required Snowflake userId,
      required EntityContext ctx,
      required this.emojiName})
      : super(AuditLogType.emojiDelete, serverId, userId, ctx: ctx);
}
