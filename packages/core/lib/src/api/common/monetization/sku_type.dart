import 'package:mineral/src/api/common/types/enhanced_enum.dart';

enum SkuType implements EnhancedEnum<int> {
  durable(2),
  consumable(3),
  subscription(5),
  subscriptionGroup(6);

  @override
  final int value;

  const SkuType(this.value);

  static SkuType from(int value) => SkuType.values.firstWhere(
        (e) => e.value == value,
        orElse: () => throw ArgumentError('Unknown SkuType value: $value'),
      );
}
