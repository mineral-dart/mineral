import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/api/server/channels/private_thread_channel.dart';
import 'package:mineral/src/api/server/channels/public_thread_channel.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/base_part.dart';
import 'package:mineral/src/infrastructure/internals/http/discord_header.dart';
import 'package:mineral/src/infrastructure/io/exceptions/serialization_exception.dart';

final class ThreadPart extends BasePart implements ThreadPartContract {
  ThreadPart(super.marshaller, super.dataStore);

  @override
  Future<ThreadResult> fetchActives(Object serverId) async {
    final guildId = Snowflake.parse(serverId);
    final request = Request.json(endpoint: '/guilds/$guildId/threads/active');
    final result = await dataStore.requestBucket
        .query<List<Map<String, dynamic>>>(request)
        .run(dataStore.client.get);

    final channels = await result.map((element) async {
      final raw = await marshaller.serializers.channels.normalize(element);
      return marshaller.serializers.channels.serialize(raw);
    }).wait;

    return ThreadResult(channels
        .asMap()
        .map((key, value) => MapEntry(value.id, value as ServerChannel)));
  }

  @override
  Future<Map<Snowflake, PublicThreadChannel>> fetchPublicArchived(
      Object channelId) async {
    final req = Request.json(endpoint: '/channels/$channelId/archived/public');
    final result = await dataStore.requestBucket
        .query<List<Map<String, dynamic>>>(req)
        .run(dataStore.client.get);

    final channels = await result.map((element) async {
      final raw = await marshaller.serializers.channels.normalize(element);
      return marshaller.serializers.channels.serialize(raw);
    }).wait;

    return channels
        .asMap()
        .map((key, value) => MapEntry(value.id, value as PublicThreadChannel));
  }

  @override
  Future<Map<Snowflake, PrivateThreadChannel>> fetchPrivateArchived(
      Object channelId) async {
    final req = Request.json(endpoint: '/channels/$channelId/archived/private');
    final result = await dataStore.requestBucket
        .query<List<Map<String, dynamic>>>(req)
        .run(dataStore.client.get);

    final channels = await result.map((element) async {
      final raw = await marshaller.serializers.channels.normalize(element);
      return marshaller.serializers.channels.serialize(raw);
    }).wait;

    return channels
        .asMap()
        .map((key, value) => MapEntry(value.id, value as PrivateThreadChannel));
  }

  @override
  Future<T> createWithoutMessage<T extends ThreadChannel>(
      Object? serverId, Object? channelId, ThreadChannelBuilder builder,
      {String? reason}) async {
    final guildId = serverId != null ? Snowflake.parse(serverId) : null;
    final req = Request.json(
        endpoint: '/channels/$channelId/threads',
        body: builder.build(),
        headers: {DiscordHeader.auditLogReason(reason)});

    final result = await dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(dataStore.client.post);

    final raw = await marshaller.serializers.channels.normalize(result);
    final serialized = await marshaller.serializers.channels.serialize({
      ...raw,
      'guild_id': guildId,
    });
    if (serialized is! T)
      throw SerializationException(
          'Expected $T but got ${serialized.runtimeType}');

    return serialized;
  }

  @override
  Future<T> createFromMessage<T extends ThreadChannel>(Object? serverId,
      Object? channelId, Object? messageId, ThreadChannelBuilder builder,
      {String? reason}) async {
    final guildId = serverId != null ? Snowflake.parse(serverId) : null;
    final req = Request.json(
        endpoint: '/channels/$channelId/messages/$messageId/threads',
        body: builder.build(),
        headers: {DiscordHeader.auditLogReason(reason)});

    final result = await dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(dataStore.client.post);

    final raw = await marshaller.serializers.channels.normalize(result);
    final serialized = await marshaller.serializers.channels.serialize({
      ...raw,
      'guild_id': guildId,
    });
    if (serialized is! T)
      throw SerializationException(
          'Expected $T but got ${serialized.runtimeType}');

    return serialized;
  }
}
