import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/api/server/webhook.dart';
import 'package:mineral/src/domains/container/ioc_container.dart';
import 'package:mineral/src/domains/services/marshaller/marshaller.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/types/serializer.dart';

final class WebhookSerializer implements SerializerContract<Webhook> {
  MarshallerContract get _marshaller => ioc.resolve<MarshallerContract>();

  @override
  Future<Map<String, dynamic>> normalize(Map<String, dynamic> json) async {
    final user = json['user'] as Map<String, dynamic>?;

    final payload = {
      'id': json['id'],
      'type': json['type'],
      'guild_id': json['guild_id'],
      'channel_id': json['channel_id'],
      'user_id': user?['id'],
      'name': json['name'],
      'avatar': json['avatar'],
      'token': json['token'],
      'application_id': json['application_id'],
      'url': json['url'],
    };

    final cacheKey = _marshaller.cacheKey.webhook(json['id'] as String);
    await _marshaller.cache?.put(cacheKey, payload);

    return payload;
  }

  @override
  Future<Webhook> serialize(Map<String, dynamic> json) async {
    return Webhook(
      id: Snowflake.parse(json['id']),
      type: WebhookType.of(json['type'] as int),
      serverId: json['guild_id'] != null
          ? Snowflake.parse(json['guild_id'])
          : null,
      channelId: json['channel_id'] != null
          ? Snowflake.parse(json['channel_id'])
          : null,
      userId:
          json['user_id'] != null ? Snowflake.parse(json['user_id']) : null,
      name: json['name'] as String?,
      avatar: json['avatar'] as String?,
      token: json['token'] as String?,
      applicationId: json['application_id'] != null
          ? Snowflake.parse(json['application_id'])
          : null,
      url: json['url'] as String?,
    );
  }

  @override
  Map<String, dynamic> deserialize(Webhook webhook) {
    return {
      'id': webhook.id.value,
      'type': webhook.type.value,
      'guild_id': webhook.serverId?.value,
      'channel_id': webhook.channelId?.value,
      'user_id': webhook.userId?.value,
      'name': webhook.name,
      'avatar': webhook.avatar,
      'token': webhook.token,
      'application_id': webhook.applicationId?.value,
      'url': webhook.url,
    };
  }
}
