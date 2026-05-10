import 'dart:async';

import 'package:mineral/contracts.dart';
import 'package:mineral/src/api/common/bot/bot.dart';
import 'package:mineral/src/api/common/commands/builder/command_declaration_builder.dart';
import 'package:mineral/src/api/common/commands/builder/command_definition_builder.dart';
import 'package:mineral/src/api/common/commands/builder/message_command_builder.dart';
import 'package:mineral/src/api/common/commands/builder/user_command_builder.dart';
import 'package:mineral/src/api/common/commands/command_context_type.dart';
import 'package:mineral/src/api/server/server.dart';
import 'package:mineral/src/domains/commands/command_builder.dart';
import 'package:mineral/src/domains/commands/command_interaction_dispatcher.dart';
import 'package:mineral/src/domains/commands/command_registration.dart';
import 'package:mineral/src/domains/commands/command_result.dart';
import 'package:mineral/src/infrastructure/io/exceptions/invalid_command_exception.dart';
import 'package:mineral/src/infrastructure/io/exceptions/missing_property_exception.dart';
import 'package:mineral/src/infrastructure/services/http/request.dart';

abstract class CommandInteractionManagerContract {
  final List<CommandRegistration> commandsHandler = [];
  final List<CommandBuilder> commands = [];
  late InteractionDispatcherContract dispatcher;
  void Function(CommandFailure failure)? onCommandError;

  Future<void> registerGlobal(Bot bot);

  Future<void> registerServer(Bot bot, Server server);

  void addCommand(CommandBuilder command);
}

final class CommandInteractionManager
    implements CommandInteractionManagerContract {
  @override
  final List<CommandRegistration> commandsHandler = [];

  @override
  final List<CommandBuilder> commands = [];

  @override
  void Function(CommandFailure failure)? onCommandError;

  @override
  late InteractionDispatcherContract dispatcher;

  DataStoreContract get _dataStore => _dataStoreRef;
  late final DataStoreContract _dataStoreRef;

  CommandInteractionManager._();

  factory CommandInteractionManager({
    required DataStoreContract dataStore,
    required MarshallerContract marshaller,
  }) {
    final manager = CommandInteractionManager._();
    manager._dataStoreRef = dataStore;
    manager.dispatcher = CommandInteractionDispatcher(
      manager,
      marshaller: marshaller,
      dataStore: dataStore,
    );
    return manager;
  }

  @override
  void addCommand(CommandBuilder command) {
    if (commands.contains(command)) {
      throw InvalidCommandException('Command $command already exists');
    }

    final name = switch (command) {
      final CommandDeclarationBuilder command => command.name,
      final CommandDefinitionBuilder definition => definition.command.name,
      final UserCommandBuilder b => b.name,
      final MessageCommandBuilder b => b.name,
      final _ => throw InvalidCommandException('Unknown command type')
    };

    if (name == null) {
      throw MissingPropertyException('Command name is required');
    }

    final handlers = switch (command) {
      final CommandDeclarationBuilder command =>
        command.reduceHandlers(command.name!),
      final CommandDefinitionBuilder definition =>
        definition.command.reduceHandlers(definition.command.name!),
      final UserCommandBuilder b => [
          if (b.handle != null)
            CommandRegistration(
                name: b.name!, handler: b.handle!, declaredOptions: const [])
          else
            throw InvalidCommandException(
                'User command "${b.name}" has no handler')
        ],
      final MessageCommandBuilder b => [
          if (b.handle != null)
            CommandRegistration(
                name: b.name!, handler: b.handle!, declaredOptions: const [])
          else
            throw InvalidCommandException(
                'Message command "${b.name}" has no handler')
        ],
      final _ => throw InvalidCommandException('Unknown command type')
    };

    commands.add(command);
    commandsHandler.addAll(handlers);
  }

  @override
  Future<void> registerGlobal(Bot bot) async {
    final List<CommandBuilder> globalCommands =
        _getContext(CommandContextType.global);
    final payload = _serializeCommand(globalCommands);

    final req = Request.json(
        endpoint: '/applications/${bot.id}/commands', body: payload);
    await _dataStore.client.put(req);
  }

  @override
  Future<void> registerServer(Bot bot, Server server) async {
    final List<CommandBuilder> guildCommands =
        _getContext(CommandContextType.server);
    final payload = _serializeCommand(guildCommands);

    final req = Request.json(
        endpoint: '/applications/${bot.id}/guilds/${server.id}/commands',
        body: payload);

    final response = await _dataStore.client.put(req);
    if (response.statusCode == 400) {
      final error = Map<String, dynamic>.from(response.body['errors'] as Map<dynamic, dynamic>)
          .values
          .firstOrNull?['name'];

      final errors = List.from(error?['_errors'] as Iterable<dynamic>? ?? []).firstOrNull;

      throw InvalidCommandException('${errors['code']}: ${errors['message']}');
    }
  }

  List<CommandBuilder> _getContext(CommandContextType contextType) {
    return commands.where((command) {
      final context = switch (command) {
        final CommandDeclarationBuilder command => command.context,
        final CommandDefinitionBuilder definition => definition.command.context,
        final UserCommandBuilder b => b.context,
        final MessageCommandBuilder b => b.context,
        final _ => throw InvalidCommandException('Unknown command type')
      };

      return context == contextType;
    }).toList();
  }

  List<Map<String, dynamic>> _serializeCommand(List<CommandBuilder> commands) {
    return commands.map((command) {
      return switch (command) {
        final CommandDeclarationBuilder command => command.toJson(),
        final CommandDefinitionBuilder definition =>
          definition.command.toJson(),
        final UserCommandBuilder b => b.toJson(),
        final MessageCommandBuilder b => b.toJson(),
        final _ => throw InvalidCommandException('Unknown command type')
      };
    }).toList();
  }
}
