import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/api/server/guild_application_command_permissions.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class ApplicationCommandPermissionsUpdatePacket
    implements ListenablePacket {
  @override
  PacketType get packetType =>
      PacketType.applicationCommandPermissionsUpdate;

  final DataStoreContract _dataStore;

  ApplicationCommandPermissionsUpdatePacket(
      {required DataStoreContract dataStore})
      : _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final server = await _dataStore.server
        .get(message.payload['guild_id'] as Object, false);

    final permissions = GuildApplicationCommandPermissions.fromJson(
        Map<String, dynamic>.from(message.payload as Map));

    dispatch<ServerApplicationCommandPermissionsUpdateArgs>(
      event: Event.serverApplicationCommandPermissionsUpdate,
      payload: (server: server, permissions: permissions),
    );
  }
}
