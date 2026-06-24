import 'dart:collection';
import 'dart:convert';

import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/utils/redact.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/domains/services/wss/running_strategy.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/dispatchers/shard_authentication.dart';
import 'package:mineral/src/infrastructure/internals/wss/dispatchers/shard_data.dart';
import 'package:mineral/src/infrastructure/internals/wss/dispatchers/shard_network_error.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:mineral/src/infrastructure/services/wss/websocket_client.dart';
import 'package:mineral/src/infrastructure/services/wss/websocket_message.dart';

final class Shard implements ShardContract {
  @override
  final Queue<Map<String, dynamic>> onceEventQueue = Queue();

  @override
  final String shardName;

  @override
  final WebsocketOrchestratorContract wss;

  @override
  late WebsocketClient client;

  @override
  late final ShardAuthentication authentication;

  final int shardIndex;
  final int shardCount;

  final LoggerContract logger;

  String url;

  late final ShardData dispatchEvent;

  late final ShardNetworkError networkError;

  Shard({
    required this.shardName,
    required this.shardIndex,
    required this.shardCount,
    required this.url,
    required this.wss,
    required this.logger,
    required RunningStrategy strategy,
  }) {
    authentication = ShardAuthentication(this);
    networkError = ShardNetworkError(this);
    dispatchEvent = ShardData(this, strategy);
  }

  @override
  Future<void> init({String? url}) async {
    if (url != null) {
      this.url = url;
    }

    client = WebsocketClientImpl(
      name: shardName,
      url: this.url,
      logger: logger,
      onError: (error) {
        logger.error('WebSocket error: $error');
        if (error is Map && error['code'] is int) {
          networkError.dispatch(error['code']);
        } else {
          networkError.dispatch(null);
        }
      },
      onClose: networkError.dispatch,
      onOpen: (message) {
        if (message.content case ShardMessage(:final payload)) {
          logger.trace(
            jsonEncode(redactSensitiveFields(payload as Map<String, dynamic>)),
          );
        }
      },
    );

    client.interceptor.message
      ..add(wss.config.encoding.decode)
      ..add((WebsocketMessage message) {
        final logPayload = message.content.payload;
        logger.trace({
          'shard': shardName,
          'message': logPayload is Map<String, dynamic>
              ? redactSensitiveFields(logPayload)
              : logPayload,
        });
        return message;
      });

    client.interceptor.request.add(wss.config.encoding.encode);

    await client.listen((message) {
      if (message.content case ShardMessage(
        opCode: final code,
        payload: final payload,
      )) {
        try {
          switch (code) {
            case OpCode.hello:
              if (payload is! Map<String, dynamic>) {
                logger.error(
                  'OpCode.hello: expected Map payload, got ${payload.runtimeType}',
                );
                break;
              }
              authentication.identify(payload);
            case OpCode.heartbeatAck:
              authentication.ack();
            case OpCode.reconnect:
              authentication.reconnect();
            case OpCode.invalidSession:
              if (payload == true) {
                authentication.resume();
              } else {
                authentication.reconnect();
              }
            case OpCode.dispatch:
              if ([
                PacketType.ready.name,
                PacketType.guildCreate.name,
              ].contains((message.content as ShardMessage).type)) {
                final decoded = wss.config.encoding.decode(message);
                onceEventQueue.add(
                  (decoded.content as ShardMessage).serialize()
                      as Map<String, dynamic>,
                );
              }

              dispatchEvent.dispatch(message);
            case OpCode.heartbeat:
              authentication.heartbeat();
            default:
              logger.warn('Unknown op code: $code');
          }
          // ignore: avoid_catching_errors, crash-safety boundary for shard message processing
        } on Error catch (e, stackTrace) {
          logger
            ..error('Fatal error processing opcode $code on $shardName: $e')
            ..trace('$stackTrace');
        } on Exception catch (e, stackTrace) {
          logger
            ..error('Error processing opcode $code on $shardName: $e')
            ..trace('$stackTrace');
        }
      }
    });

    await authentication.connect();
  }
}
