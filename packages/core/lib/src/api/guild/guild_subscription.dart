import 'package:mineral/src/api/common/premium_tier.dart';

final class GuildSubscription {
  final PremiumTier tier;
  final int? subscriptionCount;
  final bool hasEnabledProgressBar;

  GuildSubscription({
    required this.tier,
    required this.subscriptionCount,
    required this.hasEnabledProgressBar,
  });
}
