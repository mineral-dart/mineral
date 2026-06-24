import 'package:mineral/events.dart';
import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/api/common/typing.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class TypingPacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.typingStart;

  final EntityContext _ctx;

  TypingPacket({required EntityContext ctx}) : _ctx = ctx;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final payload = message.payload;

    final typing = Typing(
      ctx: _ctx,
      guildId: Snowflake.nullable(payload['guild_id']),
      channelId: Snowflake.parse(payload['channel_id']),
      userId: Snowflake.parse(payload['user_id']),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        payload['timestamp'] as int,
      ),
    );

    dispatch<TypingArgs>(event: Event.typing, payload: (typing: typing));
  }
}
