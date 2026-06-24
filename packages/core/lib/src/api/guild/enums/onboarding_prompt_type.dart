import 'package:mineral/src/api/common/types/enhanced_enum.dart';

enum OnboardingPromptType implements EnhancedEnum<int> {
  multipleChoice(0),
  dropdown(1);

  @override
  final int value;

  const OnboardingPromptType(this.value);
}
