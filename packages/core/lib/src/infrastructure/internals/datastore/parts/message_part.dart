import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/api/common/polls/poll_answer_vote.dart';
import 'package:mineral/src/domains/common/utils/attachment.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/base_part.dart';

final class MessagePart extends BasePart implements MessagePartContract {
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
      'limit': ?limit,
    };

    final req = Request.json(
      endpoint: query.isEmpty
          ? '/channels/$channelId/messages'
          : '/channels/$channelId/messages?${query.entries.map((e) => '${e.key}=${e.value}').join('&')}',
    );
    final body = await dataStore.requestBucket.get<List<dynamic>>(req);

    final messages = await Future.wait(
      body.map((e) async => marshaller.serializers.message
          .normalize(e as Map<String, dynamic>)),
    );

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
    final body = await dataStore.requestBucket.get<Map<String, dynamic>>(req);

    final message = await marshaller.serializers.message.normalize(body);
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

    final body = await dataStore.requestBucket.patch<Map<String, dynamic>>(req);

    final rawMessage = await marshaller.serializers.message.normalize(body);
    final message = await marshaller.serializers.message.serialize(rawMessage);
    if (message is! T) {
      throw SerializationException(
        'Expected $T but got ${message.runtimeType}',
      );
    }
    return message;
  }

  @override
  Future<void> pin(Snowflake channelId, Snowflake id) async {
    final req = Request.json(endpoint: '/channels/$channelId/pins/$id');
    await dataStore.requestBucket.put<Map<String, dynamic>>(req);
  }

  @override
  Future<void> unpin(Snowflake channelId, Snowflake id) async {
    final req = Request.json(endpoint: '/channels/$channelId/pins/$id');
    await dataStore.requestBucket.delete<Map<String, dynamic>>(req);
  }

  @override
  Future<void> crosspost(Snowflake channelId, Snowflake id) async {
    final req = Request.json(
      endpoint: '/channels/$channelId/messages/$id/crosspost',
    );
    await dataStore.requestBucket.post<Map<String, dynamic>>(req);
  }

  @override
  Future<void> delete(Snowflake channelId, Snowflake id) async {
    final req = Request.json(endpoint: '/channels/$channelId/messages/$id');
    await dataStore.requestBucket.delete<Map<String, dynamic>>(req);
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

    final body = await dataStore.requestBucket.post<Map<String, dynamic>>(req);

    final message = await marshaller.serializers.message.normalize(body);
    final serialized = await marshaller.serializers.message.serialize(message);
    if (serialized is! T) {
      throw SerializationException(
        'Expected $T but got ${serialized.runtimeType}',
      );
    }
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

    final result = await dataStore.requestBucket.post<Map<String, dynamic>>(req);

    final raw = await marshaller.serializers.message.normalize(result);
    final serialized = await marshaller.serializers.message.serialize(raw);
    if (serialized is! R) {
      throw SerializationException(
        'Expected $R but got ${serialized.runtimeType}',
      );
    }
    return serialized;
  }

  @override
  Future<T> forward<T extends Message>(
    Snowflake targetChannelId, {
    required Snowflake messageId,
    required Snowflake sourceChannelId,
    Snowflake? guildId,
  }) async {
    final ref = <String, dynamic>{
      'type': 1,
      'message_id': messageId.value,
      'channel_id': sourceChannelId.value,
      if (guildId != null) 'guild_id': guildId.value,
    };

    final req = Request.json(
      endpoint: '/channels/${targetChannelId.value}/messages',
      body: {'message_reference': ref},
    );

    final body = await dataStore.requestBucket.post<Map<String, dynamic>>(req);

    final raw = await marshaller.serializers.message.normalize(body);
    final serialized = await marshaller.serializers.message.serialize(raw);
    if (serialized is! T) {
      throw SerializationException(
        'Expected $T but got ${serialized.runtimeType}',
      );
    }
    return serialized;
  }

  @override
  Future<T> sendPoll<T extends Message>(String channelId, Poll poll) async {
    final req = Request.json(
      endpoint: '/channels/$channelId/messages',
      body: {'poll': marshaller.serializers.poll.deserialize(poll)},
    );
    final body = await dataStore.requestBucket.post<Map<String, dynamic>>(req);

    final message = await marshaller.serializers.message.normalize(body);
    final serializedMessage = await marshaller.serializers.message.serialize(
      message,
    );

    if (serializedMessage is! T) {
      throw SerializationException(
        'Expected $T but got ${serializedMessage.runtimeType}',
      );
    }
    return serializedMessage;
  }

  @override
  Future<PollAnswerVote> getPollVotes(
    Snowflake? guildId,
    Snowflake channelId,
    Snowflake messageId,
    int answerId,
  ) async {
    final req = Request.json(
      endpoint:
          '/channels/${channelId.value}/polls/${messageId.value}/answers/$answerId',
    );
    final body = await dataStore.requestBucket.get<Map<String, dynamic>>(req);

    body['id'] = answerId;
    body['message_id'] = messageId.value;
    body['channel_id'] = channelId.value;
    body['guild_id'] = guildId?.value;

    final answerPayload =
        await marshaller.serializers.pollAnswerVote.normalize(body);

    final answer = await marshaller.serializers.pollAnswerVote.serialize(
      answerPayload,
    );

    return answer;
  }
}
