import 'dart:async';
import 'dart:collection';
import 'dart:io' as io;

import 'package:mineral/contracts.dart';
import 'package:mineral/src/infrastructure/io/exceptions/serialization_exception.dart';
import 'package:mineral/src/infrastructure/services/wss/interceptor.dart';
import 'package:mineral/src/infrastructure/services/wss/websocket_message.dart';
import 'package:mineral/src/infrastructure/services/wss/websocket_requested_message.dart';

abstract interface class WebsocketClient {
  String get name;

  String get url;

  Stream? get stream;

  Interceptor get interceptor;

  Future<void> connect();

  Future<void> disconnect({int? code, String? reason});

  Future<void> send(String message);

  Future<void> listen(void Function(WebsocketMessage) callback);
}

final class WebsocketClientImpl implements WebsocketClient {
  io.WebSocket? _channel;
  StreamSubscription<dynamic>? _channelListener;
  final void Function(Object payload)? _onError;
  final void Function(int? exitCode)? _onClose;
  final void Function(WebsocketMessage)? _onOpen;
  void Function(WebsocketMessage)? _onMessage;

  final LoggerContract _logger;

  // Rate limiter: Discord allows 120 gateway commands per 60 seconds.
  static const int _rateLimitMax = 120;
  int _tokens = _rateLimitMax;
  final Queue<String> _sendQueue = Queue<String>();
  Timer? _refillTimer;

  @override
  final Interceptor interceptor = InterceptorImpl();

  @override
  final String name;

  @override
  final String url;

  @override
  Stream? stream;

  WebsocketClientImpl(
      {required this.url,
      required LoggerContract logger,
      this.name = 'default',
      void Function(Object payload)? onError,
      void Function(int? exitCode)? onClose,
      void Function(WebsocketMessage)? onOpen})
      : _logger = logger,
        _onError = onError,
        _onClose = onClose,
        _onOpen = onOpen;

  @override
  Future<void> connect() async {
    try {
      _channel = await io.WebSocket.connect(url);
      stream = _channel!.asBroadcastStream();

      _tokens = _rateLimitMax;
      _refillTimer?.cancel();
      _refillTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (_tokens < _rateLimitMax) {
          _tokens++;
          _drainQueue();
        }
      });

      _channelListener = stream!.listen(
        (dynamic message) => _handleMessage(_onMessage, message),
        onError: (Object err) {
          _onError?.call({
            'error': err,
            'code': _channel?.closeCode,
            'reason': _channel?.closeReason,
          });
        },
        onDone: () {
          _onClose?.call(_channel?.closeCode);
        },
      );

      if (_onOpen != null) {
        final firstMessage = await stream?.first;
        _handleMessage(_onOpen, firstMessage);
      }
    } on io.WebSocketException catch (err) {
      _logger.error('WebSocket connection failed: $err');
      _onClose?.call(1006);
    } on io.SocketException catch (err) {
      _logger.error('Socket connection failed: $err');
      _onClose?.call(1006);
    }
  }

  @override
  Future<void> disconnect({int? code = 1000, String? reason}) async {
    _refillTimer?.cancel();
    _sendQueue.clear();
    _channelListener?.cancel();
    await _channel?.close(code, reason);
  }

  @override
  Future<void> listen(void Function(WebsocketMessage) callback) async {
    _onMessage = callback;
  }

  Future<void> _handleMessage(dynamic callback, dynamic message) async {
    try {
      final interceptedMessage = await _handleMessageInterceptors(
          WebsocketMessageImpl(
              channelName: name, originalContent: message, content: message));
      callback(interceptedMessage);
    } on SerializationException catch (e) {
      _logger.warn('Dropping malformed gateway frame: $e');
    }
  }

  @override
  Future<void> send(String message) async {
    final interceptedMessage = await _handleRequestedMessageInterceptors(
        WebsocketRequestedMessageImpl(channelName: name, content: message));

    switch (_channel?.readyState) {
      case io.WebSocket.open:
        if (_tokens > 0) {
          _tokens--;
          _channel?.add(interceptedMessage.content);
        } else {
          _sendQueue.add(interceptedMessage.content as String);
        }
      case io.WebSocket.closed when _onClose != null:
        _onClose(_channel?.closeCode);
    }
  }

  void _drainQueue() {
    while (_sendQueue.isNotEmpty &&
        _tokens > 0 &&
        _channel?.readyState == io.WebSocket.open) {
      _tokens--;
      _channel?.add(_sendQueue.removeFirst());
    }
  }

  Future<WebsocketMessage> _handleMessageInterceptors(
      WebsocketMessage message) async {
    for (final interceptor in interceptor.message) {
      message = await interceptor(message);
    }

    return message;
  }

  Future<WebsocketRequestedMessage> _handleRequestedMessageInterceptors(
      WebsocketRequestedMessage message) async {
    for (final interceptor in interceptor.request) {
      message = await interceptor(message);
    }

    return message;
  }
}
