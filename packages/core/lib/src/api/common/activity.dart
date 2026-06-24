import 'package:mineral/src/api/common/activity_emoji.dart';
import 'package:mineral/src/api/common/types/activity_type.dart';
import 'package:mineral/src/domains/common/utils/helper.dart';

final class Activity {
  final String name;
  final ActivityType type;
  final String? url;
  final DateTime createdAt;
  final String? details;
  final String? state;
  final ActivityEmoji? emoji;

  Activity({
    required this.name,
    required this.type,
    required this.url,
    required this.createdAt,
    required this.details,
    required this.state,
    required this.emoji,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      name: json['name'] as String,
      type: ActivityType.values.firstWhere(
        (element) => element.value == json['type'],
        orElse: () => ActivityType.unknown,
      ),
      url: json['url'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
      details: json['details'] as String?,
      state: json['state'] as String?,
      emoji: Helper.createOrNull(
        field: json['emoji'],
        fn: () => ActivityEmoji(
          name: json['name'] as String,
          id: json['id'] as String?,
          animated: json['animated'] as bool? ?? false,
        ),
      ),
    );
  }
}
