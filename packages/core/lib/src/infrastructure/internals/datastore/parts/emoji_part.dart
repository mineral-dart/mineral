import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/infrastructure/internals/http/discord_header.dart';

final class EmojiPart implements EmojiPartContract {
  final MarshallerContract _marshaller;
  final DataStoreContract _dataStore;

  EmojiPart(this._marshaller, this._dataStore);

  HttpClientStatus get status => _dataStore.client.status;

  @override
  Future<Map<Snowflake, Emoji>> fetch(Object serverId, bool force) async {
    final req = Request.json(endpoint: '/guilds/$serverId/emojis');
    final result = await _dataStore.requestBucket
        .query<List<Map<String, dynamic>>>(req)
        .run(_dataStore.client.get);

    final emojis = await result.map((element) async {
      final raw = await _marshaller.serializers.emojis.normalize(element);
      return _marshaller.serializers.emojis.serialize(raw);
    }).wait;

    return emojis.asMap().map((_, value) => MapEntry(value.id!, value));
  }

  @override
  Future<Emoji?> get(Object serverId, Object emojiId, bool force) async {
    final String key = _marshaller.cacheKey.serverEmoji(serverId, emojiId);

    final cachedEmoji = await _marshaller.cache?.get(key);
    if (!force && cachedEmoji != null) {
      final emoji = await _marshaller.serializers.emojis.serialize(cachedEmoji);
      return emoji;
    }

    final req = Request.json(endpoint: '/guilds/$serverId/emojis/$emojiId');
    final result = await _dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(_dataStore.client.get);

    final raw = await _marshaller.serializers.emojis.normalize(result);
    final emoji = await _marshaller.serializers.emojis.serialize(raw);

    return emoji;
  }

  @override
  Future<Emoji> create(
      Object serverId, String name, Image image, List<Object> roles,
      {String? reason}) async {
    final req = Request.json(endpoint: '/guilds/$serverId/emojis', body: {
      'name': name.replaceAll(' ', '_'),
      'image': image.base64,
      'roles': roles.isNotEmpty ? roles : null,
    }, headers: {
      DiscordHeader.auditLogReason(reason)
    });
    final result = await _dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(_dataStore.client.post);

    final raw = await _marshaller.serializers.emojis.normalize({
      ...result,
      'guild_id': serverId,
    });
    final emoji = await _marshaller.serializers.emojis.serialize(raw);

    return emoji;
  }

  @override
  Future<Emoji?> update(
      {required Object id,
      required Object serverId,
      required Map<String, dynamic> payload,
      required String? reason}) async {
    final req = Request.json(
        endpoint: '/guilds/$serverId/emojis/$id',
        body: payload,
        headers: {DiscordHeader.auditLogReason(reason)});

    final result = await _dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(_dataStore.client.patch);

    final raw = await _marshaller.serializers.emojis.normalize({
      ...result,
      'guild_id': serverId,
    });
    final emoji = await _marshaller.serializers.emojis.serialize(raw);

    return emoji;
  }

  @override
  Future<void> delete(Object serverId, Object emojiId, {String? reason}) async {
    final req = Request.json(
        endpoint: '/guilds/$serverId/emojis/$emojiId',
        headers: {DiscordHeader.auditLogReason(reason)});

    await _dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(_dataStore.client.delete);
  }
}
