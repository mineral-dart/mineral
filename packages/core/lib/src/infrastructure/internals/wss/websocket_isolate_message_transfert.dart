import 'dart:async';

enum MessageTransfertType {
  send(0),
  request(1),
  response(2);

  final int value;

  const MessageTransfertType(this.value);
}

final class WebsocketIsolateMessageTransfert {
  final MessageTransfertType type;
  final Map<String, dynamic>? payload;

  final String? uid;
  final List<String> targetKeys;
  final Completer? completer;

  WebsocketIsolateMessageTransfert(
    this.type,
    this.payload,
    this.uid,
    this.targetKeys,
    this.completer,
  );

  const WebsocketIsolateMessageTransfert.send(this.payload)
    : type = MessageTransfertType.send,
      uid = null,
      targetKeys = const [],
      completer = null;

  const WebsocketIsolateMessageTransfert.request({
    required this.uid,
    this.payload,
    this.targetKeys = const [],
    this.completer,
  }) : type = MessageTransfertType.request;

  factory WebsocketIsolateMessageTransfert.fromJson(Map<String, dynamic> json) {
    return WebsocketIsolateMessageTransfert(
      MessageTransfertType.values[json['type'] as int],
      json['payload'] as Map<String, dynamic>?,
      json['uid'] as String?,
      List<String>.from(json['target_keys'] as Iterable<dynamic>),
      null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'payload': payload,
      'target_keys': targetKeys,
      'uid': uid,
    };
  }
}
