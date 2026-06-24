/// Tests for AUTO_MODERATION_RULE_CREATE, _UPDATE, _DELETE.
library;

import 'package:mineral/api.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/automoderation_rule_create_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/automoderation_rule_delete_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/automoderation_rule_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:test/test.dart';

import '../helpers/fake_cache_provider.dart';
import '../helpers/fake_marshaller.dart';
import '../helpers/fake_websocket_orchestrator.dart';
import '../helpers/mocks.dart';
import 'helpers/packet_test_helpers.dart';

// ── IDs ───────────────────────────────────────────────────────────────────────

const _guildId = '123456789012345678';
const _ruleId = '111222333444555666';
const _creatorId = '987654321098765432';

// ── Minimal auto-moderation rule payload ──────────────────────────────────────

Map<String, dynamic> _rulePayload({String name = 'test-rule'}) => {
  'id': _ruleId,
  'guild_id': _guildId,
  'name': name,
  'creator_id': _creatorId,
  'event_type': 1, // MESSAGE_SEND
  'trigger_type': 1, // KEYWORD
  'trigger_metadata': {
    'keyword_filter': ['badword'],
    'regex_patterns': <String>[],
    'presets': <int>[],
    'allow_list': <String>[],
    'mention_total_limit': null,
    'mention_raid_protection_enabled': false,
  },
  'actions': [
    {'type': 1}, // BLOCK_MESSAGE
  ],
  'enabled': true,
  'exempt_roles': <String>[],
  'exempt_channels': <String>[],
};

ShardMessage<dynamic> _msg(String type, Map<String, dynamic> payload) =>
    ShardMessage(
      type: type,
      opCode: OpCode.dispatch,
      sequence: 1,
      payload: payload,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeCacheProvider cache;
  late FakeMarshaller marshaller;

  setUp(() {
    final wss = FakeWebsocketOrchestrator();
    cache = FakeCacheProvider();

    marshaller = FakeMarshaller(
      cache: cache,
      entityContext: buildCtx(dataStore: MockDataStore(), wss: wss),
    );
  });

  // ── AUTO_MODERATION_RULE_CREATE ────────────────────────────────────────────

  group('AutomoderationRuleCreatePacket', () {
    test('packetType is PacketType.autoModerationRuleCreate', () {
      final packet = AutomoderationRuleCreatePacket(marshaller: marshaller);
      expect(packet.packetType, equals(PacketType.autoModerationRuleCreate));
      expect(packet.packetType.name, equals('AUTO_MODERATION_RULE_CREATE'));
    });

    test('dispatches Event.guildRuleCreate', () async {
      final packet = AutomoderationRuleCreatePacket(marshaller: marshaller);
      Event? capturedEvent;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        capturedEvent = event;
      }

      await packet.listen(
        _msg('AUTO_MODERATION_RULE_CREATE', _rulePayload()),
        dispatch,
      );

      expect(capturedEvent, equals(Event.guildRuleCreate));
    });

    test('payload is GuildRuleCreateArgs with correct rule', () async {
      final packet = AutomoderationRuleCreatePacket(marshaller: marshaller);
      GuildRuleCreateArgs? args;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        if (event == Event.guildRuleCreate) {
          args = payload as GuildRuleCreateArgs;
        }
      }

      await packet.listen(
        _msg('AUTO_MODERATION_RULE_CREATE', _rulePayload()),
        dispatch,
      );

      expect(args, isNotNull);
      expect(args!.rule.id, equals(Snowflake.parse(_ruleId)));
      expect(args!.rule.name, equals('test-rule'));
    });
  });

  // ── AUTO_MODERATION_RULE_UPDATE ────────────────────────────────────────────

  group('AutoModerationRuleUpdatePacket', () {
    test('packetType is PacketType.autoModerationRuleUpdate', () {
      final packet = AutoModerationRuleUpdatePacket(marshaller: marshaller);
      expect(packet.packetType, equals(PacketType.autoModerationRuleUpdate));
      expect(packet.packetType.name, equals('AUTO_MODERATION_RULE_UPDATE'));
    });

    test('dispatches Event.guildRuleUpdate', () async {
      final packet = AutoModerationRuleUpdatePacket(marshaller: marshaller);
      Event? capturedEvent;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        capturedEvent = event;
      }

      await packet.listen(
        _msg('AUTO_MODERATION_RULE_UPDATE', _rulePayload()),
        dispatch,
      );

      expect(capturedEvent, equals(Event.guildRuleUpdate));
    });

    test('before is null when rule not in cache', () async {
      final packet = AutoModerationRuleUpdatePacket(marshaller: marshaller);
      GuildRuleUpdateArgs? args;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        if (event == Event.guildRuleUpdate) {
          args = payload as GuildRuleUpdateArgs;
        }
      }

      await packet.listen(
        _msg('AUTO_MODERATION_RULE_UPDATE', _rulePayload()),
        dispatch,
      );

      expect(args, isNotNull);
      expect(args!.before, isNull);
      expect(args!.after.id, equals(Snowflake.parse(_ruleId)));
    });

    test('before is populated when rule is in cache', () async {
      // Pre-seed the old rule in cache.
      final ruleCacheKey = marshaller.cacheKey.guildRules(_guildId, _ruleId);
      final oldNormalized = await marshaller.serializers.rules.normalize(
        _rulePayload(name: 'old-rule'),
      );
      await cache.put(ruleCacheKey, oldNormalized);

      final packet = AutoModerationRuleUpdatePacket(marshaller: marshaller);
      GuildRuleUpdateArgs? args;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        if (event == Event.guildRuleUpdate) {
          args = payload as GuildRuleUpdateArgs;
        }
      }

      await packet.listen(
        _msg('AUTO_MODERATION_RULE_UPDATE', _rulePayload(name: 'new-rule')),
        dispatch,
      );

      expect(args, isNotNull);
      expect(args!.before, isNotNull);
      expect(args!.before!.name, equals('old-rule'));
      expect(args!.after.name, equals('new-rule'));
    });
  });

  // ── AUTO_MODERATION_RULE_DELETE ────────────────────────────────────────────

  group('AutomoderationRuleDeletePacket', () {
    test('packetType is PacketType.autoModerationRuleDelete', () {
      final packet = AutomoderationRuleDeletePacket(marshaller: marshaller);
      expect(packet.packetType, equals(PacketType.autoModerationRuleDelete));
      expect(packet.packetType.name, equals('AUTO_MODERATION_RULE_DELETE'));
    });

    test('dispatches Event.guildRuleDelete', () async {
      final packet = AutomoderationRuleDeletePacket(marshaller: marshaller);
      Event? capturedEvent;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        capturedEvent = event;
      }

      await packet.listen(
        _msg('AUTO_MODERATION_RULE_DELETE', _rulePayload()),
        dispatch,
      );

      expect(capturedEvent, equals(Event.guildRuleDelete));
    });

    test('payload is GuildRuleDeleteArgs with correct rule', () async {
      final packet = AutomoderationRuleDeletePacket(marshaller: marshaller);
      GuildRuleDeleteArgs? args;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        if (event == Event.guildRuleDelete) {
          args = payload as GuildRuleDeleteArgs;
        }
      }

      await packet.listen(
        _msg('AUTO_MODERATION_RULE_DELETE', _rulePayload()),
        dispatch,
      );

      expect(args, isNotNull);
      expect(args!.rule.id, equals(Snowflake.parse(_ruleId)));
    });
  });
}
