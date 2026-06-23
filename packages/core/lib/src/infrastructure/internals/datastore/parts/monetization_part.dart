import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/api/common/monetization/entitlement.dart';
import 'package:mineral/src/api/common/monetization/entitlement_owner_type.dart';
import 'package:mineral/src/api/common/monetization/sku.dart';
import 'package:mineral/src/api/common/monetization/subscription.dart';
import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/base_part.dart';

final class MonetizationPart extends BasePart
    implements MonetizationPartContract {
  MonetizationPart(super.marshaller, super.dataStore);

  @override
  Future<List<Sku>> fetchSkus(Object applicationId) async {
    final appId = Snowflake.parse(applicationId);
    final req = Request.json(endpoint: '/applications/$appId/skus');
    final result =
        await dataStore.requestBucket.get<List<dynamic>>(req);

    return result
        .cast<Map<String, dynamic>>()
        .map(Sku.fromJson)
        .toList();
  }

  @override
  Future<List<Entitlement>> fetchEntitlements(
    Object applicationId, {
    Object? userId,
    List<Object>? skuIds,
    Object? guildId,
    bool? excludeEnded,
    int? limit,
    Object? before,
    Object? after,
  }) async {
    final appId = Snowflake.parse(applicationId);
    final queryParams = <String, String>{
      if (userId != null) 'user_id': userId.toString(),
      if (skuIds != null) 'sku_ids': skuIds.map((e) => e.toString()).join(','),
      if (guildId != null) 'guild_id': guildId.toString(),
      if (excludeEnded != null) 'exclude_ended': excludeEnded.toString(),
      if (limit != null) 'limit': limit.toString(),
      if (before != null) 'before': before.toString(),
      if (after != null) 'after': after.toString(),
    };

    final req = Request.json(
      endpoint: '/applications/$appId/entitlements',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final result =
        await dataStore.requestBucket.get<List<dynamic>>(req);

    return result
        .cast<Map<String, dynamic>>()
        .map(Entitlement.fromJson)
        .toList();
  }

  @override
  Future<Entitlement> createTestEntitlement(
    Object applicationId, {
    required Object skuId,
    required Object ownerId,
    required EntitlementOwnerType ownerType,
  }) async {
    final appId = Snowflake.parse(applicationId);
    final req = Request.json(
      endpoint: '/applications/$appId/entitlements',
      body: {
        'sku_id': skuId.toString(),
        'owner_id': ownerId.toString(),
        'owner_type': ownerType.value,
      },
    );
    final result =
        await dataStore.requestBucket.post<Map<String, dynamic>>(req);

    return Entitlement.fromJson(result);
  }

  @override
  Future<void> consumeEntitlement(
      Object applicationId, Object entitlementId) async {
    final appId = Snowflake.parse(applicationId);
    final req = Request.json(
        endpoint: '/applications/$appId/entitlements/$entitlementId/consume');
    await dataStore.requestBucket.post<void>(req);
  }

  @override
  Future<void> deleteTestEntitlement(
      Object applicationId, Object entitlementId) async {
    final appId = Snowflake.parse(applicationId);
    final req = Request.json(
        endpoint: '/applications/$appId/entitlements/$entitlementId');
    await dataStore.requestBucket.delete<void>(req);
  }

  @override
  Future<List<Subscription>> fetchSubscriptions(
    Object skuId, {
    Object? userId,
    int? limit,
    Object? before,
    Object? after,
  }) async {
    final queryParams = <String, String>{
      if (userId != null) 'user_id': userId.toString(),
      if (limit != null) 'limit': limit.toString(),
      if (before != null) 'before': before.toString(),
      if (after != null) 'after': after.toString(),
    };

    final req = Request.json(
      endpoint: '/skus/$skuId/subscriptions',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final result =
        await dataStore.requestBucket.get<List<dynamic>>(req);

    return result
        .cast<Map<String, dynamic>>()
        .map(Subscription.fromJson)
        .toList();
  }

  @override
  Future<Subscription> getSubscription(
      Object skuId, Object subscriptionId) async {
    final req = Request.json(
        endpoint: '/skus/$skuId/subscriptions/$subscriptionId');
    final result =
        await dataStore.requestBucket.get<Map<String, dynamic>>(req);

    return Subscription.fromJson(result);
  }
}
