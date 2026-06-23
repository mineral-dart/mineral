import 'package:mineral/src/api/common/snowflake.dart';

/// A single channel shown on a guild's welcome screen.
final class WelcomeChannel {
  /// The channel's id.
  final Snowflake channelId;

  /// The description shown for the channel on the welcome screen.
  final String description;

  /// The emoji id, if the emoji is custom.
  final Snowflake? emojiId;

  /// The emoji name if custom, the unicode character if standard, or null.
  final String? emojiName;

  const WelcomeChannel({
    required this.channelId,
    required this.description,
    this.emojiId,
    this.emojiName,
  });

  factory WelcomeChannel.fromJson(Map<String, dynamic> json) {
    return WelcomeChannel(
      channelId: Snowflake.parse(json['channel_id']),
      description: json['description'] as String,
      emojiId: Snowflake.nullable(json['emoji_id']),
      emojiName: json['emoji_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'channel_id': channelId.value,
      'description': description,
      if (emojiId != null) 'emoji_id': emojiId!.value,
      if (emojiName != null) 'emoji_name': emojiName,
    };
  }
}

/// A guild's welcome screen shown to new members.
final class WelcomeScreen {
  /// The server description shown in the welcome screen.
  final String? description;

  /// The channels shown in the welcome screen (up to 5).
  final List<WelcomeChannel> welcomeChannels;

  const WelcomeScreen({
    required this.description,
    required this.welcomeChannels,
  });

  factory WelcomeScreen.fromJson(Map<String, dynamic> json) {
    final rawChannels =
        (json['welcome_channels'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
    return WelcomeScreen(
      description: json['description'] as String?,
      welcomeChannels:
          rawChannels.map(WelcomeChannel.fromJson).toList(),
    );
  }
}
