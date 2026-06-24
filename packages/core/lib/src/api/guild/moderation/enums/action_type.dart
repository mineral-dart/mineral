import 'package:mineral/api.dart';

enum ActionType implements EnhancedEnum<int> {
  blockMessage(1),
  sendAlertMessage(2),
  timeout(3),
  blockMemberInteraction(4),
  unknown(-1);

  @override
  final int value;
  const ActionType(this.value);
}
