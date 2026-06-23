import 'package:mineral/src/api/common/types/enhanced_enum.dart';

enum VoiceChannelEffectAnimationType implements EnhancedEnum<int> {
  premium(0),
  basic(1);

  @override
  final int value;

  const VoiceChannelEffectAnimationType(this.value);
}
