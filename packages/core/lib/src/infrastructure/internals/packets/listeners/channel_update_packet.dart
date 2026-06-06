import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/api/private/channels/private_channel.dart';
import 'package:mineral/src/api/server/channels/server_channel.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class ChannelUpdatePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.channelUpdate;

  final LoggerContract _logger;
  final MarshallerContract _marshaller;

  ChannelUpdatePacket({
    required LoggerContract logger,
    required MarshallerContract marshaller,
  })  : _logger = logger,
        _marshaller = marshaller;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final rawBeforeChannel =
        await _marshaller.cache?.get(message.payload['id'] as String);
    final before = rawBeforeChannel != null
        ? await _marshaller.serializers.channels.serialize(rawBeforeChannel)
        : null;

    final rawChannel =
        await _marshaller.serializers.channels.normalize(message.payload as Map<String, dynamic>);
    final channel =
        await _marshaller.serializers.channels.serialize(rawChannel);

    return switch (channel) {
      ServerChannel() => dispatch<ServerChannelUpdateArgs>(
          event: Event.serverChannelUpdate,
          payload: (before: before as ServerChannel?, after: channel)),
      PrivateChannel() => dispatch<PrivateChannelUpdateArgs>(
          event: Event.privateChannelUpdate,
          payload: (before: before as PrivateChannel?, after: channel)),
      _ => _logger
          .warn("Unknown channel type: $channel contact Mineral's core team.")
    };
  }
}
