import 'package:mineral_test/mineral_test.dart';
import 'package:test/test.dart';

import 'src/welcome_listener.dart';

void main() {
  group('WelcomeListener', () {
    late TestBot bot;
    late TestGuild guild;

    setUp(() async {
      bot = await TestBot.create();
      guild = GuildBuilder().withName('Mineral HQ').build();
      bot.events.register(WelcomeListener());
    });

    tearDown(() => bot.dispose());

    test('sends a welcome message into the configured channel', () async {
      final user = UserBuilder().withUsername('bob').build();
      final member = MemberBuilder().ofGuild(guild).withUser(user).build();

      await bot.simulateMemberJoin(member: member, guild: guild);

      expect(
        bot.actions.sentMessages,
        contains(
          isMessageSent(
            channelId: WelcomeListener.welcomeChannelId,
            content: 'hello bob, welcome to Mineral HQ!',
          ),
        ),
      );
      expect(bot.errors, isEmpty);
    });

    test('content predicate via Matcher works', () async {
      final user = UserBuilder().withUsername('carol').build();
      final member = MemberBuilder().ofGuild(guild).withUser(user).build();

      await bot.simulateMemberJoin(member: member, guild: guild);

      expect(
        bot.actions.sentMessages,
        contains(isMessageSent(content: contains('carol'))),
      );
    });
  });
}
