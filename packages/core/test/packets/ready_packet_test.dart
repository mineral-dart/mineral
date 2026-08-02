import 'dart:async';

import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/commands/command_builder.dart' as cb;
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/common/runtime_state.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/ready_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:test/test.dart';

import '../helpers/fake_cache_provider.dart';
import '../helpers/fake_logger.dart';
import '../helpers/fake_marshaller.dart';
import '../helpers/fake_websocket_orchestrator.dart';
import '../helpers/mocks.dart';

// ── No-op CommandInteractionManager stub ──────────────────────────────────────

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

// ── Minimal READY payload ──────────────────────────────────────────────────────

Map<String, dynamic> _readyPayload() => {
  'v': 10,
  'user': {
    'id': '123456789012345678',
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
};

ShardMessage<dynamic> _buildMessage() => ShardMessage(
  type: 'READY',
  opCode: OpCode.dispatch,
  sequence: 1,
  payload: _readyPayload(),
);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('ReadyPacket', () {
    late FakeWebsocketOrchestrator wss;
    late FakeLogger logger;
    late FakeMarshaller marshaller;
    late RuntimeState runtimeState;
    late EntityContext ctx;
    late _NoopCommandManager commandManager;
    late ReadyPacket packet;

    setUp(() {
      wss = FakeWebsocketOrchestrator();
      logger = FakeLogger();
      runtimeState = RuntimeState();
      marshaller = FakeMarshaller(logger: logger);

      ctx = EntityContext(
        datastore: MockDataStore(),
        wss: wss,
        logger: logger,
        runtimeState: runtimeState,
      );

      commandManager = _NoopCommandManager();

      packet = ReadyPacket(
        marshaller: marshaller,
        commandManager: commandManager,
        wss: wss,
        runtimeState: runtimeState,
        entityContext: ctx,
      );
    });

    test('packetType is PacketType.ready', () {
      expect(packet.packetType, equals(PacketType.ready));
      expect(packet.packetType.name, equals('READY'));
    });

    test('dispatches Event.ready', () async {
      Event? capturedEvent;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        capturedEvent = event;
      }

      await packet.listen(_buildMessage(), dispatch);

      expect(capturedEvent, equals(Event.ready));
    });

    test('payload is ReadyArgs with a Bot', () async {
      Object? capturedPayload;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        capturedPayload = payload;
      }

      await packet.listen(_buildMessage(), dispatch);

      expect(capturedPayload, isA<ReadyArgs>());
      final args = capturedPayload as ReadyArgs;
      expect(args.bot, isA<Bot>());
    });

    test('Bot is stored in runtimeState after READY', () async {
      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {}

      await packet.listen(_buildMessage(), dispatch);

      expect(runtimeState.bot, isNotNull);
    });

    test(
      'cache is cleared on second READY when clearOnReady is true',
      () async {
        final cache = FakeCacheProvider()
          ..config = CacheConfig(clearOnReady: true, staggerClearMs: 0);
        final marshallerWithCache = FakeMarshaller(cache: cache);

        await cache.put('some-key', {'data': 'value'});
        expect(cache.store.containsKey('some-key'), isTrue);

        final packetWithCache = ReadyPacket(
          marshaller: marshallerWithCache,
          commandManager: commandManager,
          wss: wss,
          runtimeState: runtimeState,
          entityContext: ctx,
          cacheConfig: cache.config,
        );

        await packetWithCache.listen(
          _buildMessage(),
          <T extends Object>({
            required Event event,
            required T payload,
            bool Function(String?)? constraint,
          }) {},
        );

        // Cache is cleared on first (and only) isAlreadyUsed = false call
        expect(cache.store.containsKey('some-key'), isFalse);
      },
    );

    test(
      'registerGlobal is called only once even if listen is called twice',
      () async {
        int callCount = 0;
        final trackingManager = _CountingCommandManager(
          onRegisterGlobal: () {
            callCount++;
          },
        );

        final p = ReadyPacket(
          marshaller: marshaller,
          commandManager: trackingManager,
          wss: wss,
          runtimeState: runtimeState,
          entityContext: ctx,
        );

        void dispatch<T extends Object>({
          required Event event,
          required T payload,
          bool Function(String?)? constraint,
        }) {}

        await p.listen(_buildMessage(), dispatch);
        await p.listen(_buildMessage(), dispatch);

        expect(callCount, equals(1));
      },
    );

    // ── Regression tests for #468 ───────────────────────────────────────────
    //
    // One ReadyPacket instance is shared by every shard, and the packet
    // dispatcher runs handlers without serialization, so two READY
    // dispatches can genuinely interleave at await points. Both tests below
    // drive two `listen()` calls concurrently — the first is deliberately
    // never awaited before the second starts — landing the second call
    // inside a window controlled by a `Completer` on the fake command
    // manager's `registerGlobal`. A test that awaits the first call
    // sequentially before starting the second would never exercise this
    // window at all.

    test(
      'Interleaving A: two concurrent READY dispatches (simulating two '
      'shards sharing this ReadyPacket) call registerGlobal exactly once',
      () async {
        final gate = Completer<void>();
        final entered = Completer<void>();
        final blockingManager = _BlockingCommandManager(
          gate: gate.future,
          onEnter: () {
            if (!entered.isCompleted) {
              entered.complete();
            }
          },
        );

        final p = ReadyPacket(
          marshaller: marshaller,
          commandManager: blockingManager,
          wss: wss,
          runtimeState: runtimeState,
          entityContext: ctx,
        );

        void dispatch<T extends Object>({
          required Event event,
          required T payload,
          bool Function(String?)? constraint,
        }) {}

        // Shard 0's READY: not awaited, so its execution can be suspended
        // mid-flight while the test keeps driving.
        final f1 = p.listen(_buildMessage(), dispatch);

        // Block until shard 0 has actually entered registerGlobal and is
        // now suspended on `gate`. Under the old `if (!isAlreadyUsed)`
        // guard, this is precisely the window where a second READY would
        // still observe `isAlreadyUsed == false`.
        await entered.future;

        // Shard 1's READY arrives while shard 0 is still in flight.
        final f2 = p.listen(_buildMessage(), dispatch);

        gate.complete();
        await Future.wait([f1, f2]);

        expect(blockingManager.registerGlobalCallCount, equals(1));
      },
    );

    test(
      'Interleaving B: a cache write landing while READY is still in '
      'flight (single shard) survives the clear',
      () async {
        final cache = FakeCacheProvider()
          ..config = CacheConfig(clearOnReady: true, staggerClearMs: 0);
        await cache.put('stale', {'from': 'previous session'});

        final gate = Completer<void>();
        final entered = Completer<void>();
        final blockingManager = _BlockingCommandManager(
          gate: gate.future,
          onEnter: () {
            if (!entered.isCompleted) {
              entered.complete();
            }
          },
        );

        final marshallerWithCache = FakeMarshaller(cache: cache);
        final p = ReadyPacket(
          marshaller: marshallerWithCache,
          commandManager: blockingManager,
          wss: wss,
          runtimeState: runtimeState,
          entityContext: ctx,
          cacheConfig: cache.config,
        );

        void dispatch<T extends Object>({
          required Event event,
          required T payload,
          bool Function(String?)? constraint,
        }) {}

        final f1 = p.listen(_buildMessage(), dispatch);

        // Block until READY's handling has reached (and is now blocked
        // inside) the registerGlobal REST call -- the earliest point at
        // which a concurrently-dispatched GUILD_CREATE could plausibly
        // start writing to the cache, since the dispatcher does not
        // serialize handlers.
        await entered.future;

        // Simulate GUILD_CREATE hydrating the cache while READY is still
        // in flight.
        await cache.put('guild:1', {'hydrated': true});

        gate.complete();
        await f1;

        expect(
          cache.store.containsKey('guild:1'),
          isTrue,
          reason:
              'a cache write landing during the READY window must survive; '
              'the clear must not run after it',
        );
      },
    );
  });
}

// ── Helpers ───────────────────────────────────────────────────────────────────

final class _CountingCommandManager
    implements CommandInteractionManagerContract {
  final void Function() onRegisterGlobal;

  _CountingCommandManager({required this.onRegisterGlobal});

  @override
  final List<CommandRegistration> commandsHandler = [];
  @override
  final List<cb.CommandBuilder> commands = [];
  @override
  late InteractionDispatcherContract dispatcher;
  @override
  void Function(CommandFailure failure)? onCommandError;

  @override
  Future<void> registerGlobal(Bot bot) async {
    onRegisterGlobal();
  }

  @override
  Future<void> registerServer(Bot bot, Guild guild) async {}

  @override
  void addCommand(dynamic command) {}

  @override
  Future<void> handleAutocomplete(Map<String, dynamic> payload) async {}
}

/// A [CommandInteractionManagerContract] whose `registerGlobal` suspends on
/// a caller-supplied `gate` future, so a test can deterministically land a
/// second, concurrent `ReadyPacket.listen` call while the first is still
/// in flight inside `registerGlobal`.
///
/// `onEnter` fires synchronously, before the suspension, as soon as
/// `registerGlobal` is entered -- awaiting the future it completes tells a
/// test "the call is now blocked on `gate`" without any sleeps or arbitrary
/// microtask pumping.
final class _BlockingCommandManager
    implements CommandInteractionManagerContract {
  _BlockingCommandManager({required this.gate, this.onEnter});

  final Future<void> gate;
  final void Function()? onEnter;

  int registerGlobalCallCount = 0;

  @override
  final List<CommandRegistration> commandsHandler = [];
  @override
  final List<cb.CommandBuilder> commands = [];
  @override
  late InteractionDispatcherContract dispatcher;
  @override
  void Function(CommandFailure failure)? onCommandError;

  @override
  Future<void> registerGlobal(Bot bot) async {
    registerGlobalCallCount++;
    onEnter?.call();
    await gate;
  }

  @override
  Future<void> registerServer(Bot bot, Guild guild) async {}

  @override
  void addCommand(dynamic command) {}

  @override
  Future<void> handleAutocomplete(Map<String, dynamic> payload) async {}
}
