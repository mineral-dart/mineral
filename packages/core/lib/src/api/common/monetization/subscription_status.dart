import 'package:mineral/src/api/common/types/enhanced_enum.dart';

enum SubscriptionStatus implements EnhancedEnum<int> {
  active(0),
  ending(1),
  inactive(2);

  @override
  final int value;

  const SubscriptionStatus(this.value);

  static SubscriptionStatus from(int value) =>
      SubscriptionStatus.values.firstWhere(
        (e) => e.value == value,
        orElse: () =>
            throw ArgumentError('Unknown SubscriptionStatus value: $value'),
      );
}
