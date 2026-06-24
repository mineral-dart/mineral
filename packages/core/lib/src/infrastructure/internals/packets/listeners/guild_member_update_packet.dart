import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class GuildMemberUpdatePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.guildMemberUpdate;

  final MarshallerContract _marshaller;
  final DataStoreContract _dataStore;

  GuildMemberUpdatePacket({
    required MarshallerContract marshaller,
    required DataStoreContract dataStore,
  })  : _marshaller = marshaller,
        _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final payload = message.payload as Map<String, dynamic>;
    final guildId = payload['guild_id'] as String;
    final guild = await _dataStore.guild.get(guildId, false);

    final userMap = payload['user'] as Map<String, dynamic>;
    final before =
        await _dataStore.member.get(guildId, userMap['id'] as String, false);
    final rawMember =
        await _marshaller.serializers.member.normalize(payload);
    final member = await _marshaller.serializers.member.serialize(rawMember);

    dispatch<GuildMemberUpdateArgs>(event: Event.guildMemberUpdate, payload: (guild: guild, before: before!, after: member));
  }
}
