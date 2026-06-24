import 'package:mineral/contracts.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

abstract interface class PacketDispatcherContract {
  void listen(
    PacketTypeContract packet,
    Function(ShardMessage, DispatchEvent) listener,
  );

  void dispatch(dynamic payload);

  void dispose();
}
