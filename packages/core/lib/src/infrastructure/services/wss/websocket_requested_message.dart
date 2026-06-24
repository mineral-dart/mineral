abstract interface class WebsocketRequestedMessage {
  DateTime get createdAt;

  String get channelName;

  dynamic content;
}

final class WebsocketRequestedMessageImpl implements WebsocketRequestedMessage {
  @override
  final DateTime createdAt = DateTime.now();

  @override
  final String channelName;

  @override
  dynamic content;

  WebsocketRequestedMessageImpl({
    required this.channelName,
    required this.content,
  });
}
