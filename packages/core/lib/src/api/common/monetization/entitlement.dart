import 'package:mineral/src/api/common/monetization/entitlement_type.dart';
import 'package:mineral/src/api/common/snowflake.dart';

final class Entitlement {
  final Snowflake id;
  final Snowflake skuId;
  final Snowflake applicationId;
  final Snowflake? userId;
  final EntitlementType type;
  final bool deleted;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final Snowflake? guildId;
  final bool? consumed;
  final Snowflake? subscriptionId;

  const Entitlement({
    required this.id,
    required this.skuId,
    required this.applicationId,
    required this.type,
    required this.deleted,
    this.userId,
    this.startsAt,
    this.endsAt,
    this.guildId,
    this.consumed,
    this.subscriptionId,
  });

  factory Entitlement.fromJson(Map<String, dynamic> json) {
    final startsAtRaw = json['starts_at'] as String?;
    final endsAtRaw = json['ends_at'] as String?;

    return Entitlement(
      id: Snowflake.parse(json['id']),
      skuId: Snowflake.parse(json['sku_id']),
      applicationId: Snowflake.parse(json['application_id']),
      userId: Snowflake.nullable(json['user_id']),
      type: EntitlementType.from(json['type'] as int),
      deleted: json['deleted'] as bool? ?? false,
      startsAt: startsAtRaw != null ? DateTime.parse(startsAtRaw) : null,
      endsAt: endsAtRaw != null ? DateTime.parse(endsAtRaw) : null,
      guildId: Snowflake.nullable(json['guild_id']),
      consumed: json['consumed'] as bool?,
      subscriptionId: Snowflake.nullable(json['subscription_id']),
    );
  }
}
