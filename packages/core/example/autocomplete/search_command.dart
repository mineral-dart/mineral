import 'dart:async';

import 'package:mineral/api.dart';

/// Demonstrates slash command option **autocomplete**.
///
/// As the user types, Discord calls [_complete] and we return up to 25
/// [Choice]s filtered by what they have typed so far ([AutocompleteContext.value]).
final class SearchCommand implements CommandDeclaration {
  static const _catalog = [
    'Apple',
    'Apricot',
    'Banana',
    'Blueberry',
    'Cherry',
    'Grapefruit',
    'Mango',
    'Orange',
    'Peach',
    'Pear',
  ];

  FutureOr<List<Choice>> _complete(AutocompleteContext ctx) {
    final query = ctx.value.toLowerCase();

    return _catalog
        .where((item) => item.toLowerCase().contains(query))
        .take(25)
        .map((item) => Choice(item, item))
        .toList();
  }

  Future<void> handle(GuildCommandContext ctx, CommandOptions options) async {
    final fruit = options.require<String>('fruit');

    await ctx.interaction.reply(
      builder: MessageBuilder.text('🔎 You picked **$fruit**.'),
      ephemeral: true,
    );
  }

  @override
  CommandDeclarationBuilder build() {
    return CommandDeclarationBuilder()
      ..setName('search')
      ..setDescription('Search the fruit catalog with autocomplete')
      ..addOption(
        Option.string(
          name: 'fruit',
          description: 'Start typing to see suggestions',
          required: true,
          autocomplete: true,
          onAutocomplete: _complete,
        ),
      )
      ..setHandle(handle);
  }
}
