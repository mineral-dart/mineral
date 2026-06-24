import 'package:mineral/api.dart';

/// Demonstrates the **soundboard** manager (`guild.soundboardSounds`).
final class SoundsCommand implements CommandDeclaration {
  Future<void> list(GuildCommandContext ctx, CommandOptions options) async {
    final sounds = await ctx.guild.soundboardSounds.fetch();

    if (sounds.isEmpty) {
      await ctx.interaction.reply(
        builder: MessageBuilder.text('🔊 This guild has no soundboard sounds.'),
        ephemeral: true,
      );
      return;
    }

    final lines = sounds.values
        .map((sound) => '• **${sound.name}**')
        .join('\n');

    await ctx.interaction.reply(
      builder: MessageBuilder.text('🔊 Soundboard sounds:\n$lines'),
      ephemeral: true,
    );
  }

  @override
  CommandDeclarationBuilder build() {
    return CommandDeclarationBuilder()
      ..setName('sounds')
      ..setDescription('Soundboard utilities')
      ..addSubCommand(
        (sub) => sub
          ..setName('list')
          ..setDescription('List the guild soundboard sounds')
          ..setHandle(list),
      );
  }
}
