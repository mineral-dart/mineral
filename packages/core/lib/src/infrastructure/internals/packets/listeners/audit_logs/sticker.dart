import 'package:mineral/api.dart';
import 'package:mineral/src/api/guild/audit_log/actions/sticker.dart';
import 'package:mineral/src/api/guild/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

Future<AuditLog> stickerCreateAuditLogHandler(
  Map<String, dynamic> json,
  EntityContext ctx,
) async {
  final sticker = await ctx.datastore.sticker.get(
    json['guild_id'] as String,
    json['target_id'] as String,
    false,
  );

  return StickerCreateAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    stickerId: Snowflake.parse(json['target_id']),
    sticker: sticker!,
    ctx: ctx,
  );
}

Future<AuditLog> stickerUpdateAuditLogHandler(
  Map<String, dynamic> json,
  EntityContext ctx,
) async {
  final sticker = await ctx.datastore.sticker.get(
    json['guild_id'] as String,
    json['target_id'] as String,
    false,
  );

  return StickerUpdateAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    stickerId: Snowflake.parse(json['target_id']),
    changes: List<Map<String, dynamic>>.from(
      json['changes'] as Iterable<dynamic>,
    ).map(Change.fromJson).toList(),
    sticker: sticker!,
    ctx: ctx,
  );
}

Future<AuditLog> stickerDeleteAuditLogHandler(
  Map<String, dynamic> json,
  EntityContext ctx,
) async {
  return StickerDeleteAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    stickerId: Snowflake.parse(json['target_id']),
    ctx: ctx,
  );
}
