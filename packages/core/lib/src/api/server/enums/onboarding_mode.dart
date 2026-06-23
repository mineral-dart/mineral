import 'package:mineral/src/api/common/types/enhanced_enum.dart';

enum OnboardingMode implements EnhancedEnum<int> {
  default_(0),
  advanced(1);

  @override
  final int value;

  const OnboardingMode(this.value);
}
