import 'package:mineral/src/api/common/types/enhanced_enum.dart';

enum MessageReferenceType implements EnhancedEnum<int> {
  /// A standard reply message reference (type 0).
  default_(0),

  /// A forwarded message reference (type 1).
  forward(1);

  @override
  final int value;
  const MessageReferenceType(this.value);
}
