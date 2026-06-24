import 'package:mineral/src/api/common/emoji.dart';
import 'package:mineral/src/api/common/snowflake.dart';

class PartialEmoji {
  final Snowflake? id;
  final String name;
  final bool animated;

  const PartialEmoji(this.id, this.name, this.animated);

  factory PartialEmoji.fromUnicode(String value) =>
      PartialEmoji(null, value, false);

  factory PartialEmoji.fromEmoji(Emoji emoji) =>
      PartialEmoji(emoji.id, emoji.name, emoji.animated);

  Map<String, dynamic> toJson() => {
    'id': id?.value,
    'name': name,
    'animated': animated,
  };
}
