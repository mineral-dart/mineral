import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/base_part.dart';
import 'package:mineral/src/infrastructure/internals/http/discord_header.dart';
import 'package:mineral/src/infrastructure/io/exceptions/serialization_exception.dart';

final class ChannelPart extends BasePart implements ChannelPartContract {
  ChannelPart(super.marshaller, super.dataStore);

  @override
  Future<Map<Snowflake, T>> fetch<T extends Channel>(
      Object serverId, bool force) async {
    final req = Request.json(endpoint: '/guilds/$serverId/channels');
    final result = await dataStore.requestBucket
        .query<List<Map<String, dynamic>>>(req)
        .run(dataStore.client.get);

    final channels = await result.map((element) async {
      final raw = await marshaller.serializers.channels.normalize(element);
      return marshaller.serializers.channels.serialize(raw);
    }).wait;

    return channels.asMap().map((_, value) {
      if (value is! T)
        throw SerializationException(
            'Expected $T but got ${value.runtimeType}');
      return MapEntry(value.id, value);
    });
  }

  @override
  Future<T?> get<T extends Channel>(Object id, bool force) async {
    final String key = marshaller.cacheKey.channel(id);
    final cachedChannel = await marshaller.cache?.get(key);
    if (!force && cachedChannel != null) {
      final serialized =
          await marshaller.serializers.channels.serialize(cachedChannel);
      if (serialized is! T)
        throw SerializationException(
            'Expected $T but got ${serialized.runtimeType}');

      return serialized;
    }

    final req = Request.json(endpoint: '/channels/$id');
    final result = await dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(dataStore.client.get);

    final raw = await marshaller.serializers.channels.normalize(result);
    final serialized = await marshaller.serializers.channels.serialize(raw);
    if (serialized is! T)
      throw SerializationException(
          'Expected $T but got ${serialized.runtimeType}');

    return serialized;
  }

  @override
  Future<T> create<T extends Channel>(
      Object? serverId, ChannelBuilderContract builder,
      {String? reason}) async {
    final req = Request.json(
        endpoint: '/guilds/$serverId/channels',
        body: builder.build(),
        headers: {DiscordHeader.auditLogReason(reason)});

    final result = await dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(dataStore.client.post);

    final raw = await marshaller.serializers.channels.normalize(result);
    final serialized = await marshaller.serializers.channels.serialize({
      ...raw,
      'guild_id': serverId,
    });
    if (serialized is! T)
      throw SerializationException(
          'Expected $T but got ${serialized.runtimeType}');

    return serialized;
  }

  @override
  Future<PrivateChannel> createPrivateChannel(
      Object id, Object recipientId) async {
    final req = Request.json(
        endpoint: '/users/@me/channels', body: {'recipient_id': recipientId});

    final result = await dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(dataStore.client.post);

    final raw = await marshaller.serializers.channels.normalize(result);
    final channel = await marshaller.serializers.channels.serialize(raw);

    return channel as PrivateChannel;
  }

  @override
  Future<T?> update<T extends Channel>(
      Object id, ChannelBuilderContract builder,
      {Object? serverId, String? reason}) async {
    final req = Request.json(
        endpoint: '/channels/$id',
        body: builder.build(),
        headers: {DiscordHeader.auditLogReason(reason)});

    final result = await dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(dataStore.client.patch);

    final raw = await marshaller.serializers.channels.normalize(result);
    final serialized = await marshaller.serializers.channels.serialize({
      ...raw,
      'guild_id': serverId,
    });
    if (serialized is! T)
      throw SerializationException(
          'Expected $T but got ${serialized.runtimeType}');

    return serialized;
  }

  @override
  Future<void> delete(Object id, String? reason) async {
    final req = Request.json(
        endpoint: '/channels/$id',
        headers: {DiscordHeader.auditLogReason(reason)});

    await dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(dataStore.client.delete);
  }
}
