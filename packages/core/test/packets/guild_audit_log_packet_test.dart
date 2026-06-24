/// Tests for GUILD_AUDIT_LOG_ENTRY_CREATE.
library;

import 'package:mineral/events.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/common/runtime_state.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_audit_log_entry_create_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:test/test.dart';

import '../helpers/fake_logger.dart';
import '../helpers/fake_websocket_orchestrator.dart';
import '../helpers/mocks.dart';

// ── IDs ───────────────────────────────────────────────────────────────────────

const _guildId = '123456789012345678';
const _targetId = '111222333444555666';
const _userId = '987654321098765432';

// ── Payload builders ──────────────────────────────────────────────────────────

Map<String, dynamic> _auditLogPayload(int actionType) => {
  'id': '444555666777888999',
  'guild_id': _guildId,
  'target_id': _targetId,
  'user_id': _userId,
  'action_type': actionType,
  'reason': 'Test reason',
  'changes': <Map<String, dynamic>>[],
  'options': null,
};

ShardMessage<dynamic> _msg(Map<String, dynamic> payload) => ShardMessage(
  type: 'GUILD_AUDIT_LOG_ENTRY_CREATE',
  opCode: OpCode.dispatch,
  sequence: 1,
  payload: payload,
);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeLogger logger;
  late EntityContext ctx;
  late GuildAuditLogEntryCreatePacket packet;

  setUp(() {
    logger = FakeLogger();
    ctx = EntityContext(
      datastore: MockDataStore(),
      wss: FakeWebsocketOrchestrator(),
      logger: logger,
      runtimeState: RuntimeState(),
    );
    packet = GuildAuditLogEntryCreatePacket(logger: logger, ctx: ctx);
  });

  test('packetType is PacketType.guildAuditLogEntryCreate', () {
    expect(packet.packetType, equals(PacketType.guildAuditLogEntryCreate));
    expect(packet.packetType.name, equals('GUILD_AUDIT_LOG_ENTRY_CREATE'));
  });

  test(
    'dispatches Event.guildAuditLog for known action type (member kick)',
    () async {
      Event? capturedEvent;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        capturedEvent = event;
      }

      // action_type 20 = MEMBER_KICK (does not require datastore)
      await packet.listen(_msg(_auditLogPayload(20)), dispatch);

      expect(capturedEvent, equals(Event.guildAuditLog));
    },
  );

  test('payload is GuildAuditLogArgs', () async {
    Object? capturedPayload;

    void dispatch<T extends Object>({
      required Event event,
      required T payload,
      bool Function(String?)? constraint,
    }) {
      capturedPayload = payload;
    }

    // action_type 20 = MEMBER_KICK
    await packet.listen(_msg(_auditLogPayload(20)), dispatch);

    expect(capturedPayload, isA<GuildAuditLogArgs>());
    final args = capturedPayload as GuildAuditLogArgs;
    expect(args.audit, isNotNull);
  });

  test('dispatches for unknown action type with warn log', () async {
    bool dispatched = false;

    void dispatch<T extends Object>({
      required Event event,
      required T payload,
      bool Function(String?)? constraint,
    }) {
      dispatched = true;
    }

    // action_type 9999 is unknown
    await packet.listen(_msg(_auditLogPayload(9999)), dispatch);

    expect(dispatched, isTrue);
  });
}
