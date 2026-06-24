import 'package:mineral/api.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/entitlement_create_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/entitlement_delete_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/entitlement_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/subscription_create_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/subscription_delete_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/subscription_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:test/test.dart';

// ── Payload factories ─────────────────────────────────────────────────────────

Map<String, dynamic> _entitlementPayload({
  String id = '222333444555666777',
  String skuId = '111222333444555666',
  String applicationId = '999888777666555444',
  int type = 8,
  bool deleted = false,
}) => {
  'id': id,
  'sku_id': skuId,
  'application_id': applicationId,
  'type': type,
  'deleted': deleted,
};

Map<String, dynamic> _subscriptionPayload({
  String id = '333444555666777888',
  String userId = '444555666777888999',
  String skuId = '111222333444555666',
  String entitlementId = '222333444555666777',
  int status = 0,
}) => {
  'id': id,
  'user_id': userId,
  'sku_ids': [skuId],
  'entitlement_ids': [entitlementId],
  'current_period_start': '2024-01-01T00:00:00.000Z',
  'current_period_end': '2024-02-01T00:00:00.000Z',
  'status': status,
};

// ── Shard message builders ────────────────────────────────────────────────────

ShardMessage<dynamic> _entitlementMessage(
  String type,
  Map<String, dynamic> payload,
) => ShardMessage(
  type: type,
  opCode: OpCode.dispatch,
  sequence: 1,
  payload: payload,
);

ShardMessage<dynamic> _subscriptionMessage(
  String type,
  Map<String, dynamic> payload,
) => ShardMessage(
  type: type,
  opCode: OpCode.dispatch,
  sequence: 1,
  payload: payload,
);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── PacketType identity ──────────────────────────────────────────────────

  group('PacketType identity', () {
    test('EntitlementCreatePacket has correct packetType', () {
      final packet = EntitlementCreatePacket();
      expect(packet.packetType, equals(PacketType.entitlementCreate));
      expect(packet.packetType.name, equals('ENTITLEMENT_CREATE'));
    });

    test('EntitlementUpdatePacket has correct packetType', () {
      final packet = EntitlementUpdatePacket();
      expect(packet.packetType, equals(PacketType.entitlementUpdate));
      expect(packet.packetType.name, equals('ENTITLEMENT_UPDATE'));
    });

    test('EntitlementDeletePacket has correct packetType', () {
      final packet = EntitlementDeletePacket();
      expect(packet.packetType, equals(PacketType.entitlementDelete));
      expect(packet.packetType.name, equals('ENTITLEMENT_DELETE'));
    });

    test('SubscriptionCreatePacket has correct packetType', () {
      final packet = SubscriptionCreatePacket();
      expect(packet.packetType, equals(PacketType.subscriptionCreate));
      expect(packet.packetType.name, equals('SUBSCRIPTION_CREATE'));
    });

    test('SubscriptionUpdatePacket has correct packetType', () {
      final packet = SubscriptionUpdatePacket();
      expect(packet.packetType, equals(PacketType.subscriptionUpdate));
      expect(packet.packetType.name, equals('SUBSCRIPTION_UPDATE'));
    });

    test('SubscriptionDeletePacket has correct packetType', () {
      final packet = SubscriptionDeletePacket();
      expect(packet.packetType, equals(PacketType.subscriptionDelete));
      expect(packet.packetType.name, equals('SUBSCRIPTION_DELETE'));
    });
  });

  // ── ENTITLEMENT_CREATE ───────────────────────────────────────────────────

  group('EntitlementCreatePacket', () {
    test('dispatches Event.entitlementCreate', () async {
      final packet = EntitlementCreatePacket();
      Event? capturedEvent;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        capturedEvent = event;
      }

      await packet.listen(
        _entitlementMessage('ENTITLEMENT_CREATE', _entitlementPayload()),
        dispatch,
      );

      expect(capturedEvent, equals(Event.entitlementCreate));
    });

    test('payload carries correctly parsed Entitlement', () async {
      final packet = EntitlementCreatePacket();
      EntitlementCreateArgs? args;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        if (event == Event.entitlementCreate) {
          args = payload as EntitlementCreateArgs;
        }
      }

      await packet.listen(
        _entitlementMessage(
          'ENTITLEMENT_CREATE',
          _entitlementPayload(id: '222333444555666777'),
        ),
        dispatch,
      );

      expect(args, isNotNull);
      expect(args!.entitlement, isA<Entitlement>());
      expect(
        args!.entitlement.id,
        equals(Snowflake.parse('222333444555666777')),
      );
      expect(
        args!.entitlement.type,
        equals(EntitlementType.applicationSubscription),
      );
      expect(args!.entitlement.deleted, isFalse);
    });
  });

  // ── ENTITLEMENT_UPDATE ───────────────────────────────────────────────────

  group('EntitlementUpdatePacket', () {
    test('dispatches Event.entitlementUpdate', () async {
      final packet = EntitlementUpdatePacket();
      Event? capturedEvent;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        capturedEvent = event;
      }

      await packet.listen(
        _entitlementMessage('ENTITLEMENT_UPDATE', _entitlementPayload()),
        dispatch,
      );

      expect(capturedEvent, equals(Event.entitlementUpdate));
    });

    test('payload carries correctly parsed Entitlement', () async {
      final packet = EntitlementUpdatePacket();
      EntitlementUpdateArgs? args;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        if (event == Event.entitlementUpdate) {
          args = payload as EntitlementUpdateArgs;
        }
      }

      await packet.listen(
        _entitlementMessage(
          'ENTITLEMENT_UPDATE',
          _entitlementPayload(deleted: true),
        ),
        dispatch,
      );

      expect(args, isNotNull);
      expect(args!.entitlement.deleted, isTrue);
    });
  });

  // ── ENTITLEMENT_DELETE ───────────────────────────────────────────────────

  group('EntitlementDeletePacket', () {
    test('dispatches Event.entitlementDelete', () async {
      final packet = EntitlementDeletePacket();
      Event? capturedEvent;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        capturedEvent = event;
      }

      await packet.listen(
        _entitlementMessage('ENTITLEMENT_DELETE', _entitlementPayload()),
        dispatch,
      );

      expect(capturedEvent, equals(Event.entitlementDelete));
    });

    test('payload carries correctly parsed Entitlement', () async {
      final packet = EntitlementDeletePacket();
      EntitlementDeleteArgs? args;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        if (event == Event.entitlementDelete) {
          args = payload as EntitlementDeleteArgs;
        }
      }

      await packet.listen(
        _entitlementMessage(
          'ENTITLEMENT_DELETE',
          _entitlementPayload(id: '999888777666555444'),
        ),
        dispatch,
      );

      expect(args, isNotNull);
      expect(
        args!.entitlement.id,
        equals(Snowflake.parse('999888777666555444')),
      );
    });
  });

  // ── SUBSCRIPTION_CREATE ──────────────────────────────────────────────────

  group('SubscriptionCreatePacket', () {
    test('dispatches Event.subscriptionCreate', () async {
      final packet = SubscriptionCreatePacket();
      Event? capturedEvent;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        capturedEvent = event;
      }

      await packet.listen(
        _subscriptionMessage('SUBSCRIPTION_CREATE', _subscriptionPayload()),
        dispatch,
      );

      expect(capturedEvent, equals(Event.subscriptionCreate));
    });

    test('payload carries correctly parsed Subscription', () async {
      final packet = SubscriptionCreatePacket();
      SubscriptionCreateArgs? args;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        if (event == Event.subscriptionCreate) {
          args = payload as SubscriptionCreateArgs;
        }
      }

      await packet.listen(
        _subscriptionMessage(
          'SUBSCRIPTION_CREATE',
          _subscriptionPayload(id: '333444555666777888', status: 0),
        ),
        dispatch,
      );

      expect(args, isNotNull);
      expect(args!.subscription, isA<Subscription>());
      expect(
        args!.subscription.id,
        equals(Snowflake.parse('333444555666777888')),
      );
      expect(args!.subscription.status, equals(SubscriptionStatus.active));
    });
  });

  // ── SUBSCRIPTION_UPDATE ──────────────────────────────────────────────────

  group('SubscriptionUpdatePacket', () {
    test('dispatches Event.subscriptionUpdate', () async {
      final packet = SubscriptionUpdatePacket();
      Event? capturedEvent;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        capturedEvent = event;
      }

      await packet.listen(
        _subscriptionMessage('SUBSCRIPTION_UPDATE', _subscriptionPayload()),
        dispatch,
      );

      expect(capturedEvent, equals(Event.subscriptionUpdate));
    });

    test(
      'payload carries correctly parsed Subscription with ending status',
      () async {
        final packet = SubscriptionUpdatePacket();
        SubscriptionUpdateArgs? args;

        void dispatch<T extends Object>({
          required Event event,
          required T payload,
          bool Function(String?)? constraint,
        }) {
          if (event == Event.subscriptionUpdate) {
            args = payload as SubscriptionUpdateArgs;
          }
        }

        await packet.listen(
          _subscriptionMessage(
            'SUBSCRIPTION_UPDATE',
            _subscriptionPayload(status: 1),
          ),
          dispatch,
        );

        expect(args, isNotNull);
        expect(args!.subscription.status, equals(SubscriptionStatus.ending));
      },
    );
  });

  // ── SUBSCRIPTION_DELETE ──────────────────────────────────────────────────

  group('SubscriptionDeletePacket', () {
    test('dispatches Event.subscriptionDelete', () async {
      final packet = SubscriptionDeletePacket();
      Event? capturedEvent;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        capturedEvent = event;
      }

      await packet.listen(
        _subscriptionMessage('SUBSCRIPTION_DELETE', _subscriptionPayload()),
        dispatch,
      );

      expect(capturedEvent, equals(Event.subscriptionDelete));
    });

    test(
      'payload carries correctly parsed Subscription with inactive status',
      () async {
        final packet = SubscriptionDeletePacket();
        SubscriptionDeleteArgs? args;

        void dispatch<T extends Object>({
          required Event event,
          required T payload,
          bool Function(String?)? constraint,
        }) {
          if (event == Event.subscriptionDelete) {
            args = payload as SubscriptionDeleteArgs;
          }
        }

        await packet.listen(
          _subscriptionMessage(
            'SUBSCRIPTION_DELETE',
            _subscriptionPayload(status: 2),
          ),
          dispatch,
        );

        expect(args, isNotNull);
        expect(args!.subscription.status, equals(SubscriptionStatus.inactive));
      },
    );
  });
}
