import 'package:mineral_test/mineral_test.dart';
import 'package:test/test.dart';

import 'src/ping_command.dart';

void main() {
  group('/ping', () {
    late TestBot bot;

    setUp(() async {
      bot = await TestBot.create();
    });

    tearDown(() => bot.dispose());

    test('replies with "pong"', () async {
      bot.events.register(PingListener());
      final caller = UserBuilder().withUsername('alice').build();

      await bot.simulateCommand('ping', invokedBy: caller);

      expect(
        bot.actions.interactionReplies,
        contains(isInteractionReplied(content: 'pong')),
      );
      expect(bot.errors, isEmpty);
    });

    test('DSL: whenCommand(...).expectReply(...)', () async {
      bot.events.register(PingListener());

      await bot
          .whenCommand('ping')
          .invokedBy(UserBuilder().build())
          .expectReply(content: 'pong');
    });

    test('/echo replies with the message option', () async {
      bot.events.register(EchoListener());

      await bot
          .whenCommand('echo')
          .withOptions({'message': 'hello world'})
          .expectReply(content: 'hello world');
    });

    test('handler errors are captured under bot.errors', () async {
      bot.events.register(BoomListener());

      await bot.simulateCommand('boom', invokedBy: UserBuilder().build());

      expect(bot.errors, hasLength(1));
      expect(bot.errors.single.commandName, 'boom');
      expect(bot.errors.single.error, isA<StateError>());
      expect(bot.actions.interactionReplies, isEmpty);
    });
  });
}
