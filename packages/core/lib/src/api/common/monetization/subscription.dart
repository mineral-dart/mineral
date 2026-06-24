import 'package:mineral/src/api/common/monetization/subscription_status.dart';
import 'package:mineral/src/api/common/snowflake.dart';

final class Subscription {
  final Snowflake id;
  final Snowflake userId;
  final List<Snowflake> skuIds;
  final List<Snowflake> entitlementIds;
  final List<Snowflake>? renewalSkuIds;
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;
  final SubscriptionStatus status;
  final DateTime? canceledAt;
  final String? country;

  const Subscription({
    required this.id,
    required this.userId,
    required this.skuIds,
    required this.entitlementIds,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    required this.status,
    this.renewalSkuIds,
    this.canceledAt,
    this.country,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    final canceledAtRaw = json['canceled_at'] as String?;

    final rawRenewalSkuIds = json['renewal_sku_ids'] as List<dynamic>?;

    return Subscription(
      id: Snowflake.parse(json['id']),
      userId: Snowflake.parse(json['user_id']),
      skuIds: (json['sku_ids'] as List<dynamic>).map(Snowflake.parse).toList(),
      entitlementIds: (json['entitlement_ids'] as List<dynamic>)
          .map(Snowflake.parse)
          .toList(),
      renewalSkuIds: rawRenewalSkuIds?.map(Snowflake.parse).toList(),
      currentPeriodStart: DateTime.parse(
        json['current_period_start'] as String,
      ),
      currentPeriodEnd: DateTime.parse(json['current_period_end'] as String),
      status: SubscriptionStatus.from(json['status'] as int),
      canceledAt: canceledAtRaw != null ? DateTime.parse(canceledAtRaw) : null,
      country: json['country'] as String?,
    );
  }
}
