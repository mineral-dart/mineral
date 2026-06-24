import 'package:mineral_test/mineral_test.dart';
import 'package:test/test.dart';

import 'src/mod_command.dart';

void main() {
  group('/mod ban', () {
    late TestBot bot;
    late TestGuild guild;
    late TestUser moderator;
    late TestUser regularUser;
    late TestUser target;

    setUp(() async {
      bot = await TestBot.create();
      guild = GuildBuilder().withName('Ban Land').build();
      moderator = UserBuilder().withUsername('mod').build();
      regularUser = UserBuilder().withUsername('regular').build();
      target = UserBuilder().withUsername('spammer').build();

      final targetMember = MemberBuilder()
          .ofGuild(guild)
          .withUser(target)
          .build();
      bot.dataStore.seed(guilds: [guild], members: [targetMember]);

      bot.events.register(ModBanListener(moderatorIds: {moderator.id}));
    });

    tearDown(() => bot.dispose());

    test('an authorized moderator can ban a user', () async {
      await bot.simulateCommand(
        'mod.ban',
        options: {'user': target, 'reason': 'spam'},
        invokedBy: moderator,
        in_: guild,
      );

      expect(
        bot.actions.bans,
        contains(isMemberBanned(memberId: target.id, reason: 'spam')),
      );
      expect(
        bot.actions.interactionReplies,
        contains(isInteractionReplied(content: 'Banned spammer.')),
      );

      // The store façade removed the banned member.
      expect(bot.dataStore.members(in_: guild), isEmpty);
    });

    test('an unauthorized user gets an ephemeral refusal', () async {
      await bot.simulateCommand(
        'mod.ban',
        options: {'user': target, 'reason': 'meh'},
        invokedBy: regularUser,
        in_: guild,
      );

      expect(bot.actions.bans, isEmpty);
      expect(
        bot.actions.interactionReplies,
        contains(
          isInteractionReplied(
            content: 'You are not allowed to run this command.',
            ephemeral: true,
          ),
        ),
      );
    });

    test('invalid arguments produce an ephemeral error reply', () async {
      await bot.simulateCommand(
        'mod.ban',
        options: const {'user': 'not a user'},
        invokedBy: moderator,
        in_: guild,
      );

      expect(bot.actions.bans, isEmpty);
      expect(
        bot.actions.interactionReplies,
        contains(
          isInteractionReplied(content: 'Invalid arguments.', ephemeral: true),
        ),
      );
    });
  });
}
