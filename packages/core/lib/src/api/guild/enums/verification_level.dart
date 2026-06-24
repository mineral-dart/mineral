import 'package:mineral/src/api/common/types/enhanced_enum.dart';

enum VerificationLevel implements EnhancedEnum<int> {
  none(0),
  low(1),
  medium(2),
  high(3),
  veryHigh(4),
  unknown(-1);

  @override
  final int value;

  const VerificationLevel(this.value);
}
