import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/base_part.dart';
import 'package:mineral/src/infrastructure/internals/http/discord_header.dart';

final class EmojiPart extends BasePart implements EmojiPartContract {
  EmojiPart(super.marshaller, super.dataStore);

  @override
  Future<Map<Snowflake, Emoji>> fetch(Object guildId, bool force) async {
    final parsedGuildId = Snowflake.parse(guildId);
    final req = Request.json(endpoint: '/guilds/$parsedGuildId/emojis');
    final result = await dataStore.requestBucket
        .get<List<Map<String, dynamic>>>(req);

    final emojis = await result.map((element) async {
      final raw = await marshaller.serializers.emojis.normalize(element);
      return marshaller.serializers.emojis.serialize(raw);
    }).wait;

    return emojis.asMap().map((_, value) => MapEntry(value.id!, value));
  }

  @override
  Future<Emoji?> get(Object guildId, Object emojiId, bool force) async {
    final parsedGuildId = Snowflake.parse(guildId);
    final String key = marshaller.cacheKey.guildEmoji(
      parsedGuildId.value,
      emojiId,
    );

    final cachedEmoji = await marshaller.cache?.get(key);
    if (!force && cachedEmoji != null) {
      final emoji = await marshaller.serializers.emojis.serialize(cachedEmoji);
      return emoji;
    }

    final req = Request.json(
      endpoint: '/guilds/$parsedGuildId/emojis/$emojiId',
    );
    final result = await dataStore.requestBucket.get<Map<String, dynamic>>(req);

    final raw = await marshaller.serializers.emojis.normalize(result);
    final emoji = await marshaller.serializers.emojis.serialize(raw);

    return emoji;
  }

  @override
  Future<Emoji> create(
    Object guildId,
    String name,
    Image image,
    List<Object> roles, {
    String? reason,
  }) async {
    final parsedGuildId = Snowflake.parse(guildId);
    final req = Request.json(
      endpoint: '/guilds/$parsedGuildId/emojis',
      body: {
        'name': name.replaceAll(' ', '_'),
        'image': image.base64,
        'roles': roles.isNotEmpty ? roles : null,
      },
      headers: {DiscordHeader.auditLogReason(reason)},
    );
    final result = await dataStore.requestBucket.post<Map<String, dynamic>>(
      req,
    );

    final raw = await marshaller.serializers.emojis.normalize({
      ...result,
      'guild_id': parsedGuildId,
    });
    final emoji = await marshaller.serializers.emojis.serialize(raw);

    return emoji;
  }

  @override
  Future<Emoji?> update({
    required Object id,
    required Object guildId,
    required Map<String, dynamic> payload,
    required String? reason,
  }) async {
    final emojiId = Snowflake.parse(id);
    final parsedGuildId = Snowflake.parse(guildId);
    final req = Request.json(
      endpoint: '/guilds/$parsedGuildId/emojis/$emojiId',
      body: payload,
      headers: {DiscordHeader.auditLogReason(reason)},
    );

    final result = await dataStore.requestBucket.patch<Map<String, dynamic>>(
      req,
    );

    final raw = await marshaller.serializers.emojis.normalize({
      ...result,
      'guild_id': parsedGuildId,
    });
    final emoji = await marshaller.serializers.emojis.serialize(raw);

    return emoji;
  }

  @override
  Future<void> delete(Object guildId, Object emojiId, {String? reason}) async {
    final parsedGuildId = Snowflake.parse(guildId);
    final req = Request.json(
      endpoint: '/guilds/$parsedGuildId/emojis/$emojiId',
      headers: {DiscordHeader.auditLogReason(reason)},
    );

    await dataStore.requestBucket.delete<Map<String, dynamic>>(req);
  }
}
