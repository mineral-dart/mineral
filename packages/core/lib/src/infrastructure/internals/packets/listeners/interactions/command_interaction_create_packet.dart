import 'package:collection/collection.dart';
import 'package:mineral/src/api/common/types/interaction_type.dart';
import 'package:mineral/src/domains/commands/command_interaction_manager.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class CommandInteractionCreatePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.interactionCreate;

  final CommandInteractionManagerContract _commandManager;

  CommandInteractionCreatePacket({
    required CommandInteractionManagerContract commandManager,
  }) : _commandManager = commandManager;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final type = InteractionType.values.firstWhereOrNull(
      (e) => e.value == message.payload['type'],
    );

    if (type == InteractionType.applicationCommand) {
      await _commandManager.dispatcher.dispatch(
        message.payload as Map<String, dynamic>,
      );
    } else if (type == InteractionType.applicationCommandAutocomplete) {
      await _commandManager.handleAutocomplete(
        message.payload as Map<String, dynamic>,
      );
    }
  }
}
