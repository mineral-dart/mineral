import 'package:mineral/src/api/common/types/enhanced_enum.dart';

enum CommandKind implements EnhancedEnum<int> {
  chatInput(1),
  user(2),
  message(3),
  primaryEntryPoint(4),
  unknown(-1);

  @override
  final int value;

  const CommandKind(this.value);

  factory CommandKind.of(int value) => values.firstWhere(
        (e) => e.value == value,
        orElse: () => CommandKind.unknown,
      );
}
