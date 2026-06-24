import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/api/guild/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class MessageDeleteAuditLog extends AuditLog {
  final Snowflake messageId;
  final Snowflake? channelId;

  MessageDeleteAuditLog({
    required Snowflake guildId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.messageId,
    this.channelId,
  }) : super(AuditLogType.messageDelete, guildId, userId, ctx: ctx);
}

final class MessageBulkDeleteAuditLog extends AuditLog {
  final int count;
  final Snowflake? channelId;

  MessageBulkDeleteAuditLog({
    required Snowflake guildId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.count,
    this.channelId,
  }) : super(AuditLogType.messageBulkDelete, guildId, userId, ctx: ctx);
}

final class MessagePinAuditLog extends AuditLog {
  DataStoreContract get _datastore => ctx.datastore;

  final Snowflake messageId;
  final Snowflake? channelId;

  MessagePinAuditLog({
    required Snowflake guildId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.messageId,
    this.channelId,
  }) : super(AuditLogType.messagePin, guildId, userId, ctx: ctx);

  Future<GuildMessage> resolveMessage({bool force = false}) async {
    final message = await _datastore.message
        .get<GuildMessage>(guildId.value, messageId.value, force);
    return message!;
  }
}

final class MessageUnpinAuditLog extends AuditLog {
  DataStoreContract get _datastore => ctx.datastore;

  final Snowflake messageId;
  final Snowflake? channelId;

  MessageUnpinAuditLog({
    required Snowflake guildId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.messageId,
    this.channelId,
  }) : super(AuditLogType.messageUnpin, guildId, userId, ctx: ctx);

  Future<GuildMessage> resolveMessage({bool force = false}) async {
    final message = await _datastore.message
        .get<GuildMessage>(guildId.value, messageId.value, force);
    return message!;
  }
}
