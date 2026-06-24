import 'package:mineral/api.dart';

/// Demonstrates the **guild scheduled events** manager (`guild.scheduledEvents`).
final class EventsCommand implements CommandDeclaration {
  Future<void> list(GuildCommandContext ctx, CommandOptions options) async {
    final events = await ctx.guild.scheduledEvents.fetch();

    if (events.isEmpty) {
      await ctx.interaction.reply(
        builder: MessageBuilder.text('📅 No scheduled events.'),
        ephemeral: true,
      );
      return;
    }

    final lines = events.values.map((event) => '• **${event.name}**').join('\n');

    await ctx.interaction.reply(
      builder: MessageBuilder.text('📅 Scheduled events:\n$lines'),
      ephemeral: true,
    );
  }

  @override
  CommandDeclarationBuilder build() {
    return CommandDeclarationBuilder()
      ..setName('events')
      ..setDescription('Manage scheduled events')
      ..addSubCommand((sub) => sub
        ..setName('list')
        ..setDescription('List the guild scheduled events')
        ..setHandle(list));
  }
}
