import 'package:mineral/src/api/common/types/enhanced_enum.dart';

enum ExplicitContentFilter implements EnhancedEnum<int> {
  disabled(0),
  membersWithoutRoles(1),
  allMembers(2),
  unknown(-1);

  @override
  final int value;

  const ExplicitContentFilter(this.value);
}
