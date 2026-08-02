import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/api/common/bot/bot.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/common/runtime_state.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class ReadyPacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.ready;

  /// Memoizes the one-time READY initialization (cache clear + global
  /// command registration).
  ///
  /// One [ReadyPacket] instance is shared by every shard, and
  /// `PacketDispatcher.listen` runs handlers without serialization, so two
  /// shards' READY events can both reach [listen] before either finishes.
  /// A plain `bool` guard checked-then-set after an `await` is not enough:
  /// both callers can observe the flag unset before either sets it.
  ///
  /// Assigning with `??=` closes that window because it is synchronous: the
  /// async function underneath starts running immediately and only
  /// *suspends* — handing back its `Future` — at its first `await`. So by
  /// the time any code outside [listen] runs again, [_initializeOnce] is
  /// already non-null. A second, concurrent READY sees the in-flight
  /// `Future` and awaits *that* — joining the first call's work — rather
  /// than skipping it or re-running it, so `dispatch<ReadyArgs>` for the
  /// second shard doesn't fire until initialization has actually finished.
  Future<void>? _initializeOnce;

  final MarshallerContract _marshaller;
  final CommandInteractionManagerContract _commandManager;
  final WebsocketOrchestratorContract _wss;
  final RuntimeState _runtimeState;
  final CacheConfig? _cacheConfig;
  final EntityContext _entityContext;

  ReadyPacket({
    required MarshallerContract marshaller,
    required CommandInteractionManagerContract commandManager,
    required WebsocketOrchestratorContract wss,
    required RuntimeState runtimeState,
    required EntityContext entityContext,
    CacheConfig? cacheConfig,
  }) : _marshaller = marshaller,
       _commandManager = commandManager,
       _wss = wss,
       _runtimeState = runtimeState,
       _entityContext = entityContext,
       _cacheConfig = cacheConfig;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    // Bot is created at runtime from the gateway's READY payload and stored
    // in the shared [RuntimeState] for downstream consumers (GuildCreatePacket,
    // Interaction).
    final bot = _runtimeState.bot ??= Bot.fromJson(
      message.payload as Map<String, dynamic>,
      wss: _wss,
      entityContext: _entityContext,
    );

    await (_initializeOnce ??= _runOnce(bot));

    dispatch<ReadyArgs>(event: Event.ready, payload: (bot: bot));
  }

  Future<void> _runOnce(Bot bot) async {
    // Clear the cache before doing anything else — in particular, before
    // the `registerGlobal` REST round-trip below. Discord streams
    // GUILD_CREATE immediately after READY, and since the dispatcher does
    // not serialize handlers, a GUILD_CREATE for this shard can be
    // processed concurrently with anything this method awaits. Any await
    // ahead of the clear (jitter, a REST call) is a window in which
    // GUILD_CREATE can hydrate the cache before the clear wipes it back
    // out. Running the clear first, with nothing awaited ahead of it,
    // closes that window.
    await _maybeClearCache();
    await _commandManager.registerGlobal(bot);
  }

  Future<void> _maybeClearCache() async {
    final config = _cacheConfig;
    if (config == null || !config.clearOnReady) {
      return;
    }

    final cache = _marshaller.cache;
    if (cache == null) {
      return;
    }

    // No jitter here (the old `staggerClearMs`-based delay is gone): any
    // delay before `clear()` only widens the race window described above.
    // The jitter existed to avoid every shard clearing independently on
    // reconnect; that no longer applies since [_initializeOnce] already
    // guarantees a single clear for this client's whole lifetime.
    await cache.clear();
  }
}
