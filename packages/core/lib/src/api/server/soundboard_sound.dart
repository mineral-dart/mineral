import 'package:mineral/src/api/common/snowflake.dart';

/// Represents a Discord soundboard sound (either a default sound or a
/// guild-specific custom sound).
final class SoundboardSound {
  /// The name of the sound.
  final String name;

  /// The unique id of this sound.
  final Snowflake soundId;

  /// The volume of this sound, in the range [0, 1].
  final double volume;

  /// The id of the emoji associated with this sound, if any.
  final Snowflake? emojiId;

  /// The unicode character of the emoji associated with this sound, if any.
  final String? emojiName;

  /// The id of the guild this sound belongs to, or `null` for default sounds.
  final Snowflake? guildId;

  /// Whether this sound can currently be used.
  final bool available;

  /// The id of the user who created this sound, if present in the payload.
  final Snowflake? userId;

  const SoundboardSound({
    required this.name,
    required this.soundId,
    required this.volume,
    required this.available,
    this.emojiId,
    this.emojiName,
    this.guildId,
    this.userId,
  });

  factory SoundboardSound.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;

    return SoundboardSound(
      name: json['name'] as String,
      soundId: Snowflake.parse(json['sound_id']),
      volume: (json['volume'] as num).toDouble(),
      emojiId: Snowflake.nullable(json['emoji_id']),
      emojiName: json['emoji_name'] as String?,
      guildId: Snowflake.nullable(json['guild_id']),
      available: json['available'] as bool? ?? true,
      userId: user != null ? Snowflake.parse(user['id']) : null,
    );
  }
}
