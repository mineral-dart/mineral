import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/api/private/channels/private_channel.dart';
import 'package:mineral/src/api/server/channels/server_channel.dart';
import 'package:mineral/src/domains/events/event.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class ChannelPinsUpdatePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.channelPinsUpdate;

  final LoggerContract _logger;
  final DataStoreContract _dataStore;

  ChannelPinsUpdatePacket({
    required LoggerContract logger,
    required DataStoreContract dataStore,
  })  : _logger = logger,
        _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final channel =
        await _dataStore.channel.get(message.payload['channel_id'] as Object, false);

    return switch (channel) {
      ServerChannel() => registerServerChannelPins(channel, dispatch),
      PrivateChannel() => registerPrivateChannelPins(channel, dispatch),
      _ => _logger
          .warn("Unknown channel type: $channel contact Mineral's core team.")
    };
  }

  Future<void> registerServerChannelPins(
      ServerChannel channel, DispatchEvent dispatch) async {
    final server = await _dataStore.server.get(channel.serverId.value, false);

    dispatch<ServerChannelPinsUpdateArgs>(event: Event.serverChannelPinsUpdate, payload: (server: server, channel: channel));
  }

  Future<void> registerPrivateChannelPins(
      PrivateChannel channel, DispatchEvent dispatch) async {
    dispatch<PrivateChannelPinsUpdateArgs>(event: Event.privateChannelPinsUpdate, payload: (channel: channel));
  }
}
