import 'package:mineral/src/api/common/types/enhanced_enum.dart';

enum EntitlementOwnerType implements EnhancedEnum<int> {
  guild(1),
  user(2);

  @override
  final int value;

  const EntitlementOwnerType(this.value);

  static EntitlementOwnerType from(int value) =>
      EntitlementOwnerType.values.firstWhere(
        (e) => e.value == value,
        orElse: () =>
            throw ArgumentError('Unknown EntitlementOwnerType value: $value'),
      );
}
