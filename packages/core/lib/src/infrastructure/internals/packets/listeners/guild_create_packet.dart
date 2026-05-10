import 'package:mineral/events.dart';
import 'package:mineral/src/domains/commands/command_interaction_manager.dart';
import 'package:mineral/src/domains/common/runtime_state.dart';
import 'package:mineral/src/domains/events/event.dart';
import 'package:mineral/src/domains/services/marshaller/marshaller.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class GuildCreatePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.guildCreate;

  final MarshallerContract _marshaller;
  final CommandInteractionManagerContract _commandManager;
  final RuntimeState _runtimeState;

  GuildCreatePacket({
    required MarshallerContract marshaller,
    required CommandInteractionManagerContract commandManager,
    required RuntimeState runtimeState,
  })  : _marshaller = marshaller,
        _commandManager = commandManager,
        _runtimeState = runtimeState;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final payload = message.payload as Map<String, dynamic>;
    await List.from(payload['channels'] as Iterable<dynamic>).map((element) async {
      return _marshaller.serializers.channels.normalize({
        ...(element as Map<String, dynamic>),
        'guild_id': payload['id'],
      });
    }).wait;

    await List.from(payload['members'] as Iterable<dynamic>).map((element) async {
      return _marshaller.serializers.member.normalize({
        ...(element as Map<String, dynamic>),
        'guild_id': payload['id'],
      });
    }).wait;

    await List.from(payload['roles'] as Iterable<dynamic>).map((element) async {
      return _marshaller.serializers.role.normalize({
        ...(element as Map<String, dynamic>),
        'guild_id': payload['id'],
      });
    }).wait;

    await List.from(payload['stickers'] as Iterable<dynamic>).map((element) async {
      return _marshaller.serializers.sticker.normalize({
        ...(element as Map<String, dynamic>),
        'guild_id': payload['id'],
      });
    }).wait;

    await List.from(payload['voice_states'] as Iterable<dynamic>).map((element) async {
      return _marshaller.serializers.voice.normalize({
        ...(element as Map<String, dynamic>),
        'guild_id': payload['id'],
      });
    }).wait;

    final rawServer =
        await _marshaller.serializers.server.normalize(payload);
    final server = await _marshaller.serializers.server.serialize(rawServer);

    // Bot is created at runtime by ReadyPacket and published to the shared
    // [RuntimeState]. If GUILD_CREATE arrives before READY (shouldn't happen
    // per Discord ordering), this throws — we'd be in a broken gateway state.
    final bot = _runtimeState.bot ??
        (throw StateError(
            'GUILD_CREATE received before READY; bot identity not set.'));

    await _commandManager.registerServer(bot, server);

    dispatch<ServerCreateArgs>(event: Event.serverCreate, payload: (server: server));
  }
}
