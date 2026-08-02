import 'package:mineral/src/api/common/commands/builder/command_declaration_builder.dart';
import 'package:mineral/src/api/common/commands/command_context_type.dart';
import 'package:mineral/src/domains/commands/command_registration.dart';

/// The shared shape every command builder must expose so
/// [CommandInteractionManagerContract.addCommand] and command registration
/// can operate on any implementer without an exhaustive type switch.
///
/// Implement this interface — and nothing else — to add a new command
/// builder type; no other part of the framework needs to learn about it.
abstract interface class CommandBuilder {
  /// The command's name, or `null` until it has been set.
  String? get name;

  /// Whether the command is registered globally or scoped to a single guild.
  CommandContextType get context;

  /// The Discord API payload for this command.
  Map<String, dynamic> toJson();

  /// The handler registrations (root command and/or dotted sub-command
  /// paths) this builder produces.
  List<CommandRegistration> reduceHandlers();

  /// The declarative option tree backing this command, used to discover
  /// autocomplete handlers.
  ///
  /// `null` for builders with no option tree to walk (user and message
  /// commands).
  CommandDeclarationBuilder? get declaration;
}
