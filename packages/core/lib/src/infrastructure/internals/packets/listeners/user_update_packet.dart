import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class UserUpdatePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.userUpdate;

  final MarshallerContract _marshaller;

  UserUpdatePacket({required MarshallerContract marshaller})
      : _marshaller = marshaller;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final payload = message.payload as Map<String, dynamic>;
    final userId = payload['id'] as String;

    final userCacheKey = _marshaller.cacheKey.user(userId);
    final rawUser = await _marshaller.cache?.get(userCacheKey);
    final before =
        rawUser != null ? await _marshaller.serializers.user.serialize(rawUser) : null;

    final rawAfter =
        await _marshaller.serializers.user.normalize(payload);
    final after = await _marshaller.serializers.user.serialize(rawAfter);

    dispatch<UserUpdateArgs>(
        event: Event.userUpdate, payload: (before: before, after: after));
  }
}
