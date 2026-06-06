import 'package:mineral/api.dart';

import 'feedback/feedback_provider.dart';
import 'global_states/vote_counter.dart';
import 'poll/poll_provider.dart';
import 'welcome/welcome_provider.dart';

// Run from `hmr` command, configuration available via `pubspec.yaml`
void main() async {
  final client = ClientBuilder()
      .setIntent(Intent.allNonPrivileged)
      .registerProvider(WelcomeProvider.new)
      .registerProvider(PollProvider.new)
      .registerProvider(FeedbackProvider.new)
      .build();

  client
    ..register<VoteCounterContract>(VoteCounter.new)
    ..onCommandError = (CommandFailure failure) {
      client.logger.error(
        'Command "${failure.commandName}" failed: ${failure.error}',
      );
    };

  await client.init();
}
