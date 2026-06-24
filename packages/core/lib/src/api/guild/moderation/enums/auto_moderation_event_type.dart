import 'package:mineral/api.dart';

enum AutoModerationEventType implements EnhancedEnum<int> {
  messageSend(1),
  memberUpdate(2),
  unknown(-1);

  @override
  final int value;
  const AutoModerationEventType(this.value);
}
