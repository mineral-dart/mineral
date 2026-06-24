import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class ThreadMembersUpdatePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.threadMembersUpdate;

  final MarshallerContract _marshaller;
  final DataStoreContract _dataStore;

  ThreadMembersUpdatePacket({
    required MarshallerContract marshaller,
    required DataStoreContract dataStore,
  })  : _marshaller = marshaller,
        _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final payload = message.payload as Map<String, dynamic>;
    final guild =
        await _dataStore.guild.get(payload['guild_id'] as String, false);
    final thread = await _dataStore.channel
        .get<ThreadChannel>(payload['id'] as String, false);

    await List.from(payload['added_members'] as Iterable<dynamic>).map((element) async {
      final el = element as Map<String, dynamic>;
      Member? member;
      if (el['member'] != null) {
        member = await _dataStore.member
            .get(payload['guild_id'] as String, el['user_id'] as String, false);
      } else {
        final rawMember =
            await _marshaller.serializers.member.normalize(el);
        member = await _marshaller.serializers.member.serialize(rawMember);
      }

      dispatch<GuildThreadMemberArgs>(
          event: Event.guildThreadMemberAdd, payload: (thread: thread!, guild: guild, member: member!));
    }).wait;

    await List.from(payload['removed_member_ids'] as Iterable<dynamic>).map((element) async {
      final el = element as Map<String, dynamic>;
      Member? member;
      if (el['member'] != null) {
        member = await _dataStore.member
            .get(payload['guild_id'] as String, el['user_id'] as String, false);
      } else {
        final rawMember =
            await _marshaller.serializers.member.normalize(el);
        member = await _marshaller.serializers.member.serialize(rawMember);
      }

      dispatch<GuildThreadMemberArgs>(
          event: Event.guildThreadMemberRemove,
          payload: (thread: thread!, guild: guild, member: member!));
    }).wait;
  }
}
