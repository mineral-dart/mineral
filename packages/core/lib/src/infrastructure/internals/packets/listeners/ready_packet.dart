import 'dart:math';

import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/api/common/bot/bot.dart';
import 'package:mineral/src/domains/common/runtime_state.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class ReadyPacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.ready;

  bool isAlreadyUsed = false;

  final MarshallerContract _marshaller;
  final CommandInteractionManagerContract _commandManager;
  final WebsocketOrchestratorContract _wss;
  final RuntimeState _runtimeState;
  final CacheConfig? _cacheConfig;

  ReadyPacket({
    required MarshallerContract marshaller,
    required CommandInteractionManagerContract commandManager,
    required WebsocketOrchestratorContract wss,
    required RuntimeState runtimeState,
    CacheConfig? cacheConfig,
  })  : _marshaller = marshaller,
        _commandManager = commandManager,
        _wss = wss,
        _runtimeState = runtimeState,
        _cacheConfig = cacheConfig;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    // Bot is created at runtime from the gateway's READY payload and stored
    // in the shared [RuntimeState] for downstream consumers (GuildCreatePacket,
    // Interaction).
    final bot = _runtimeState.bot ??=
        Bot.fromJson(message.payload as Map<String, dynamic>, wss: _wss);

    if (!isAlreadyUsed) {
      await _commandManager.registerGlobal(bot);
      await _maybeClearCache();
      isAlreadyUsed = true;
    }

    dispatch<ReadyArgs>(event: Event.ready, payload: (bot: bot));
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

    if (config.staggerClearMs > 0) {
      final jitter = Random().nextInt(config.staggerClearMs);
      await Future.delayed(Duration(milliseconds: jitter));
    }

    await cache.clear();
  }
}
