import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/api/guild/channels/guild_channel.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class WebhooksUpdatePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.webhooksUpdate;

  final DataStoreContract _dataStore;

  WebhooksUpdatePacket({required DataStoreContract dataStore})
      : _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final guild =
        await _dataStore.guild.get(message.payload['guild_id'] as Object, false);
    final channel =
        await _dataStore.channel.get<GuildChannel>(message.payload['channel_id'] as Object, false);

    dispatch<GuildWebhooksUpdateArgs>(
        event: Event.guildWebhooksUpdate,
        payload: (guild: guild, channel: channel));
  }
}
