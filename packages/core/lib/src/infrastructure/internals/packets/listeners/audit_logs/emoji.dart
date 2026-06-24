import 'package:mineral/api.dart';
import 'package:mineral/src/api/guild/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

Future<AuditLog> emojiCreateAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  final changes = json['changes'] as List<dynamic>;
  return EmojiCreateAuditLog(
      guildId: Snowflake.parse(json['guild_id']),
      emojiName: (changes[0] as Map<String, dynamic>)['new_value'] as String,
      userId: Snowflake.parse(json['user_id']),
      ctx: ctx);
}

Future<AuditLog> emojiUpdateAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  final changes = json['changes'] as List<dynamic>;
  return EmojiUpdateAuditLog(
      guildId: Snowflake.parse(json['guild_id']),
      beforeEmojiName: (changes[0] as Map<String, dynamic>)['old_value'] as String,
      afterEmojiName: (changes[0] as Map<String, dynamic>)['new_value'] as String,
      userId: Snowflake.parse(json['user_id']),
      ctx: ctx);
}

Future<AuditLog> emojiDeleteAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  final changes = json['changes'] as List<dynamic>;
  return EmojiDeleteAuditLog(
      guildId: Snowflake.parse(json['guild_id']),
      emojiName: (changes[0] as Map<String, dynamic>)['old_value'] as String,
      userId: Snowflake.parse(json['user_id']),
      ctx: ctx);
}
