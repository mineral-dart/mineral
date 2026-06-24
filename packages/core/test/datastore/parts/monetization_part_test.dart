import 'package:mineral/api.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/monetization_part.dart';
import 'package:test/test.dart';

import '../../helpers/fake_datastore.dart';
import '../../helpers/fake_http_client.dart';
import '../../helpers/fake_marshaller.dart';
import '../../helpers/fake_response.dart';
import '../../helpers/ioc_test_helper.dart';

// ── Payload factories ─────────────────────────────────────────────────────────

Map<String, dynamic> _skuPayload({
  String id = '111222333444555666',
  int type = 5,
  String applicationId = '999888777666555444',
  String name = 'Premium Plan',
  String slug = 'premium-plan',
  int flags = 4,
}) =>
    {
      'id': id,
      'type': type,
      'application_id': applicationId,
      'name': name,
      'slug': slug,
      'flags': flags,
    };

Map<String, dynamic> _entitlementPayload({
  String id = '222333444555666777',
  String skuId = '111222333444555666',
  String applicationId = '999888777666555444',
  int type = 8,
  bool deleted = false,
  String? userId,
  String? guildId,
}) =>
    {
      'id': id,
      'sku_id': skuId,
      'application_id': applicationId,
      'type': type,
      'deleted': deleted,
      'user_id': ?userId,
      'guild_id': ?guildId,
    };

Map<String, dynamic> _subscriptionPayload({
  String id = '333444555666777888',
  String userId = '444555666777888999',
  String skuId = '111222333444555666',
  String entitlementId = '222333444555666777',
  int status = 0,
}) =>
    {
      'id': id,
      'user_id': userId,
      'sku_ids': [skuId],
      'entitlement_ids': [entitlementId],
      'current_period_start': '2024-01-01T00:00:00.000Z',
      'current_period_end': '2024-02-01T00:00:00.000Z',
      'status': status,
    };

// ── Test constants ────────────────────────────────────────────────────────────

const _applicationId = '999888777666555444';
const _skuId = '111222333444555666';
const _entitlementId = '222333444555666777';
const _subscriptionId = '333444555666777888';

// ── Helper ────────────────────────────────────────────────────────────────────

(MonetizationPart, void Function() restore) _buildPart(FakeHttpClient client) {
  final ds = FakeDataStore(client);
  final ioc = createTestIoc(dataStore: ds);
  return (MonetizationPart(FakeMarshaller(), ds), ioc.restore);
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('MonetizationPart', () {
    // ── fetchSkus ──────────────────────────────────────────────────────────

    group('fetchSkus()', () {
      test('sends GET to /applications/:id/skus', () async {
        final client = FakeHttpClient([
          FakeResponse<List<dynamic>>(200, [_skuPayload()]),
        ]);
        final (part, restore) = _buildPart(client);

        await part.fetchSkus(_applicationId);
        restore();

        expect(client.calls, hasLength(1));
        expect(client.calls.single.method, equals('GET'));
        expect(client.calls.single.path,
            equals('/applications/$_applicationId/skus'));
      });

      test('returns a list of Sku entities', () async {
        final client = FakeHttpClient([
          FakeResponse<List<dynamic>>(200, [
            _skuPayload(id: '111222333444555666', name: 'Premium Plan'),
            _skuPayload(id: '666555444333222111', name: 'Basic Plan', type: 2),
          ]),
        ]);
        final (part, restore) = _buildPart(client);

        final result = await part.fetchSkus(_applicationId);
        restore();

        expect(result, hasLength(2));
        expect(result[0].name, equals('Premium Plan'));
        expect(result[0].type, equals(SkuType.subscription));
        expect(result[1].name, equals('Basic Plan'));
        expect(result[1].type, equals(SkuType.durable));
      });

      test('returns empty list when no SKUs', () async {
        final client = FakeHttpClient([
          FakeResponse<List<dynamic>>(200, <dynamic>[]),
        ]);
        final (part, restore) = _buildPart(client);

        final result = await part.fetchSkus(_applicationId);
        restore();

        expect(result, isEmpty);
      });
    });

    // ── fetchEntitlements ──────────────────────────────────────────────────

    group('fetchEntitlements()', () {
      test('sends GET to /applications/:id/entitlements', () async {
        final client = FakeHttpClient([
          FakeResponse<List<dynamic>>(200, [_entitlementPayload()]),
        ]);
        final (part, restore) = _buildPart(client);

        await part.fetchEntitlements(_applicationId);
        restore();

        expect(client.calls, hasLength(1));
        expect(client.calls.single.method, equals('GET'));
        expect(client.calls.single.path,
            equals('/applications/$_applicationId/entitlements'));
      });

      test('returns a list of Entitlement entities', () async {
        final client = FakeHttpClient([
          FakeResponse<List<dynamic>>(200, [
            _entitlementPayload(id: '222333444555666777'),
            _entitlementPayload(id: '333444555666777888'),
          ]),
        ]);
        final (part, restore) = _buildPart(client);

        final result = await part.fetchEntitlements(_applicationId);
        restore();

        expect(result, hasLength(2));
        expect(result[0].id, equals(Snowflake.parse('222333444555666777')));
        expect(result[1].id, equals(Snowflake.parse('333444555666777888')));
      });

      test('applies query filters when provided', () async {
        final client = FakeHttpClient([
          FakeResponse<List<dynamic>>(200, [_entitlementPayload()]),
        ]);
        final (part, restore) = _buildPart(client);

        await part.fetchEntitlements(
          _applicationId,
          userId: '444555666777888999',
          skuIds: ['111222333444555666'],
          guildId: '555666777888999000',
          excludeEnded: true,
          limit: 10,
          before: 'before-id',
          after: 'after-id',
        );
        restore();

        expect(client.requests, hasLength(1));
        final queryParams = client.requests.single.queryParameters;
        expect(queryParams['user_id'], equals('444555666777888999'));
        expect(queryParams['sku_ids'],
            equals('111222333444555666'));
        expect(queryParams['guild_id'],
            equals('555666777888999000'));
        expect(queryParams['exclude_ended'], equals('true'));
        expect(queryParams['limit'], equals('10'));
        expect(queryParams['before'], equals('before-id'));
        expect(queryParams['after'], equals('after-id'));
      });
    });

    // ── createTestEntitlement ─────────────────────────────────────────────

    group('createTestEntitlement()', () {
      test('sends POST to /applications/:id/entitlements', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _entitlementPayload()),
        ]);
        final (part, restore) = _buildPart(client);

        await part.createTestEntitlement(
          _applicationId,
          skuId: _skuId,
          ownerId: '444555666777888999',
          ownerType: EntitlementOwnerType.user,
        );
        restore();

        expect(client.calls, hasLength(1));
        expect(client.calls.single.method, equals('POST'));
        expect(client.calls.single.path,
            equals('/applications/$_applicationId/entitlements'));
      });

      test('sends correct body', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _entitlementPayload()),
        ]);
        final (part, restore) = _buildPart(client);

        await part.createTestEntitlement(
          _applicationId,
          skuId: _skuId,
          ownerId: '444555666777888999',
          ownerType: EntitlementOwnerType.guild,
        );
        restore();

        final body = client.requests.single.body as Map<String, dynamic>;
        expect(body['sku_id'], equals(_skuId));
        expect(body['owner_id'], equals('444555666777888999'));
        expect(body['owner_type'], equals(EntitlementOwnerType.guild.value));
      });

      test('returns parsed Entitlement', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200,
              _entitlementPayload(id: _entitlementId)),
        ]);
        final (part, restore) = _buildPart(client);

        final result = await part.createTestEntitlement(
          _applicationId,
          skuId: _skuId,
          ownerId: '444555666777888999',
          ownerType: EntitlementOwnerType.user,
        );
        restore();

        expect(result, isA<Entitlement>());
        expect(result.id, equals(Snowflake.parse(_entitlementId)));
      });
    });

    // ── consumeEntitlement ────────────────────────────────────────────────

    group('consumeEntitlement()', () {
      test('sends POST to /applications/:id/entitlements/:id/consume',
          () async {
        final client = FakeHttpClient([FakeResponse<void>(204, null)]);
        final (part, restore) = _buildPart(client);

        await part.consumeEntitlement(_applicationId, _entitlementId);
        restore();

        expect(client.calls, hasLength(1));
        expect(client.calls.single.method, equals('POST'));
        expect(
          client.calls.single.path,
          equals(
              '/applications/$_applicationId/entitlements/$_entitlementId/consume'),
        );
      });
    });

    // ── deleteTestEntitlement ─────────────────────────────────────────────

    group('deleteTestEntitlement()', () {
      test('sends DELETE to /applications/:id/entitlements/:id', () async {
        final client = FakeHttpClient([FakeResponse<void>(204, null)]);
        final (part, restore) = _buildPart(client);

        await part.deleteTestEntitlement(_applicationId, _entitlementId);
        restore();

        expect(client.calls, hasLength(1));
        expect(client.calls.single.method, equals('DELETE'));
        expect(
          client.calls.single.path,
          equals(
              '/applications/$_applicationId/entitlements/$_entitlementId'),
        );
      });
    });

    // ── fetchSubscriptions ────────────────────────────────────────────────

    group('fetchSubscriptions()', () {
      test('sends GET to /skus/:id/subscriptions', () async {
        final client = FakeHttpClient([
          FakeResponse<List<dynamic>>(200, [_subscriptionPayload()]),
        ]);
        final (part, restore) = _buildPart(client);

        await part.fetchSubscriptions(_skuId);
        restore();

        expect(client.calls, hasLength(1));
        expect(client.calls.single.method, equals('GET'));
        expect(client.calls.single.path,
            equals('/skus/$_skuId/subscriptions'));
      });

      test('returns a list of Subscription entities', () async {
        final client = FakeHttpClient([
          FakeResponse<List<dynamic>>(200, [_subscriptionPayload()]),
        ]);
        final (part, restore) = _buildPart(client);

        final result = await part.fetchSubscriptions(_skuId);
        restore();

        expect(result, hasLength(1));
        expect(result[0].status, equals(SubscriptionStatus.active));
        expect(result[0].skuIds,
            contains(Snowflake.parse(_skuId)));
      });

      test('applies query filters when provided', () async {
        final client = FakeHttpClient([
          FakeResponse<List<dynamic>>(200, [_subscriptionPayload()]),
        ]);
        final (part, restore) = _buildPart(client);

        await part.fetchSubscriptions(
          _skuId,
          userId: '444555666777888999',
          limit: 5,
          before: 'before-id',
          after: 'after-id',
        );
        restore();

        final queryParams = client.requests.single.queryParameters;
        expect(queryParams['user_id'], equals('444555666777888999'));
        expect(queryParams['limit'], equals('5'));
        expect(queryParams['before'], equals('before-id'));
        expect(queryParams['after'], equals('after-id'));
      });
    });

    // ── getSubscription ───────────────────────────────────────────────────

    group('getSubscription()', () {
      test('sends GET to /skus/:id/subscriptions/:subscriptionId', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _subscriptionPayload()),
        ]);
        final (part, restore) = _buildPart(client);

        await part.getSubscription(_skuId, _subscriptionId);
        restore();

        expect(client.calls, hasLength(1));
        expect(client.calls.single.method, equals('GET'));
        expect(
          client.calls.single.path,
          equals('/skus/$_skuId/subscriptions/$_subscriptionId'),
        );
      });

      test('returns a parsed Subscription', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200,
              _subscriptionPayload(id: _subscriptionId, status: 1)),
        ]);
        final (part, restore) = _buildPart(client);

        final result = await part.getSubscription(_skuId, _subscriptionId);
        restore();

        expect(result, isA<Subscription>());
        expect(result.id, equals(Snowflake.parse(_subscriptionId)));
        expect(result.status, equals(SubscriptionStatus.ending));
      });
    });
  });
}
