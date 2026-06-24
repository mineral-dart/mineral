import 'dart:convert';

import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/utils/safe_cast.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:mineral/src/infrastructure/io/exceptions/serialization_exception.dart';
import 'package:mineral/src/infrastructure/services/wss/websocket_message.dart';
import 'package:mineral/src/infrastructure/services/wss/websocket_requested_message.dart';

final class JsonEncoderStrategy implements EncodingStrategy {
  @override
  WsEncoder get encoder => WsEncoder.json;

  final LoggerContract _logger;

  JsonEncoderStrategy({required LoggerContract logger}) : _logger = logger;

  @override
  WebsocketMessage decode(WebsocketMessage message) {
    try {
      final raw = safeCast<String>(
        message.originalContent,
        context: 'json frame body',
      );
      final decoded = safeCast<Map<String, dynamic>>(
        json.decode(raw),
        context: 'json frame payload',
      );
      return message..content = ShardMessage.of(decoded);
    } on SerializationException {
      rethrow;
    } on Exception catch (e) {
      _logger.error('Failed to decode JSON WebSocket message: $e');
      throw SerializationException(
        'Failed to decode JSON WebSocket message: $e',
      );
    }
  }

  @override
  WebsocketRequestedMessage encode(WebsocketRequestedMessage message) =>
      message;
}
