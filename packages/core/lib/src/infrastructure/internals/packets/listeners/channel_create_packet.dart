import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/mineral.dart';
import 'package:mineral/src/api/private/channels/private_channel.dart';
import 'package:mineral/src/api/server/channels/server_channel.dart';
import 'package:mineral/src/domains/container/ioc_container.dart';
import 'package:mineral/src/domains/events/event.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class ChannelCreatePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.channelCreate;

  final LoggerContract _logger;

  ChannelCreatePacket({required LoggerContract logger}) : _logger = logger;

  MarshallerContract get _marshaller => ioc.resolve<MarshallerContract>();

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final rawChannel = await _marshaller.serializers.channels
        .normalize(message.payload as Map<String, dynamic>);
    final channel =
        await _marshaller.serializers.channels.serialize(rawChannel);

    return switch (channel) {
      ServerChannel() => dispatch<ServerChannelCreateArgs>(
          event: Event.serverChannelCreate, payload: (channel: channel)),
      PrivateChannel() => dispatch<PrivateChannelCreateArgs>(
          event: Event.privateChannelCreate, payload: (channel: channel)),
      _ => _logger
          .warn("Unknown channel type: $channel contact Mineral's core team.")
    };
  }
}
