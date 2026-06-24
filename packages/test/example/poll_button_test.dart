import 'package:mineral_test/mineral_test.dart';
import 'package:test/test.dart';

import 'src/poll_buttons.dart';

void main() {
  group('Poll buttons', () {
    late TestBot bot;
    late TestUser voter;

    setUp(() async {
      bot = await TestBot.create();
      voter = UserBuilder().withUsername('voter').build();
      bot.events.register(VoteYesButton());
      bot.events.register(VoteCommentModal());
    });

    tearDown(() => bot.dispose());

    test('clicking "Yes" opens the comment modal', () async {
      await bot.simulateButton('poll_vote:yes', clickedBy: voter);

      expect(
        bot.actions.modals,
        contains(
          isModalShown(customId: 'poll_comment', title: 'Add a comment'),
        ),
      );
    });

    test('DSL: whenButton(...).expectModal(...)', () async {
      await bot
          .whenButton('poll_vote:yes')
          .clickedBy(voter)
          .expectModal(customId: 'poll_comment');
    });

    test('submitting the modal records the vote with the comment', () async {
      await bot.simulateModalSubmit(
        'poll_comment',
        submittedBy: voter,
        fields: const {'comment': 'great idea'},
      );

      expect(
        bot.actions.interactionReplies,
        contains(
          isInteractionReplied(
            content: 'Vote recorded with comment: "great idea".',
          ),
        ),
      );
    });
  });
}
