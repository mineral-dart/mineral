import 'package:mineral/api.dart';

enum KeywordPresetType implements EnhancedEnum<int> {
  profanity(1),
  sexualContent(2),
  slurs(3),
  unknown(-1);

  @override
  final int value;
  const KeywordPresetType(this.value);
}
