import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/wss/dispatchers/shard_authentication.dart';
import 'package:mineral/src/infrastructure/services/wss/websocket_client.dart';
import 'package:mineral/src/infrastructure/services/wss/websocket_message.dart';

abstract interface class ShardContract {
  String get shardName;

  WebsocketOrchestratorContract get wss;

  WebsocketClient get client;

  ShardAuthentication get authentication;

  Future<void> init({String? url});
}

abstract interface class ShardMessageContract<T, OpCodeEnum extends OpCode> {
  String? get type;

  OpCodeEnum get opCode;

  int? get sequence;

  T get payload;

  Object serialize();
}

abstract interface class ShardDataContract {
  void dispatch(WebsocketMessage message);
}

abstract interface class ShardNetworkErrorContract {
  void dispatch(dynamic payload);
}
