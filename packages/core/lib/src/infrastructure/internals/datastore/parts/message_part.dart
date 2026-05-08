import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/api/common/polls/poll_answer_vote.dart';
import 'package:mineral/src/domains/common/utils/attachment.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/base_part.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/response_handler.dart';
import 'package:mineral/src/infrastructure/io/exceptions/serialization_exception.dart';

final class MessagePart extends BasePart
    with ResponseHandler
    implements MessagePartContract {
  MessagePart(super.marshaller, super.dataStore);

  @override
  Future<Map<Snowflake, T>> fetch<T extends BaseMessage>(
    Object channelId, {
    Snowflake? around,
    Snowflake? before,
    Snowflake? after,
    int? limit,
  }) async {
    final query = {
      if (around != null) 'around': around.value,
      if (before != null) 'before': before.value,
      if (after != null) 'after': after.value,
      if (limit != null) 'limit': limit,
    };

    final req = Request.json(
      endpoint: query.isEmpty
          ? '/channels/$channelId/messages'
          : '/channels/$channelId/messages?${query.entries.map((e) => '${e.key}=${e.value}').join('&')}',
    );
    final response = await dataStore.client.get(req);

    final messages = await handleResponse(
        response,
        (body) => Future.wait(
              List.from(body as Iterable<dynamic>).map((e) async => marshaller
                  .serializers.message
                  .normalize(e as Map<String, dynamic>)),
            ));

    final serializedMessages = await Future.wait(
      messages.map((e) async {
        final msg = await marshaller.serializers.message.serialize(e);
        if (msg is! T) {
          throw SerializationException(
            'Expected $T but got ${msg.runtimeType}',
          );
        }
        return msg as T;
      }),
    );

    final Map<Snowflake, T> results = serializedMessages.fold(
      {},
      (previousValue, element) => {...previousValue, element.id: element},
    );

    return results;
  }

  @override
  Future<T?> get<T extends BaseMessage>(
    Object channelId,
    Object id,
    bool force,
  ) async {
    final messageId = Snowflake.parse(id);
    final cacheKey = marshaller.cacheKey.message(channelId, messageId.value);
    final cachedMessage = await marshaller.cache?.get(cacheKey);
    if (!force && cachedMessage != null) {
      final message = await marshaller.serializers.message.serialize(
        cachedMessage,
      );
      if (message is! T) {
        throw SerializationException(
          'Expected $T but got ${message.runtimeType}',
        );
      }
      return message as T;
    }

    final req =
        Request.json(endpoint: '/channels/$channelId/messages/$messageId');
    final response = await dataStore.client.get(req);

    final message = await handleResponse(
        response,
        (body) => marshaller.serializers.message
            .normalize(body as Map<String, dynamic>));

    final serialized = await marshaller.serializers.message.serialize(message);
    if (serialized is! T) {
      throw SerializationException(
        'Expected $T but got ${serialized.runtimeType}',
      );
    }
    return serialized as T;
  }

  @override
  Future<T> update<T extends Message>({
    required Object id,
    required Object channelId,
    required MessageBuilder builder,
  }) async {
    final messageId = Snowflake.parse(id);
    final (components, files) = makeAttachmentFromBuilder(builder);

    final payload = {
      'flags': MessageFlagType.isComponentV2.value,
      'components': components,
    };
    final req = switch (files.isEmpty) {
      true => Request.json(
          endpoint: '/channels/$channelId/messages/$messageId',
          body: payload,
        ),
      false => Request.formData(
          endpoint: '/channels/$channelId/messages/$messageId',
          body: payload,
          files: files,
        ),
    };

    final response = await dataStore.client.patch(req);

    final rawMessage = await handleResponse(
        response,
        (body) => marshaller.serializers.message
            .normalize(body as Map<String, dynamic>));

    final message = await marshaller.serializers.message.serialize(rawMessage);
    if (message is! T)
      throw SerializationException(
        'Expected $T but got ${message.runtimeType}',
      );
    return message;
  }

  @override
  Future<void> pin(Snowflake channelId, Snowflake id) async {
    final req = Request.json(endpoint: '/channels/$channelId/pins/$id');
    await dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(dataStore.client.put);
  }

  @override
  Future<void> unpin(Snowflake channelId, Snowflake id) async {
    final req = Request.json(endpoint: '/channels/$channelId/pins/$id');
    await dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(dataStore.client.delete);
  }

  @override
  Future<void> crosspost(Snowflake channelId, Snowflake id) async {
    final req = Request.json(
      endpoint: '/channels/$channelId/messages/$id/crosspost',
    );
    await dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(dataStore.client.post);
  }

  @override
  Future<void> delete(Snowflake channelId, Snowflake id) async {
    final req = Request.json(endpoint: '/channels/$channelId/messages/$id');
    await dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(dataStore.client.delete);
  }

  @override
  Future<T> send<T extends Message>(
    String? guildId,
    String channelId,
    MessageBuilder builder,
  ) async {
    final (components, files) = makeAttachmentFromBuilder(builder);

    final payload = {
      'flags': MessageFlagType.isComponentV2.value,
      'components': components,
    };
    final req = switch (files.isEmpty) {
      true => Request.json(
          endpoint: '/channels/$channelId/messages',
          body: payload,
        ),
      false => Request.formData(
          endpoint: '/channels/$channelId/messages',
          body: payload,
          files: files,
        ),
    };

    final response = await dataStore.client.post(req);

    final message = await handleResponse(
        response,
        (body) => marshaller.serializers.message
            .normalize(body as Map<String, dynamic>));

    final serialized = await marshaller.serializers.message.serialize(message);
    if (serialized is! T)
      throw SerializationException(
        'Expected $T but got ${serialized.runtimeType}',
      );
    return serialized;
  }

  @override
  Future<R> reply<T extends Channel, R extends Message>(
    Snowflake id,
    Snowflake channelId,
    MessageBuilder builder,
  ) async {
    final (components, files) = makeAttachmentFromBuilder(builder);

    final payload = {
      'flags': MessageFlagType.isComponentV2.value,
      'components': components,
      'message_reference': {'message_id': id, 'channel_id': channelId},
    };

    final req = Request.auto(
      endpoint: '/channels/$channelId/messages',
      body: payload,
      files: files,
    );

    final result = await dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(dataStore.client.post);

    final raw = await marshaller.serializers.message.normalize(result);
    final serialized = await marshaller.serializers.message.serialize(raw);
    if (serialized is! R)
      throw SerializationException(
        'Expected $R but got ${serialized.runtimeType}',
      );
    return serialized;
  }

  @override
  Future<T> sendPoll<T extends Message>(String channelId, Poll poll) async {
    final req = Request.json(
      endpoint: '/channels/$channelId/messages',
      body: {'poll': marshaller.serializers.poll.deserialize(poll)},
    );
    final response = await dataStore.client.post(req);

    final message = await handleResponse(
        response,
        (body) => marshaller.serializers.message
            .normalize(body as Map<String, dynamic>));

    final serializedMessage = await marshaller.serializers.message.serialize(
      message,
    );

    if (serializedMessage is! T)
      throw SerializationException(
        'Expected $T but got ${serializedMessage.runtimeType}',
      );
    return serializedMessage;
  }

  @override
  Future<PollAnswerVote> getPollVotes(
    Snowflake? serverId,
    Snowflake channelId,
    Snowflake messageId,
    int answerId,
  ) async {
    final req = Request.json(
      endpoint:
          '/channels/${channelId.value}/polls/${messageId.value}/answers/$answerId',
    );
    final body = await dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(dataStore.client.get);

    body['id'] = answerId;
    body['message_id'] = messageId.value;
    body['channel_id'] = channelId.value;
    body['server_id'] = serverId?.value;

    final answerPayload =
        await marshaller.serializers.pollAnswerVote.normalize(body);

    final answer = await marshaller.serializers.pollAnswerVote.serialize(
      answerPayload,
    );

    return answer;
  }
}
