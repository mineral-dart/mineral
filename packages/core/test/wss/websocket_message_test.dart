import 'package:mineral/src/infrastructure/services/wss/websocket_message.dart';
import 'package:test/test.dart';

void main() {
  group('WebsocketMessageImpl', () {
    test('stores channelName', () {
      final message = WebsocketMessageImpl(
        channelName: 'shard-0',
        originalContent: '{}',
        content: null,
      );

      expect(message.channelName, 'shard-0');
    });

    test('stores originalContent', () {
      final original = '{"op":10,"t":null}';
      final message = WebsocketMessageImpl(
        channelName: 'shard-0',
        originalContent: original,
        content: null,
      );

      expect(message.originalContent, original);
    });

    test('stores and allows mutation of content', () {
      final message = WebsocketMessageImpl<Map<String, dynamic>?>(
        channelName: 'shard-0',
        originalContent: '{}',
        content: null,
      );

      expect(message.content, isNull);

      message.content = {'op': 10};
      expect(message.content, {'op': 10});
    });

    test('createdAt is initialized near current time', () {
      final before = DateTime.now();
      final message = WebsocketMessageImpl(
        channelName: 'shard-0',
        originalContent: '{}',
        content: null,
      );
      final after = DateTime.now();

      expect(
        message.createdAt.isAfter(before.subtract(Duration(seconds: 1))),
        isTrue,
      );
      expect(
        message.createdAt.isBefore(after.add(Duration(seconds: 1))),
        isTrue,
      );
    });

    test('can store different content types', () {
      final stringMessage = WebsocketMessageImpl<String>(
        channelName: 'ch',
        originalContent: 'raw',
        content: 'parsed',
      );
      expect(stringMessage.content, 'parsed');

      final mapMessage = WebsocketMessageImpl<Map<String, dynamic>>(
        channelName: 'ch',
        originalContent: '{}',
        content: {'key': 'value'},
      );
      expect(mapMessage.content, {'key': 'value'});
    });
  });
}
