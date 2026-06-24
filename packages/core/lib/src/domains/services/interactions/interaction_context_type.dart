import 'package:mineral/src/api/common/types/enhanced_enum.dart';

enum InteractionContextType implements EnhancedEnum<int> {
  guild(0),
  botPrivate(1),
  privateChannel(2),
  unknown(-1);

  @override
  final int value;

  const InteractionContextType(this.value);
}
