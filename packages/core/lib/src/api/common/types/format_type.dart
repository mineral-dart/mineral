import 'package:mineral/src/api/common/types/enhanced_enum.dart';

enum FormatType implements EnhancedEnum<int> {
  standard(1),
  guild(2),
  lottie(3),
  gif(4),
  unknown(0);

  @override
  final int value;
  const FormatType(this.value);
}
