import 'package:mineral/contracts.dart';
import 'package:mineral/src/api/common/monetization/entitlement.dart';
import 'package:mineral/src/api/common/monetization/entitlement_owner_type.dart';
import 'package:mineral/src/api/common/monetization/sku.dart';
import 'package:mineral/src/api/common/monetization/subscription.dart';
import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class MonetizationManager {
  final EntityContext _ctx;
  DataStoreContract get _datastore => _ctx.datastore;

  final Snowflake _applicationId;

  MonetizationManager(this._applicationId, {required EntityContext ctx})
      : _ctx = ctx;

  /// Fetch all SKUs for this application.
  /// ```dart
  /// final skus = await bot.monetization.fetchSkus();
  /// ```
  Future<List<Sku>> fetchSkus() =>
      _datastore.monetization.fetchSkus(_applicationId.value);

  /// Fetch entitlements for this application with optional filters.
  /// ```dart
  /// final entitlements = await bot.monetization.fetchEntitlements();
  /// ```
  Future<List<Entitlement>> fetchEntitlements({
    Object? userId,
    List<Object>? skuIds,
    Object? guildId,
    bool? excludeEnded,
    int? limit,
    Object? before,
    Object? after,
  }) =>
      _datastore.monetization.fetchEntitlements(
        _applicationId.value,
        userId: userId,
        skuIds: skuIds,
        guildId: guildId,
        excludeEnded: excludeEnded,
        limit: limit,
        before: before,
        after: after,
      );

  /// Create a test entitlement for testing purposes.
  /// ```dart
  /// final entitlement = await bot.monetization.createTestEntitlement(
  ///   skuId: '123', ownerId: '456', ownerType: EntitlementOwnerType.user);
  /// ```
  Future<Entitlement> createTestEntitlement({
    required Object skuId,
    required Object ownerId,
    required EntitlementOwnerType ownerType,
  }) =>
      _datastore.monetization.createTestEntitlement(
        _applicationId.value,
        skuId: skuId,
        ownerId: ownerId,
        ownerType: ownerType,
      );

  /// Consume an entitlement (marks a CONSUMABLE_PURCHASE as consumed).
  /// ```dart
  /// await bot.monetization.consumeEntitlement('entitlementId');
  /// ```
  Future<void> consumeEntitlement(Object entitlementId) =>
      _datastore.monetization
          .consumeEntitlement(_applicationId.value, entitlementId);

  /// Delete a test entitlement.
  /// ```dart
  /// await bot.monetization.deleteTestEntitlement('entitlementId');
  /// ```
  Future<void> deleteTestEntitlement(Object entitlementId) =>
      _datastore.monetization
          .deleteTestEntitlement(_applicationId.value, entitlementId);

  /// Fetch subscriptions for a SKU with optional filters.
  /// ```dart
  /// final subscriptions = await bot.monetization.fetchSubscriptions(skuId: '123');
  /// ```
  Future<List<Subscription>> fetchSubscriptions(
    Object skuId, {
    Object? userId,
    int? limit,
    Object? before,
    Object? after,
  }) =>
      _datastore.monetization.fetchSubscriptions(
        skuId,
        userId: userId,
        limit: limit,
        before: before,
        after: after,
      );

  /// Get a single subscription by SKU and subscription IDs.
  /// ```dart
  /// final subscription = await bot.monetization.getSubscription(skuId: '123', subscriptionId: '456');
  /// ```
  Future<Subscription> getSubscription(
          Object skuId, Object subscriptionId) =>
      _datastore.monetization.getSubscription(skuId, subscriptionId);
}
