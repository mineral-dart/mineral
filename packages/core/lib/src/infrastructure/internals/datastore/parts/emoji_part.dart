import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/base_part.dart';
import 'package:mineral/src/infrastructure/internals/http/discord_header.dart';

final class EmojiPart extends BasePart implements EmojiPartContract {
  EmojiPart(super.marshaller, super.dataStore);

  @override
  Future<Map<Snowflake, Emoji>> fetch(Object serverId, bool force) async {
    final guildId = Snowflake.parse(serverId);
    final req = Request.json(endpoint: '/guilds/$guildId/emojis');
    final result = await dataStore.requestBucket
        .query<List<Map<String, dynamic>>>(req)
        .run(dataStore.client.get);

    final emojis = await result.map((element) async {
      final raw = await marshaller.serializers.emojis.normalize(element);
      return marshaller.serializers.emojis.serialize(raw);
    }).wait;

    return emojis.asMap().map((_, value) => MapEntry(value.id!, value));
  }

  @override
  Future<Emoji?> get(Object serverId, Object emojiId, bool force) async {
    final guildId = Snowflake.parse(serverId);
    final String key = marshaller.cacheKey.serverEmoji(guildId.value, emojiId);

    final cachedEmoji = await marshaller.cache?.get(key);
    if (!force && cachedEmoji != null) {
      final emoji = await marshaller.serializers.emojis.serialize(cachedEmoji);
      return emoji;
    }

    final req = Request.json(endpoint: '/guilds/$guildId/emojis/$emojiId');
    final result = await dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(dataStore.client.get);

    final raw = await marshaller.serializers.emojis.normalize(result);
    final emoji = await marshaller.serializers.emojis.serialize(raw);

    return emoji;
  }

  @override
  Future<Emoji> create(
      Object serverId, String name, Image image, List<Object> roles,
      {String? reason}) async {
    final guildId = Snowflake.parse(serverId);
    final req = Request.json(endpoint: '/guilds/$guildId/emojis', body: {
      'name': name.replaceAll(' ', '_'),
      'image': image.base64,
      'roles': roles.isNotEmpty ? roles : null,
    }, headers: {
      DiscordHeader.auditLogReason(reason)
    });
    final result = await dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(dataStore.client.post);

    final raw = await marshaller.serializers.emojis.normalize({
      ...result,
      'guild_id': guildId,
    });
    final emoji = await marshaller.serializers.emojis.serialize(raw);

    return emoji;
  }

  @override
  Future<Emoji?> update(
      {required Object id,
      required Object serverId,
      required Map<String, dynamic> payload,
      required String? reason}) async {
    final emojiId = Snowflake.parse(id);
    final guildId = Snowflake.parse(serverId);
    final req = Request.json(
        endpoint: '/guilds/$guildId/emojis/$emojiId',
        body: payload,
        headers: {DiscordHeader.auditLogReason(reason)});

    final result = await dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(dataStore.client.patch);

    final raw = await marshaller.serializers.emojis.normalize({
      ...result,
      'guild_id': guildId,
    });
    final emoji = await marshaller.serializers.emojis.serialize(raw);

    return emoji;
  }

  @override
  Future<void> delete(Object serverId, Object emojiId, {String? reason}) async {
    final guildId = Snowflake.parse(serverId);
    final req = Request.json(
        endpoint: '/guilds/$guildId/emojis/$emojiId',
        headers: {DiscordHeader.auditLogReason(reason)});

    await dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(dataStore.client.delete);
  }
}
