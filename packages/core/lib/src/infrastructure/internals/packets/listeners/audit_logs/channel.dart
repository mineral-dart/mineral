import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/api/server/audit_log/audit_log.dart';

Future<AuditLog> channelCreateAuditLogHandler(
    Map<String, dynamic> json, DataStoreContract datastore) async {
  final channel = await datastore.channel.get(json['target_id'] as String, false);

  return ChannelCreateAuditLogAction(
      serverId: Snowflake.parse(json['guild_id']),
      userId: Snowflake.parse(json['user_id']),
      channel: channel!);
}

Future<AuditLog> channelUpdateAuditLogHandler(
    Map<String, dynamic> json, DataStoreContract datastore) async {
  final channel = await datastore.channel.get(json['target_id'] as String, false);

  return ChannelUpdateAuditLogAction(
      serverId: Snowflake.parse(json['guild_id']),
      userId: Snowflake.parse(json['user_id']),
      channel: channel!,
      changes:
          List<Change>.from((json['changes'] as Iterable<dynamic>).map((e) => Change.fromJson(e as Map<String, dynamic>))));
}

Future<AuditLog> channelDeleteAuditLogHandler(Map<String, dynamic> json) async {
  return ChannelDeleteAuditLogAction(
      serverId: Snowflake.parse(json['guild_id']),
      userId: Snowflake.parse(json['user_id']),
      channelId: Snowflake.parse(json['target_id']),
      changes:
          List<Change>.from((json['changes'] as Iterable<dynamic>).map((e) => Change.fromJson(e as Map<String, dynamic>))));
}
