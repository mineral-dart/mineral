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
    final guildId = Snowflake.parse(serverId);
    final req = Request.json(endpoint: '/guilds/$guildId/channels');
    final result = await dataStore.requestBucket.get<List<Map<String, dynamic>>>(req);

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
    final channelId = Snowflake.parse(id);
    final String key = marshaller.cacheKey.channel(channelId.value);
    final cachedChannel = await marshaller.cache?.get(key);
    if (!force && cachedChannel != null) {
      final serialized =
          await marshaller.serializers.channels.serialize(cachedChannel);
      if (serialized is! T)
        throw SerializationException(
            'Expected $T but got ${serialized.runtimeType}');

      return serialized;
    }

    final req = Request.json(endpoint: '/channels/$channelId');
    final result = await dataStore.requestBucket.get<Map<String, dynamic>>(req);

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
    final guildId = serverId != null ? Snowflake.parse(serverId) : null;
    final req = Request.json(
        endpoint: '/guilds/$guildId/channels',
        body: builder.build(),
        headers: {DiscordHeader.auditLogReason(reason)});

    final result = await dataStore.requestBucket.post<Map<String, dynamic>>(req);

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
  Future<PrivateChannel> createPrivateChannel(
      Object id, Object recipientId) async {
    final userId = Snowflake.parse(recipientId);
    final req = Request.json(
        endpoint: '/users/@me/channels', body: {'recipient_id': userId});

    final result = await dataStore.requestBucket.post<Map<String, dynamic>>(req);

    final raw = await marshaller.serializers.channels.normalize(result);
    final channel = await marshaller.serializers.channels.serialize(raw);

    return channel as PrivateChannel;
  }

  @override
  Future<T?> update<T extends Channel>(
      Object id, ChannelBuilderContract builder,
      {Object? serverId, String? reason}) async {
    final channelId = Snowflake.parse(id);
    final guildId = serverId != null ? Snowflake.parse(serverId) : null;
    final req = Request.json(
        endpoint: '/channels/$channelId',
        body: builder.build(),
        headers: {DiscordHeader.auditLogReason(reason)});

    final result = await dataStore.requestBucket.patch<Map<String, dynamic>>(req);

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
  Future<void> delete(Object id, String? reason) async {
    final channelId = Snowflake.parse(id);
    final req = Request.json(
        endpoint: '/channels/$channelId',
        headers: {DiscordHeader.auditLogReason(reason)});

    await dataStore.requestBucket.delete<Map<String, dynamic>>(req);
  }
}
