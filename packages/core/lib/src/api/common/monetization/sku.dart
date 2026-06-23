import 'package:mineral/src/api/common/monetization/sku_type.dart';
import 'package:mineral/src/api/common/snowflake.dart';

final class Sku {
  final Snowflake id;
  final SkuType type;
  final Snowflake applicationId;
  final String name;
  final String slug;
  final int flags;

  const Sku({
    required this.id,
    required this.type,
    required this.applicationId,
    required this.name,
    required this.slug,
    required this.flags,
  });

  factory Sku.fromJson(Map<String, dynamic> json) {
    return Sku(
      id: Snowflake.parse(json['id']),
      type: SkuType.from(json['type'] as int),
      applicationId: Snowflake.parse(json['application_id']),
      name: json['name'] as String,
      slug: json['slug'] as String,
      flags: json['flags'] as int,
    );
  }
}
