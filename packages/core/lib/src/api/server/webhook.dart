import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

enum WebhookType {
  incoming(1),
  channelFollower(2),
  application(3);

  const WebhookType(this.value);
  final int value;

  factory WebhookType.of(int value) =>
      values.firstWhere((e) => e.value == value);
}

final class Webhook {
  final EntityContext _ctx;
  DataStoreContract get _datastore => _ctx.datastore;

  final Snowflake id;
  final WebhookType type;
  final Snowflake? serverId;
  final Snowflake? channelId;
  final Snowflake? userId;
  final String? name;
  final String? avatar;
  final String? token;
  final Snowflake? applicationId;
  final String? url;

  Webhook({
    required EntityContext ctx,
    required this.id,
    required this.type,
    this.serverId,
    this.channelId,
    this.userId,
    this.name,
    this.avatar,
    this.token,
    this.applicationId,
    this.url,
  }) : _ctx = ctx;

  Future<T?> resolveChannel<T extends Channel>() async {
    if (channelId == null) {
      return null;
    }
    return _datastore.channel.get<T>(channelId!.value, false);
  }

  Future<User?> resolveOwner() async {
    if (userId == null) {
      return null;
    }
    return _datastore.user.get(userId!.value, false);
  }

  Future<Webhook?> update({
    String? name,
    String? avatar,
    Object? channelId,
    String? reason,
  }) {
    return _datastore.webhook.update(
      id: id.value,
      name: name,
      avatar: avatar,
      channelId: channelId,
      reason: reason,
    );
  }

  Future<void> delete({String? reason}) {
    return _datastore.webhook.delete(id: id.value, reason: reason);
  }
}
