import 'dart:async';

import 'package:mineral/src/domains/events/event.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

typedef DispatchEvent =
    void Function<T extends Object>({
      required Event event,
      required T payload,
      bool Function(String?)? constraint,
    });

abstract interface class ListenablePacket<T> {
  PacketType get packetType;

  FutureOr<void> listen(ShardMessage message, DispatchEvent dispatch);
}
