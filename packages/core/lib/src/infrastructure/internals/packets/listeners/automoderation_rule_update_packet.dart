import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/common/utils/helper.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class AutoModerationRuleUpdatePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.autoModerationRuleUpdate;

  final MarshallerContract _marshaller;

  AutoModerationRuleUpdatePacket({required MarshallerContract marshaller})
      : _marshaller = marshaller;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final ruleId = Snowflake.parse(message.payload['id']);
    final ruleCacheKey = _marshaller.cacheKey
        .guildRules(message.payload['guild_id'] as Object, ruleId.value);
    final rawBeforeRule = await _marshaller.cache?.get(ruleCacheKey);
    final before = await Helper.createOrNullAsync<AutoModerationRule>(
        field: rawBeforeRule,
        fn: () async =>
            await _marshaller.serializers.rules.serialize(rawBeforeRule!));

    final rawAfterRule =
        await _marshaller.serializers.rules.normalize(message.payload as Map<String, dynamic>);
    final after = await _marshaller.serializers.rules.serialize(rawAfterRule);

    dispatch<GuildRuleUpdateArgs>(event: Event.guildRuleUpdate, payload: (before: before, after: after));
  }
}
