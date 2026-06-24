import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/api/common/types/format_type.dart';
import 'package:mineral/src/api/common/types/sticker_type.dart';

final class Sticker {
  final Snowflake id;
  final String? packId;
  final String name;
  final String? description;
  final String? tags;
  final String? asset;
  final StickerType type;
  final FormatType? formatType;
  final bool isAvailable;
  final int? sortValue;
  final Snowflake? guildId;

  Sticker({
    required this.id,
    required this.name,
    required this.type,
    required this.isAvailable,
    this.packId,
    this.description,
    this.tags,
    this.asset,
    this.formatType,
    this.sortValue,
    this.guildId,
  });
}
