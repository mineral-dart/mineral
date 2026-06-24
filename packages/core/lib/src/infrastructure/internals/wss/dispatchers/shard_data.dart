import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/services/wss/running_strategy.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:mineral/src/infrastructure/services/wss/websocket_message.dart';

final class ShardData implements ShardDataContract {
  final RunningStrategy _dispatchStrategy;
  final Shard _shard;

  ShardData(Shard shard, this._dispatchStrategy) : _shard = shard;

  @override
  void dispatch(WebsocketMessage message) {
    if (message.content case ShardMessage(
      :final sequence,
    ) when sequence != null) {
      _shard.authentication.sequence = sequence;
    }

    if (message.content case ShardMessage(
      :final type,
      :final payload,
    ) when type == PacketType.ready.name) {
      _shard.authentication.setupRequirements(payload as Map<String, dynamic>);
    }

    if (message.content case ShardMessage(
      :final type,
    ) when type == PacketType.resumed.name) {
      _shard.authentication.resetReconnectAttempts();
    }

    _dispatchStrategy.dispatch(message);
  }
}
