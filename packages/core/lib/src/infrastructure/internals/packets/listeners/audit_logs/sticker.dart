import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/api/server/audit_log/actions/sticker.dart';
import 'package:mineral/src/api/server/audit_log/audit_log.dart';

Future<AuditLog> stickerCreateAuditLogHandler(
    Map<String, dynamic> json, DataStoreContract datastore) async {
  final sticker =
      await datastore.sticker.get(json['guild_id'] as String, json['target_id'] as String, false);

  return StickerCreateAuditLog(
    serverId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    stickerId: Snowflake.parse(json['target_id']),
    sticker: sticker!,
  );
}

Future<AuditLog> stickerUpdateAuditLogHandler(
    Map<String, dynamic> json, DataStoreContract datastore) async {
  final sticker =
      await datastore.sticker.get(json['guild_id'] as String, json['target_id'] as String, false);

  return StickerUpdateAuditLog(
    serverId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    stickerId: Snowflake.parse(json['target_id']),
    changes: List<Map<String, dynamic>>.from(json['changes'] as Iterable<dynamic>)
        .map(Change.fromJson)
        .toList(),
    sticker: sticker!,
  );
}

Future<AuditLog> stickerDeleteAuditLogHandler(Map<String, dynamic> json) async {
  return StickerDeleteAuditLog(
    serverId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    stickerId: Snowflake.parse(json['target_id']),
  );
}
