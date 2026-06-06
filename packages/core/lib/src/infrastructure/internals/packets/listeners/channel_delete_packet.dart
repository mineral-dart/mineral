import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/services/cache/cache_invalidation.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class ChannelDeletePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.channelDelete;

  final MarshallerContract _marshaller;

  ChannelDeletePacket({required MarshallerContract marshaller})
      : _marshaller = marshaller;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final rawChannel =
        await _marshaller.serializers.channels.normalize(message.payload as Map<String, dynamic>);
    final channel =
        await _marshaller.serializers.channels.serialize(rawChannel);

    final channelCacheKey = _marshaller.cacheKey.channel(channel.id.value);
    await _marshaller.cache.invalidate(channelCacheKey);

    dispatch<ServerChannelDeleteArgs>(event: Event.serverChannelDelete, payload: (channel: channel as ServerChannel));
  }
}
