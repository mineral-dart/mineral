import 'package:mineral/src/api/common/types/enhanced_enum.dart';

enum SystemChannelFlag implements EnhancedEnum<int> {
  suppressJoinNotifications(1 << 0),
  suppressPremiumSubscriptions(1 << 1),
  suppressGuildReminderNotifications(1 << 2),
  suppressJoinNotificationReplies(1 << 3),
  suppressRoleSubscriptionPurchaseNotifications(1 << 4),
  suppressRoleSubscriptionPurchaseNotificationReplies(1 << 5),
  unknown(-1);

  @override
  final int value;

  const SystemChannelFlag(this.value);
}
