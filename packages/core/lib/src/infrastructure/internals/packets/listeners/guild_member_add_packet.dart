import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class GuildMemberAddPacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.guildMemberAdd;

  final MarshallerContract _marshaller;
  final DataStoreContract _dataStore;

  GuildMemberAddPacket({
    required MarshallerContract marshaller,
    required DataStoreContract dataStore,
  }) : _marshaller = marshaller,
       _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final guild = await _dataStore.guild.get(
      message.payload['guild_id'] as Object,
      false,
    );

    final rawMember = await _marshaller.serializers.member.normalize({
      'guild_id': guild.id,
      ...(message.payload as Map<String, dynamic>),
    });

    final member = await _marshaller.serializers.member.serialize(rawMember);

    dispatch<GuildMemberAddArgs>(
      event: Event.guildMemberAdd,
      payload: (member: member, guild: guild),
    );
  }
}
