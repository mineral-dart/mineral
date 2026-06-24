import 'package:mineral/src/api/common/types/enhanced_enum.dart';

enum EntitlementType implements EnhancedEnum<int> {
  applicationSubscription(8);

  @override
  final int value;

  const EntitlementType(this.value);

  static EntitlementType from(int value) => EntitlementType.values.firstWhere(
    (e) => e.value == value,
    orElse: () => throw ArgumentError('Unknown EntitlementType value: $value'),
  );
}
