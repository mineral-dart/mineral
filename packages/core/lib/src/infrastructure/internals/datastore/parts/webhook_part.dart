import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/domains/common/utils/attachment.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/base_part.dart';
import 'package:mineral/src/infrastructure/internals/http/discord_header.dart';

final class WebhookPart extends BasePart implements WebhookPartContract {
  WebhookPart(super.marshaller, super.dataStore);

  @override
  Future<Map<Snowflake, Webhook>> fetchForChannel(Object channelId) async {
    final req = Request.json(endpoint: '/channels/$channelId/webhooks');
    final result =
        await dataStore.requestBucket.get<List<Map<String, dynamic>>>(req);

    final webhooks = await result.map((json) async {
      final raw = await marshaller.serializers.webhook.normalize(json);
      return marshaller.serializers.webhook.serialize(raw);
    }).wait;

    return {for (final w in webhooks) w.id: w};
  }

  @override
  Future<Map<Snowflake, Webhook>> fetchForServer(Object serverId) async {
    final req = Request.json(endpoint: '/guilds/$serverId/webhooks');
    final result =
        await dataStore.requestBucket.get<List<Map<String, dynamic>>>(req);

    final webhooks = await result.map((json) async {
      final raw = await marshaller.serializers.webhook.normalize(json);
      return marshaller.serializers.webhook.serialize(raw);
    }).wait;

    return {for (final w in webhooks) w.id: w};
  }

  @override
  Future<Webhook?> get(Object id, bool force) async {
    final cacheKey = marshaller.cacheKey.webhook(id);

    final cached = await marshaller.cache?.get(cacheKey);
    if (!force && cached != null) {
      return marshaller.serializers.webhook.serialize(cached);
    }

    final req = Request.json(endpoint: '/webhooks/$id');
    final result = await dataStore.requestBucket.get<Map<String, dynamic>>(req);

    final raw = await marshaller.serializers.webhook.normalize(result);
    return marshaller.serializers.webhook.serialize(raw);
  }

  @override
  Future<Webhook?> getWithToken(Object id, String token) async {
    final req = Request.json(endpoint: '/webhooks/$id/$token');
    final result = await dataStore.requestBucket.get<Map<String, dynamic>>(req);

    final raw = await marshaller.serializers.webhook.normalize(result);
    return marshaller.serializers.webhook.serialize(raw);
  }

  @override
  Future<Webhook> create({
    required Object channelId,
    required String name,
    String? avatar,
    String? reason,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      if (avatar != null) 'avatar': avatar,
    };

    final req = Request.json(
      endpoint: '/channels/$channelId/webhooks',
      body: body,
      headers: {DiscordHeader.auditLogReason(reason)},
    );

    final result =
        await dataStore.requestBucket.post<Map<String, dynamic>>(req);

    final raw = await marshaller.serializers.webhook.normalize(result);
    return marshaller.serializers.webhook.serialize(raw);
  }

  @override
  Future<Webhook?> update({
    required Object id,
    String? name,
    String? avatar,
    Object? channelId,
    String? reason,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (avatar != null) 'avatar': avatar,
      if (channelId != null) 'channel_id': channelId.toString(),
    };

    final req = Request.json(
      endpoint: '/webhooks/$id',
      body: body,
      headers: {DiscordHeader.auditLogReason(reason)},
    );

    final result =
        await dataStore.requestBucket.patch<Map<String, dynamic>>(req);

    final raw = await marshaller.serializers.webhook.normalize(result);
    return marshaller.serializers.webhook.serialize(raw);
  }

  @override
  Future<Webhook?> updateWithToken({
    required Object id,
    required String token,
    String? name,
    String? avatar,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (avatar != null) 'avatar': avatar,
    };

    final req =
        Request.json(endpoint: '/webhooks/$id/$token', body: body);

    final result =
        await dataStore.requestBucket.patch<Map<String, dynamic>>(req);

    final raw = await marshaller.serializers.webhook.normalize(result);
    return marshaller.serializers.webhook.serialize(raw);
  }

  @override
  Future<void> delete({required Object id, String? reason}) async {
    final req = Request.json(
      endpoint: '/webhooks/$id',
      headers: {DiscordHeader.auditLogReason(reason)},
    );
    await dataStore.requestBucket.delete<Map<String, dynamic>>(req);
  }

  @override
  Future<void> deleteWithToken(
      {required Object id, required String token}) async {
    final req = Request.json(endpoint: '/webhooks/$id/$token');
    await dataStore.requestBucket.delete<Map<String, dynamic>>(req);
  }

  @override
  Future<Message?> execute({
    required Object id,
    required String token,
    required MessageBuilder builder,
    Object? threadId,
    bool wait = true,
  }) async {
    final (components, files) = makeAttachmentFromBuilder(builder);

    final body = <String, dynamic>{
      'flags': MessageFlagType.isComponentV2.value,
      'components': components,
    };

    final query = <String, String>{
      'wait': wait.toString(),
      if (threadId != null) 'thread_id': threadId.toString(),
    };

    final endpoint = '/webhooks/$id/$token';
    final req = files.isEmpty
        ? Request.json(
            endpoint: endpoint,
            body: body,
            queryParameters: query,
          )
        : Request.formData(
            endpoint: endpoint,
            body: body,
            files: files,
          ).copyWith(queryParameters: query);

    final result =
        await dataStore.requestBucket.post<Map<String, dynamic>>(req);

    if (!wait || result.isEmpty) {
      return null;
    }

    final raw = await marshaller.serializers.message.normalize(result);
    return marshaller.serializers.message.serialize(raw);
  }

  @override
  Future<Message?> getMessage({
    required Object id,
    required String token,
    required Object messageId,
    Object? threadId,
  }) async {
    final req = Request.json(
      endpoint: '/webhooks/$id/$token/messages/$messageId',
      queryParameters: {
        if (threadId != null) 'thread_id': threadId.toString(),
      },
    );

    final result = await dataStore.requestBucket.get<Map<String, dynamic>>(req);

    if (result.isEmpty) {
      return null;
    }

    final raw = await marshaller.serializers.message.normalize(result);
    return marshaller.serializers.message.serialize(raw);
  }

  @override
  Future<Message?> editMessage({
    required Object id,
    required String token,
    required Object messageId,
    required MessageBuilder builder,
    Object? threadId,
  }) async {
    final (components, files) = makeAttachmentFromBuilder(builder);

    final body = <String, dynamic>{
      'flags': MessageFlagType.isComponentV2.value,
      'components': components,
    };

    final query = <String, String>{
      if (threadId != null) 'thread_id': threadId.toString(),
    };

    final endpoint = '/webhooks/$id/$token/messages/$messageId';
    final req = files.isEmpty
        ? Request.json(
            endpoint: endpoint,
            body: body,
            queryParameters: query,
          )
        : Request.formData(
            endpoint: endpoint,
            body: body,
            files: files,
          ).copyWith(queryParameters: query);

    final result =
        await dataStore.requestBucket.patch<Map<String, dynamic>>(req);

    if (result.isEmpty) {
      return null;
    }

    final raw = await marshaller.serializers.message.normalize(result);
    return marshaller.serializers.message.serialize(raw);
  }

  @override
  Future<void> deleteMessage({
    required Object id,
    required String token,
    required Object messageId,
    Object? threadId,
  }) async {
    final req = Request.json(
      endpoint: '/webhooks/$id/$token/messages/$messageId',
      queryParameters: {
        if (threadId != null) 'thread_id': threadId.toString(),
      },
    );
    await dataStore.requestBucket.delete<Map<String, dynamic>>(req);
  }

  @override
  Future<void> executeGithub({
    required Object id,
    required String token,
    required Map<String, dynamic> payload,
    Object? threadId,
  }) async {
    final req = Request.json(
      endpoint: '/webhooks/$id/$token/github',
      body: payload,
      queryParameters: {
        if (threadId != null) 'thread_id': threadId.toString(),
      },
    );
    await dataStore.requestBucket.post<Map<String, dynamic>>(req);
  }

  @override
  Future<void> executeSlack({
    required Object id,
    required String token,
    required Map<String, dynamic> payload,
    Object? threadId,
  }) async {
    final req = Request.json(
      endpoint: '/webhooks/$id/$token/slack',
      body: payload,
      queryParameters: {
        if (threadId != null) 'thread_id': threadId.toString(),
      },
    );
    await dataStore.requestBucket.post<Map<String, dynamic>>(req);
  }
}
