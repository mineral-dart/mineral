import 'package:mineral/api.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/application_command_permissions_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../helpers/fake_websocket_orchestrator.dart';
import '../helpers/mocks.dart';
import 'helpers/packet_test_helpers.dart';

// ── Test IDs ──────────────────────────────────────────────────────────────────

const _guildId = '123456789012345678';
const _applicationId = '222333444555666777';
const _commandId = '111000111000111000';
const _roleId = '333444555666777888';
const _userId = '444555666777888999';
const _channelId = '555666777888999000';

// ── Shard message factory ─────────────────────────────────────────────────────

ShardMessage<dynamic> _buildShardMessage() => ShardMessage(
  type: 'APPLICATION_COMMAND_PERMISSIONS_UPDATE',
  opCode: OpCode.dispatch,
  sequence: 1,
  payload: {
    'id': _commandId,
    'application_id': _applicationId,
    'guild_id': _guildId,
    'permissions': [
      {'id': _roleId, 'type': 1, 'permission': true},
      {'id': _userId, 'type': 2, 'permission': false},
      {'id': _channelId, 'type': 3, 'permission': true},
    ],
  },
);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('ApplicationCommandPermissionsUpdatePacket', () {
    // ── packetType identity ─────────────────────────────────────────────────

    test('packetType is applicationCommandPermissionsUpdate', () {
      final packet = ApplicationCommandPermissionsUpdatePacket(
        dataStore: buildMockDs(),
      );
      expect(
        packet.packetType,
        equals(PacketType.applicationCommandPermissionsUpdate),
      );
      expect(
        packet.packetType.name,
        equals('APPLICATION_COMMAND_PERMISSIONS_UPDATE'),
      );
    });

    // ── dispatch ────────────────────────────────────────────────────────────

    group('dispatches guildApplicationCommandPermissionsUpdate', () {
      late ApplicationCommandPermissionsUpdatePacket packet;
      late Guild guild;

      setUp(() {
        final ds = MockDataStore();
        guild = buildMinimalGuild(
          _guildId,
          buildCtx(dataStore: ds, wss: FakeWebsocketOrchestrator()),
        );
        when(() => ds.guild).thenReturn(FakeGuildPart(guild));
        packet = ApplicationCommandPermissionsUpdatePacket(dataStore: ds);
      });

      test(
        'dispatches Event.guildApplicationCommandPermissionsUpdate',
        () async {
          Event? capturedEvent;

          void dispatch<T extends Object>({
            required Event event,
            required T payload,
            bool Function(String?)? constraint,
          }) {
            capturedEvent = event;
          }

          await packet.listen(_buildShardMessage(), dispatch);

          expect(
            capturedEvent,
            equals(Event.guildApplicationCommandPermissionsUpdate),
          );
        },
      );

      test('payload is GuildApplicationCommandPermissionsUpdateArgs', () async {
        Object? capturedPayload;

        void dispatch<T extends Object>({
          required Event event,
          required T payload,
          bool Function(String?)? constraint,
        }) {
          capturedPayload = payload;
        }

        await packet.listen(_buildShardMessage(), dispatch);

        expect(
          capturedPayload,
          isA<GuildApplicationCommandPermissionsUpdateArgs>(),
        );
      });

      test('payload carries the resolved guild', () async {
        GuildApplicationCommandPermissionsUpdateArgs? args;

        void dispatch<T extends Object>({
          required Event event,
          required T payload,
          bool Function(String?)? constraint,
        }) {
          if (event == Event.guildApplicationCommandPermissionsUpdate) {
            args = payload as GuildApplicationCommandPermissionsUpdateArgs;
          }
        }

        await packet.listen(_buildShardMessage(), dispatch);

        expect(args, isNotNull);
        expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
        expect(args!.guild.name, equals('Test Guild'));
      });

      test('GuildApplicationCommandPermissions has correct ids', () async {
        GuildApplicationCommandPermissionsUpdateArgs? args;

        void dispatch<T extends Object>({
          required Event event,
          required T payload,
          bool Function(String?)? constraint,
        }) {
          if (event == Event.guildApplicationCommandPermissionsUpdate) {
            args = payload as GuildApplicationCommandPermissionsUpdateArgs;
          }
        }

        await packet.listen(_buildShardMessage(), dispatch);

        expect(args, isNotNull);
        final perms = args!.permissions;
        expect(perms.id, equals(Snowflake.parse(_commandId)));
        expect(perms.applicationId, equals(Snowflake.parse(_applicationId)));
        expect(perms.guildId, equals(Snowflake.parse(_guildId)));
      });

      test('permissions list has correct entries with correct types', () async {
        GuildApplicationCommandPermissionsUpdateArgs? args;

        void dispatch<T extends Object>({
          required Event event,
          required T payload,
          bool Function(String?)? constraint,
        }) {
          if (event == Event.guildApplicationCommandPermissionsUpdate) {
            args = payload as GuildApplicationCommandPermissionsUpdateArgs;
          }
        }

        await packet.listen(_buildShardMessage(), dispatch);

        expect(args, isNotNull);
        final entries = args!.permissions.permissions;
        expect(entries, hasLength(3));

        // role entry
        expect(entries[0].id, equals(Snowflake.parse(_roleId)));
        expect(entries[0].type, equals(ApplicationCommandPermissionType.role));
        expect(entries[0].permission, isTrue);

        // user entry
        expect(entries[1].id, equals(Snowflake.parse(_userId)));
        expect(entries[1].type, equals(ApplicationCommandPermissionType.user));
        expect(entries[1].permission, isFalse);

        // channel entry
        expect(entries[2].id, equals(Snowflake.parse(_channelId)));
        expect(
          entries[2].type,
          equals(ApplicationCommandPermissionType.channel),
        );
        expect(entries[2].permission, isTrue);
      });
    });
  });
}
