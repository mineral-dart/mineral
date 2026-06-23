import 'package:mineral/src/api/common/types/enhanced_enum.dart';

enum IntegrationExpireBehavior implements EnhancedEnum<int> {
  removeRole(0),
  kick(1);

  @override
  final int value;

  const IntegrationExpireBehavior(this.value);
}
