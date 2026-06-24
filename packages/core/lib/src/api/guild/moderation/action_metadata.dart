import 'package:mineral/api.dart';

final class ActionMetadata {
  final Snowflake channelId;
  final int duration;
  final String? customMessage;

  ActionMetadata({
    required this.channelId,
    required this.duration,
    this.customMessage,
  });

  factory ActionMetadata.fromJson(Map<String, dynamic> json) {
    return ActionMetadata(
      channelId: Snowflake.parse(json['channel_id']),
      duration: json['duration_seconds'] as int,
      customMessage: json['custom_message'] as String?,
    );
  }
}
