import 'dart:math';

import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/api/common/bot/bot.dart';
import 'package:mineral/src/domains/container/ioc_container.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class ReadyPacketMessage<T> {
  ShardMessage<T> message;
  ReadyPacketMessage(this.message);
}

final class ReadyPacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.ready;

  bool isAlreadyUsed = false;

  MarshallerContract get _marshaller => ioc.resolve<MarshallerContract>();

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final bot = ioc.make<Bot>(() => Bot.fromJson(message.payload as Map<String, dynamic>));
    final interactionManager = ioc.resolve<CommandInteractionManagerContract>();

    if (!isAlreadyUsed) {
      await interactionManager.registerGlobal(bot);
      await _maybeClearCache();
      isAlreadyUsed = true;
    }

    dispatch<ReadyArgs>(event: Event.ready, payload: (bot: bot));
  }

  Future<void> _maybeClearCache() async {
    final config = ioc.resolveOrNull<CacheConfig>();
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
