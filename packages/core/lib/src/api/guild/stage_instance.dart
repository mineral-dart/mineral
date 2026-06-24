import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/api/guild/enums/stage_privacy_level.dart';

/// Represents a live stage instance associated with a stage channel.
final class StageInstance {
  /// The id of this stage instance.
  final Snowflake id;

  /// The guild id of the associated stage channel's guild.
  final Snowflake guildId;

  /// The id of the associated stage channel.
  final Snowflake channelId;

  /// The topic of the stage instance (1–120 characters).
  final String topic;

  /// The privacy level of the stage instance.
  final StagePrivacyLevel privacyLevel;

  /// The id of the scheduled event for this stage instance, if any.
  final Snowflake? guildScheduledEventId;

  const StageInstance({
    required this.id,
    required this.guildId,
    required this.channelId,
    required this.topic,
    required this.privacyLevel,
    this.guildScheduledEventId,
  });

  factory StageInstance.fromJson(Map<String, dynamic> json) {
    final rawPrivacyLevel = json['privacy_level'] as int;
    final privacyLevel = StagePrivacyLevel.values.firstWhere(
      (e) => e.value == rawPrivacyLevel,
      orElse: () => StagePrivacyLevel.guildOnly,
    );

    return StageInstance(
      id: Snowflake.parse(json['id']),
      guildId: Snowflake.parse(json['guild_id']),
      channelId: Snowflake.parse(json['channel_id']),
      topic: json['topic'] as String,
      privacyLevel: privacyLevel,
      guildScheduledEventId: Snowflake.nullable(json['guild_scheduled_event_id']),
    );
  }
}
