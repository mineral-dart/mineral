import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/api/common/sticker.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/base_part.dart';

final class StickerPart extends BasePart implements StickerPartContract {
  StickerPart(super.marshaller, super.dataStore);

  @override
  Future<Map<Snowflake, Sticker>> fetch(Object guildId, bool force) async {
    final parsedGuildId = Snowflake.parse(guildId);
    final req = Request.json(endpoint: '/guilds/$parsedGuildId/stickers');
    final result = await dataStore.requestBucket
        .get<List<Map<String, dynamic>>>(req);

    final stickers = await result.map((element) async {
      final raw = await marshaller.serializers.sticker.normalize(element);
      return marshaller.serializers.sticker.serialize(raw);
    }).wait;

    return stickers.asMap().map((_, value) => MapEntry(value.id, value));
  }

  @override
  Future<Sticker?> get(Object guildId, Object stickerId, bool force) async {
    final parsedGuildId = Snowflake.parse(guildId);
    final String key = marshaller.cacheKey.sticker(
      parsedGuildId.value,
      stickerId,
    );

    final cachedSticker = await marshaller.cache?.get(key);
    if (!force && cachedSticker != null) {
      final sticker = await marshaller.serializers.sticker.serialize(
        cachedSticker,
      );

      return sticker;
    }

    final req = Request.json(
      endpoint: '/guilds/$parsedGuildId/stickers/$stickerId',
    );
    final result = await dataStore.requestBucket.get<Map<String, dynamic>>(req);

    final raw = await marshaller.serializers.sticker.normalize(result);
    final sticker = await marshaller.serializers.sticker.serialize(raw);

    return sticker;
  }

  @override
  Future<void> delete(Object guildId, Object stickerId) async {
    final parsedGuildId = Snowflake.parse(guildId);
    final req = Request.json(
      endpoint: '/guilds/$parsedGuildId/stickers/$stickerId',
    );
    await dataStore.requestBucket.delete<Map<String, dynamic>>(req);
  }
}
