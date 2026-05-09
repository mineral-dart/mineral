import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/container/ioc_container.dart';
import 'package:mineral/src/domains/services/cache/cache_invalidation.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class AutomoderationRuleDeletePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.autoModerationRuleDelete;

  MarshallerContract get _marshaller => ioc.resolve<MarshallerContract>();

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final payload = message.payload as Map<String, dynamic>;
    final rawRule = await _marshaller.serializers.rules.normalize(payload);
    final rule = await _marshaller.serializers.rules.serialize(rawRule);

    final ruleCacheKey = _marshaller.cacheKey
        .serverRules(payload['guild_id'] as Object, payload['id'] as Object);
    await _marshaller.cache.invalidate(ruleCacheKey);

    dispatch<ServerRuleDeleteArgs>(event: Event.serverRuleDelete, payload: (rule: rule));
  }
}
