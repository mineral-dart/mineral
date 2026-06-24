import 'package:mineral/api.dart';

enum TriggerType implements EnhancedEnum<int> {
  keyword(1),
  spam(3),
  keywordPreset(4),
  mentionSpam(5),
  memberProfile(6),
  unknown(-1);

  @override
  final int value;
  const TriggerType(this.value);
}
