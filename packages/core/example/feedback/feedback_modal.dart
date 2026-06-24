import 'package:mineral/api.dart';
import 'package:mineral/container.dart';
import 'package:mineral/events.dart';

final class FeedbackModal extends GuildModalSubmitEvent<Map<String, String>>
    with Logger {
  @override
  String? get customId => 'submit_feedback';

  @override
  Future<void> handle(
      GuildModalContext ctx, Map<String, String> data) async {
    final subject = data['subject'] ?? '(no subject)';
    final body = data['body'] ?? '';
    final email = data['email'];

    logger.info(
      'Feedback from ${ctx.member.username}: [$subject] $body'
      '${email != null && email.isNotEmpty ? ' (reply to: $email)' : ''}',
    );

    await ctx.interaction.reply(
      builder: MessageBuilder.text(
        '✅ Thanks for your feedback on **$subject**! The team will review it shortly.',
      ),
      ephemeral: true,
    );
  }
}
