import 'package:mineral/src/api/common/types/enhanced_enum.dart';

enum ApplicationCommandPermissionType implements EnhancedEnum<int> {
  role(1),
  user(2),
  channel(3);

  @override
  final int value;

  const ApplicationCommandPermissionType(this.value);
}
