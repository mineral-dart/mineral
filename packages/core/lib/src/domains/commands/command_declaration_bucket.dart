import 'package:mineral/src/api/common/commands/builder/command_declaration_builder.dart';
import 'package:mineral/src/api/common/commands/builder/command_definition_builder.dart';
import 'package:mineral/src/domains/commands/command_context.dart';
import 'package:mineral/src/domains/commands/command_interaction_manager.dart';

final class CommandBucket {
  final CommandInteractionManagerContract _commands;

  CommandBucket(this._commands);

  void declare(Function(CommandDeclarationBuilder) fn) {
    final builder = CommandDeclarationBuilder();
    fn(builder);

    _commands.addCommand(builder);
  }

  void define<T extends CommandContext>(Function(CommandDefinitionBuilder) fn) {
    final builder = CommandDefinitionBuilder();
    fn(builder);

    _commands.addCommand(builder.command);
  }
}
