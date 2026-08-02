import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/api/common/sticker.dart';
import 'package:mineral/src/api/common/types/format_type.dart';
import 'package:mineral/src/api/common/types/sticker_type.dart';
import 'package:mineral/src/domains/common/utils/utils.dart';
import 'package:mineral/src/domains/services/marshaller/marshaller.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/types/serializer.dart';

final class StickerSerializer implements SerializerContract<Sticker> {
  final MarshallerContract _marshaller;

  StickerSerializer(this._marshaller);

  @override
  Future<Map<String, dynamic>> normalize(Map<String, dynamic> json) async {
    final payload = {
      'id': json['id'],
      'name': json['name'],
      'type': json['type'],
      'available': json['available'],
      'pack_id': json['pack_id'],
      'description': json['description'],
      'tags': json['tags'],
      'asset': json['asset'],
      'format_type': json['format_type'],
      'sort_value': json['sort_value'],
      'guild_id': json['guild_id'],
    };

    // Standard-pack stickers (Discord's built-in packs) have no guild_id —
    // only guild-uploaded stickers are guild-scoped. There is no meaningful
    // guild-namespaced cache key for those, so they are normalized (and can
    // still be serialized) but simply not written to the cache.
    final guildId = json['guild_id'] as String?;
    if (guildId != null) {
      final cacheKey = _marshaller.cacheKey.sticker(
        guildId,
        json['id'] as String,
      );
      await _marshaller.cache?.put(cacheKey, payload);
    }

    return payload;
  }

  @override
  Sticker serialize(Map<String, dynamic> json) {
    return Sticker(
      id: Snowflake.parse(json['id']),
      name: json['name'] as String,
      // StickerType currently only declares standard/guild (Discord has
      // never documented a third value) and has no `unknown` sentinel to
      // route through findInEnum without editing sticker_type.dart, which is
      // outside this fix's scope. Guarded here with a safe fallback instead
      // of the unguarded firstWhere so an unexpected value can't throw.
      type: StickerType.values.firstWhere(
        (element) => element.value == json['type'],
        orElse: () => StickerType.standard,
      ),
      isAvailable: json['available'] as bool? ?? true,
      packId: json['pack_id'] as String?,
      description: json['description'] as String?,
      tags: json['tags'] as String?,
      asset: json['asset'] as String?,
      formatType: findInEnum(
        FormatType.values,
        json['format_type'] as int?,
        orElse: FormatType.unknown,
      ),
      sortValue: json['sort_value'] as int?,
      guildId: Snowflake.nullable(json['guild_id'] as String?),
    );
  }

  @override
  Map<String, dynamic> deserialize(Sticker sticker) {
    return {
      'id': sticker.id,
      'name': sticker.name,
      'type': sticker.type.value,
      'available': sticker.isAvailable,
      'pack_id': sticker.packId,
      'description': sticker.description,
      'tags': sticker.tags,
      'asset': sticker.asset,
      'format_type': sticker.formatType?.value,
      'sort_value': sticker.sortValue,
      'guild_id': sticker.guildId,
    };
  }
}
