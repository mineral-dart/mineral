import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/events/event.dart';
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
    final serverId = payload['guild_id'] as String;
    final server = await _dataStore.server.get(serverId, false);

    final userMap = payload['user'] as Map<String, dynamic>;
    final before =
        await _dataStore.member.get(serverId, userMap['id'] as String, false);
    final rawMember =
        await _marshaller.serializers.member.normalize(payload);
    final member = await _marshaller.serializers.member.serialize(rawMember);

    dispatch<ServerMemberUpdateArgs>(event: Event.serverMemberUpdate, payload: (server: server, before: before!, after: member));
  }
}
