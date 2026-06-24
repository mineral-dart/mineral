import 'dart:convert';

import 'package:eterl/eterl.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/utils/safe_cast.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:mineral/src/infrastructure/io/exceptions/serialization_exception.dart';
import 'package:mineral/src/infrastructure/services/wss/websocket_message.dart';
import 'package:mineral/src/infrastructure/services/wss/websocket_requested_message.dart';

final class EtfEncoderStrategy implements EncodingStrategy {
  @override
  WsEncoder get encoder => WsEncoder.etf;

  final LoggerContract _logger;

  EtfEncoderStrategy({required LoggerContract logger}) : _logger = logger;

  @override
  WebsocketMessage decode(WebsocketMessage message) {
    try {
      final bytes = safeCast<List<int>>(
        message.originalContent,
        context: 'etf frame body',
      );
      final content = eterl.unpack<Map<String, dynamic>>(bytes);
      return message..content = ShardMessage.of(content);
    } on SerializationException {
      rethrow;
    } on Exception catch (e) {
      _logger.error('Failed to decode ETF WebSocket message: $e');
      throw SerializationException(
        'Failed to decode ETF WebSocket message: $e',
      );
    }
  }

  @override
  WebsocketRequestedMessage encode(WebsocketRequestedMessage message) {
    try {
      return message
        ..content = eterl.pack(json.decode(message.content as String));
    } on Exception catch (e) {
      _logger.error('Failed to encode ETF WebSocket message: $e');
      rethrow;
    }
  }
}
