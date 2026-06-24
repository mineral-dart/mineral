import 'package:mineral/api.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/api/guild/managers/threads_manager.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/webhooks_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../helpers/fake_websocket_orchestrator.dart';
import '../helpers/mocks.dart';
import 'helpers/packet_test_helpers.dart';

// ── Test IDs ──────────────────────────────────────────────────────────────────

const _channelId = '111222333444555666';
const _guildId = '123456789012345678';

// ── Domain object builders ────────────────────────────────────────────────────

GuildTextChannel _buildServerTextChannel(EntityContext ctx) =>
    GuildTextChannel(
      ChannelProperties(
        ctx: ctx,
        id: Snowflake.parse(_channelId),
        type: ChannelType.guildText,
        name: 'general',
        description: null,
        guildId: Snowflake.parse(_guildId),
        categoryId: null,
        position: null,
        nsfw: false,
        lastMessageId: null,
        bitrate: null,
        userLimit: null,
        rateLimitPerUser: null,
        recipients: [],
        icon: null,
        ownerId: null,
        applicationId: null,
        lastPinTimestamp: null,
        rtcRegion: null,
        videoQualityMode: null,
        messageCount: null,
        memberCount: null,
        defaultAutoArchiveDuration: null,
        permissions: [],
        flags: null,
        totalMessageSent: null,
        available: null,
        appliedTags: [],
        defaultReactions: null,
        defaultSortOrder: null,
        defaultForumLayout: null,
        threads: ThreadsManager(
          Snowflake.parse(_guildId),
          Snowflake.parse(_channelId),
          ctx: ctx,
        ),
      ),
    );

// ── Shard message factory ─────────────────────────────────────────────────────

ShardMessage<dynamic> _buildShardMessage() => ShardMessage(
      type: 'WEBHOOKS_UPDATE',
      opCode: OpCode.dispatch,
      sequence: 1,
      payload: {
        'guild_id': _guildId,
        'channel_id': _channelId,
      },
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('WebhooksUpdatePacket', () {
    // ── packetType identity ─────────────────────────────────────────────────

    test('packetType is PacketType.webhooksUpdate', () {
      final packet = WebhooksUpdatePacket(dataStore: buildMockDs());
      expect(packet.packetType, equals(PacketType.webhooksUpdate));
      expect(packet.packetType.name, equals('WEBHOOKS_UPDATE'));
    });

    // ── guild branch ───────────────────────────────────────────────────────

    group('dispatches guildWebhooksUpdate with resolved guild and channel',
        () {
      late WebhooksUpdatePacket packet;
      late Guild guild;
      late GuildTextChannel channel;

      setUp(() {
        final ds = MockDataStore();
        final ctx = buildCtx(dataStore: ds, wss: FakeWebsocketOrchestrator());

        channel = _buildServerTextChannel(ctx);
        guild = buildMinimalGuild(_guildId, ctx);

        when(() => ds.channel).thenReturn(FakeChannelPart(channel));
        when(() => ds.guild).thenReturn(FakeGuildPart(guild));

        packet = WebhooksUpdatePacket(dataStore: ds);
      });

      test('dispatches Event.guildWebhooksUpdate', () async {
        Event? capturedEvent;

        void dispatch<T extends Object>(
            {required Event event,
            required T payload,
            bool Function(String?)? constraint}) {
          capturedEvent = event;
        }

        await packet.listen(_buildShardMessage(), dispatch);

        expect(capturedEvent, equals(Event.guildWebhooksUpdate));
      });

      test('payload is GuildWebhooksUpdateArgs', () async {
        Object? capturedPayload;

        void dispatch<T extends Object>(
            {required Event event,
            required T payload,
            bool Function(String?)? constraint}) {
          capturedPayload = payload;
        }

        await packet.listen(_buildShardMessage(), dispatch);

        expect(capturedPayload, isA<GuildWebhooksUpdateArgs>());
      });

      test('payload carries the resolved guild', () async {
        GuildWebhooksUpdateArgs? args;

        void dispatch<T extends Object>(
            {required Event event,
            required T payload,
            bool Function(String?)? constraint}) {
          if (event == Event.guildWebhooksUpdate) {
            args = payload as GuildWebhooksUpdateArgs;
          }
        }

        await packet.listen(_buildShardMessage(), dispatch);

        expect(args, isNotNull);
        expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
        expect(args!.guild.name, equals('Test Guild'));
      });

      test('payload carries the resolved channel', () async {
        GuildWebhooksUpdateArgs? args;

        void dispatch<T extends Object>(
            {required Event event,
            required T payload,
            bool Function(String?)? constraint}) {
          if (event == Event.guildWebhooksUpdate) {
            args = payload as GuildWebhooksUpdateArgs;
          }
        }

        await packet.listen(_buildShardMessage(), dispatch);

        expect(args, isNotNull);
        expect(args!.channel, isNotNull);
        expect(args!.channel!.id, equals(Snowflake.parse(_channelId)));
      });
    });
  });
}
