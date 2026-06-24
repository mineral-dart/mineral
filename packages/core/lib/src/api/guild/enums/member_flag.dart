import 'package:mineral/src/api/common/types/enhanced_enum.dart';

enum MemberFlag implements EnhancedEnum<int> {
  didRejoin(1 << 0),
  completedOnboarding(1 << 1),
  bypassedVerification(1 << 2),
  startedOnboarding(1 << 3),
  unknown(-1);

  @override
  final int value;

  const MemberFlag(this.value);
}
