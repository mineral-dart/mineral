import 'package:mineral/api.dart';

final class PollCommand implements CommandDeclaration {
  Future<void> create(GuildCommandContext ctx, CommandOptions options) async {
    final question = options.require<String>('question');

    final message = MessageBuilder.text('📊 **Poll:** $question')
      ..addButtons([
        Button.success('poll_vote:yes', label: 'Yes'),
        Button.danger('poll_vote:no', label: 'No'),
        Button.secondary('poll_results', label: 'See results'),
      ]);

    await ctx.interaction.reply(builder: message);
  }

  Future<void> end(GuildCommandContext ctx, CommandOptions options) async {
    await ctx.interaction.reply(
      builder: MessageBuilder.text('🔒 The poll has been closed.'),
      ephemeral: true,
    );
  }

  @override
  CommandDeclarationBuilder build() {
    return CommandDeclarationBuilder()
      ..setName('poll')
      ..setDescription('Manage polls in this channel')
      ..addSubCommand(
        (sub) => sub
          ..setName('create')
          ..setDescription('Start a new poll')
          ..addOption(
            Option.string(
              name: 'question',
              description: 'The question to ask',
              required: true,
            ),
          )
          ..setHandle(create),
      )
      ..addSubCommand(
        (sub) => sub
          ..setName('end')
          ..setDescription('Close the active poll')
          ..setHandle(end),
      );
  }
}
