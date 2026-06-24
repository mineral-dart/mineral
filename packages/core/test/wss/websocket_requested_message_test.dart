import 'package:mineral/src/infrastructure/services/wss/websocket_requested_message.dart';
import 'package:test/test.dart';

void main() {
  group('WebsocketRequestedMessageImpl', () {
    test('stores channelName', () {
      final message = WebsocketRequestedMessageImpl(
        channelName: 'shard-0',
        content: '{"op":1}',
      );

      expect(message.channelName, 'shard-0');
    });

    test('stores content', () {
      final message = WebsocketRequestedMessageImpl(
        channelName: 'shard-0',
        content: '{"op":1,"d":null}',
      );

      expect(message.content, '{"op":1,"d":null}');
    });

    test('content is mutable', () {
      final message = WebsocketRequestedMessageImpl(
        channelName: 'shard-0',
        content: 'original',
      )..content = 'modified';

      expect(message.content, 'modified');
    });

    test('content can be changed to different type', () {
      final message = WebsocketRequestedMessageImpl(
        channelName: 'shard-0',
        content: '{"op":1}',
      )..content = [1, 2, 3, 4];

      expect(message.content, [1, 2, 3, 4]);
    });

    test('createdAt is initialized near current time', () {
      final before = DateTime.now();
      final message = WebsocketRequestedMessageImpl(
        channelName: 'shard-0',
        content: '{}',
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
  });
}
