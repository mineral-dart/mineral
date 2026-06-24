import 'package:mineral/api.dart';
import 'package:mineral/events.dart';

final class FeedbackButton extends GuildButtonClickEvent {
  @override
  String? get customId => 'open_feedback';

  @override
  Future<void> handle(GuildButtonContext ctx) async {
    final modal = ModalBuilder('submit_feedback')
      ..setTitle('Share your feedback')
      ..addText('All feedback is reviewed by the team.')
      ..addTextInput(
        customId: 'subject',
        label: 'Subject',
        placeholder: 'Brief summary of your feedback',
        maxLength: 100,
        isRequired: true,
      )
      ..addTextInput(
        customId: 'body',
        label: 'Details',
        style: TextInputStyle.paragraph,
        placeholder: 'Tell us more…',
        minLength: 10,
        maxLength: 1000,
        isRequired: true,
      )
      ..addTextInput(
        customId: 'email',
        label: 'Email (optional)',
        placeholder: 'If you want a follow-up',
        isRequired: false,
      );

    await ctx.interaction.modal(modal);
  }
}
