import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';

import 'package:mineral/src/api/server/moderation/action_metadata.dart';
import 'package:mineral/src/api/server/moderation/enums/action_type.dart';
import 'package:mineral/src/api/server/moderation/enums/trigger_type.dart';
import 'package:mineral/src/domains/common/utils/helper.dart';
import 'package:mineral/src/domains/common/utils/utils.dart';
import 'package:mineral/src/domains/events/event.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class AutomoderationActionExecutionPacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.autoModerationActionExecution;

  final DataStoreContract _dataStore;

  AutomoderationActionExecutionPacket({required DataStoreContract dataStore})
      : _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final payload = message.payload as Map<String, dynamic>;
    final server =
        await _dataStore.server.get(payload['guild_id'] as String, false);
    final member = await _dataStore.member.get(
        payload['guild_id'] as String, payload['user_id'] as String, false);

    final triggerType = findInEnum(
        TriggerType.values, payload['rule_trigger_type'],
        orElse: TriggerType.unknown);

    final action = Action(
        type: findInEnum(ActionType.values,
            (payload['action'] as Map<String, dynamic>)['type'],
            orElse: ActionType.unknown),
        metadata: Helper.createOrNull(
            field: payload['metadata'],
            fn: () => ActionMetadata.fromJson(
                payload['metadata'] as Map<String, dynamic>)));

    final ruleExecution = RuleExecution(
      ruleId: Snowflake.parse(payload['rule_id']),
      channelId: Snowflake.parse(payload['channel_id']),
      messageId: Snowflake.nullable(payload['message_id']),
      server: server,
      member: member!,
      action: action,
      triggerType: triggerType,
      content: payload['content'] as String,
      matchedContent: payload['matched_content'] as String?,
      matchedKeyword: payload['matched_keyword'] as String?,
    );

    dispatch<ServerRuleExecutionArgs>(
        event: Event.serverRuleExecution, payload: (execution: ruleExecution));
  }
}
