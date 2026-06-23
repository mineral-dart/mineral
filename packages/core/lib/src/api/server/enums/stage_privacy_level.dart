import 'package:mineral/src/api/common/types/enhanced_enum.dart';

enum StagePrivacyLevel implements EnhancedEnum<int> {
  public(1),
  guildOnly(2);

  @override
  final int value;

  const StagePrivacyLevel(this.value);
}
