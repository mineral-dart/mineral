import 'dart:async';

import 'package:mineral/src/infrastructure/services/wss/interceptor.dart';
import 'package:mineral/src/infrastructure/services/wss/websocket_client.dart';
import 'package:mineral/src/infrastructure/services/wss/websocket_message.dart';
import 'package:mineral/src/infrastructure/services/wss/websocket_requested_message.dart';

final class FakeInterceptor implements Interceptor {
  @override
  final List<FutureOr<WebsocketMessage> Function(WebsocketMessage)> message =
      [];
  @override
  final List<
    FutureOr<WebsocketRequestedMessage> Function(WebsocketRequestedMessage)
  >
  request = [];
}

final class FakeWebsocketClient implements WebsocketClient {
  bool disconnected = false;
  bool connected = false;
  int? lastDisconnectCode;
  final List<String> sentMessages = [];

  @override
  final String name;

  @override
  final String url;

  @override
  Stream? stream;

  @override
  final Interceptor interceptor = FakeInterceptor();

  FakeWebsocketClient({this.name = 'test-shard', this.url = 'wss://fake'});

  @override
  Future<void> connect() async {
    connected = true;
    disconnected = false;
  }

  @override
  Future<void> disconnect({int? code = 1000, String? reason}) async {
    disconnected = true;
    connected = false;
    lastDisconnectCode = code;
  }

  @override
  Future<void> send(String message) async {
    sentMessages.add(message);
  }

  @override
  Future<void> listen(void Function(WebsocketMessage) callback) async {}
}
