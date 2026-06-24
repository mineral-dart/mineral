abstract interface class WebsocketMessage<T> {
  String get channelName;

  DateTime get createdAt;

  dynamic get originalContent;

  abstract T content;
}

final class WebsocketMessageImpl<T> implements WebsocketMessage<T> {
  @override
  final String channelName;

  @override
  final DateTime createdAt = DateTime.now();

  @override
  final dynamic originalContent;

  @override
  T content;

  WebsocketMessageImpl({
    required this.channelName,
    required this.originalContent,
    required this.content,
  });
}
