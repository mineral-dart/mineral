import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/commands/command_builder.dart' as cb;
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/common/runtime_state.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_create_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:test/test.dart';

import '../helpers/fake_cache_provider.dart';
import '../helpers/fake_logger.dart';
import '../helpers/fake_marshaller.dart';
import '../helpers/fake_websocket_orchestrator.dart';
import '../helpers/mocks.dart';

// ── IDs ───────────────────────────────────────────────────────────────────────

const _guildId = '123456789012345678';
const _botId = '987654321098765432';

// ── No-op stubs ───────────────────────────────────────────────────────────────

final class _NoopCommandManager implements CommandInteractionManagerContract {
  @override
  final List<CommandRegistration> commandsHandler = [];
  @override
  final List<cb.CommandBuilder> commands = [];
  @override
  late InteractionDispatcherContract dispatcher;
  @override
  void Function(CommandFailure failure)? onCommandError;

  @override
  Future<void> registerGlobal(Bot bot) async {}

  @override
  Future<void> registerServer(Bot bot, Guild guild) async {}

  @override
  void addCommand(dynamic command) {}

  @override
  Future<void> handleAutocomplete(Map<String, dynamic> payload) async {}
}

// ── Minimal GUILD_CREATE payload ──────────────────────────────────────────────

Map<String, dynamic> _guildPayload() => {
      'id': _guildId,
      'name': 'Test Guild',
      'owner_id': _botId,
      'description': null,
      'application_id': null,
      'icon': null,
      'icon_hash': null,
      'splash': null,
      'discovery_splash': null,
      'banner': null,
      'afk_channel_id': null,
      'afk_timeout': 300,
      'widget_enabled': false,
      'verification_level': 0,
      'default_message_notifications': 0,
      'explicit_content_filter': 0,
      'features': <String>[],
      'mfa_level': 0,
      'system_channel_id': null,
      'system_channel_flags': 0,
      'rules_channel_id': null,
      'public_updates_channel_id': null,
      'safety_alerts_channel_id': null,
      'vanity_url_code': null,
      'premium_tier': 0,
      'premium_subscription_count': null,
      'premium_progress_bar_enabled': false,
      'preferred_locale': 'en-US',
      'max_video_channel_users': null,
      'nsfw_level': 0,
      'channels': <Map<String, dynamic>>[],
      'members': <Map<String, dynamic>>[],
      'roles': <Map<String, dynamic>>[],
      'stickers': <Map<String, dynamic>>[],
      'voice_states': <Map<String, dynamic>>[],
      'threads': <Map<String, dynamic>>[],
      'presences': <Map<String, dynamic>>[],
      'emojis': <Map<String, dynamic>>[],
    };

ShardMessage<dynamic> _buildMessage() => ShardMessage(
      type: 'GUILD_CREATE',
      opCode: OpCode.dispatch,
      sequence: 1,
      payload: _guildPayload(),
    );

Bot _buildBot(FakeWebsocketOrchestrator wss, EntityContext ctx) =>
    Bot.fromJson({
      'v': 10,
      'user': {
        'id': _botId,
        'username': 'TestBot',
        'discriminator': '0000',
        'avatar': null,
        'bot': true,
        'mfa_enabled': false,
        'flags': 0,
        'public_flags': 0,
      },
      'guilds': <Map<String, dynamic>>[],
      'session_id': 'fake-session-id',
      'session_type': 'normal',
      'resume_gateway_url': 'wss://gateway.discord.gg',
      'private_channels': <dynamic>[],
      'presences': <dynamic>[],
      'application': {'id': '999888777666555444', 'flags': 0},
    }, wss: wss, entityContext: ctx);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('GuildCreatePacket', () {
    late FakeWebsocketOrchestrator wss;
    late FakeLogger logger;
    late FakeCacheProvider cache;
    late FakeMarshaller marshaller;
    late RuntimeState runtimeState;
    late EntityContext ctx;
    late _NoopCommandManager commandManager;

    setUp(() {
      wss = FakeWebsocketOrchestrator();
      logger = FakeLogger();
      cache = FakeCacheProvider();
      runtimeState = RuntimeState();

      ctx = EntityContext(
        datastore: MockDataStore(),
        wss: wss,
        logger: logger,
        runtimeState: runtimeState,
      );

      marshaller = FakeMarshaller(
        logger: logger,
        cache: cache,
        entityContext: ctx,
      );

      // Pre-populate bot in runtimeState (as ReadyPacket would do)
      runtimeState.bot = _buildBot(wss, ctx);
      commandManager = _NoopCommandManager();
    });

    test('packetType is PacketType.guildCreate', () {
      final packet = GuildCreatePacket(
        marshaller: marshaller,
        commandManager: commandManager,
        runtimeState: runtimeState,
      );
      expect(packet.packetType, equals(PacketType.guildCreate));
      expect(packet.packetType.name, equals('GUILD_CREATE'));
    });

    test('dispatches Event.guildCreate', () async {
      final packet = GuildCreatePacket(
        marshaller: marshaller,
        commandManager: commandManager,
        runtimeState: runtimeState,
      );

      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_buildMessage(), dispatch);

      expect(capturedEvent, equals(Event.guildCreate));
    });

    test('payload is GuildCreateArgs with correct guild', () async {
      final packet = GuildCreatePacket(
        marshaller: marshaller,
        commandManager: commandManager,
        runtimeState: runtimeState,
      );

      GuildCreateArgs? capturedArgs;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildCreate) {
          capturedArgs = payload as GuildCreateArgs;
        }
      }

      await packet.listen(_buildMessage(), dispatch);

      expect(capturedArgs, isNotNull);
      expect(capturedArgs!.guild.id, equals(Snowflake.parse(_guildId)));
      expect(capturedArgs!.guild.name, equals('Test Guild'));
    });

    test('guild is cached after dispatch', () async {
      final packet = GuildCreatePacket(
        marshaller: marshaller,
        commandManager: commandManager,
        runtimeState: runtimeState,
      );

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {}

      await packet.listen(_buildMessage(), dispatch);

      final guildCacheKey = marshaller.cacheKey.guild(_guildId);
      final cached = await cache.get(guildCacheKey);
      expect(cached, isNotNull);
      expect(cached!['name'], equals('Test Guild'));
    });

    test('throws StateError when bot is not set in runtimeState', () async {
      final emptyState = RuntimeState(); // no bot set
      final packet = GuildCreatePacket(
        marshaller: marshaller,
        commandManager: commandManager,
        runtimeState: emptyState,
      );

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {}

      expect(
        () => packet.listen(_buildMessage(), dispatch),
        throwsStateError,
      );
    });
  });
}

// ── Helpers ───────────────────────────────────────────────────────────────────

