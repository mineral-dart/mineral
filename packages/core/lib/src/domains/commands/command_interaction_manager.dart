import 'dart:async';

import 'package:mineral/contracts.dart';
import 'package:mineral/src/api/common/bot/bot.dart';
import 'package:mineral/src/api/common/commands/builder/command_declaration_builder.dart';
import 'package:mineral/src/api/common/commands/builder/command_definition_builder.dart';
import 'package:mineral/src/api/common/commands/builder/message_command_builder.dart';
import 'package:mineral/src/api/common/commands/builder/user_command_builder.dart';
import 'package:mineral/src/api/common/commands/command_context_type.dart';
import 'package:mineral/src/api/common/commands/command_option.dart';
import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/api/guild/guild.dart';
import 'package:mineral/src/domains/commands/command_builder.dart';
import 'package:mineral/src/domains/commands/command_interaction_dispatcher.dart';
import 'package:mineral/src/domains/commands/command_registration.dart';
import 'package:mineral/src/domains/commands/command_result.dart';
import 'package:mineral/src/domains/commands/contexts/autocomplete_context.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/infrastructure/io/exceptions/invalid_command_exception.dart';
import 'package:mineral/src/infrastructure/io/exceptions/missing_property_exception.dart';
import 'package:mineral/src/infrastructure/services/http/request.dart';
import 'package:mineral/src/infrastructure/services/http/response.dart';

abstract class CommandInteractionManagerContract {
  final List<CommandRegistration> commandsHandler = [];
  final List<CommandBuilder> commands = [];
  late InteractionDispatcherContract dispatcher;
  void Function(CommandFailure failure)? onCommandError;

  Future<void> registerGlobal(Bot bot);

  Future<void> registerServer(Bot bot, Guild guild);

  void addCommand(CommandBuilder command);

  Future<void> handleAutocomplete(Map<String, dynamic> payload);
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

  late final MarshallerContract _marshaller;

  /// Registry: root command name → option name → handler.
  final Map<String, Map<String, AutocompleteHandler>> _autocompleteHandlers =
      {};

  CommandInteractionManager._();

  factory CommandInteractionManager({
    required DataStoreContract dataStore,
    required MarshallerContract marshaller,
    required EntityContext ctx,
  }) {
    final manager = CommandInteractionManager._()
      .._dataStoreRef = dataStore
      .._marshaller = marshaller;
    manager.dispatcher = CommandInteractionDispatcher(
      manager,
      marshaller: marshaller,
      dataStore: dataStore,
      ctx: ctx,
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
      final _ => throw InvalidCommandException('Unknown command type'),
    };

    if (name == null) {
      throw MissingPropertyException('Command name is required');
    }

    final handlers = switch (command) {
      final CommandDeclarationBuilder command => command.reduceHandlers(
        command.name!,
      ),
      final CommandDefinitionBuilder definition =>
        definition.command.reduceHandlers(definition.command.name!),
      final UserCommandBuilder b => [
        if (b.handle != null)
          CommandRegistration(
            name: b.name!,
            handler: b.handle!,
            declaredOptions: const [],
          )
        else
          throw InvalidCommandException(
            'User command "${b.name}" has no handler',
          ),
      ],
      final MessageCommandBuilder b => [
        if (b.handle != null)
          CommandRegistration(
            name: b.name!,
            handler: b.handle!,
            declaredOptions: const [],
          )
        else
          throw InvalidCommandException(
            'Message command "${b.name}" has no handler',
          ),
      ],
      final _ => throw InvalidCommandException('Unknown command type'),
    };

    commands.add(command);
    commandsHandler.addAll(handlers);

    // Collect autocomplete handlers from option trees.
    _registerAutocompleteHandlers(name, command);
  }

  /// Walks the command's option tree and registers any [AutocompleteHandler]s.
  void _registerAutocompleteHandlers(String rootName, CommandBuilder command) {
    final declaration = switch (command) {
      final CommandDeclarationBuilder b => b,
      final CommandDefinitionBuilder d => d.command,
      _ => null,
    };

    if (declaration == null) {
      return;
    }

    final handlers = _autocompleteHandlers.putIfAbsent(rootName, () => {});

    // Top-level options.
    for (final option in declaration.options) {
      _collectFromOption(option, handlers);
    }

    // Sub-commands.
    for (final sub in declaration.subCommands) {
      for (final option in sub.options) {
        _collectFromOption(option, handlers);
      }
    }

    // Groups → sub-commands.
    for (final group in declaration.groups) {
      for (final sub in group.commands) {
        for (final option in sub.options) {
          _collectFromOption(option, handlers);
        }
      }
    }
  }

  void _collectFromOption(
    CommandOption option,
    Map<String, AutocompleteHandler> handlers,
  ) {
    if (option is Option &&
        option.autocomplete &&
        option.onAutocomplete != null) {
      handlers[option.name] = option.onAutocomplete!;
    }
  }

  @override
  Future<void> handleAutocomplete(Map<String, dynamic> payload) async {
    final data = payload['data'] as Map<String, dynamic>?;
    if (data == null) {
      _marshaller.logger.warn('Autocomplete payload missing "data" field');
      return;
    }

    final rootName = data['name'] as String?;
    if (rootName == null) {
      _marshaller.logger.warn('Autocomplete payload missing command name');
      return;
    }

    final rawOptions = data['options'];
    if (rawOptions == null) {
      _marshaller.logger.warn('Autocomplete payload has no options');
      return;
    }

    // Find focused option recursively.
    final focused = _findFocused(rawOptions as Iterable<dynamic>);
    if (focused == null) {
      _marshaller.logger.warn(
        'No focused option found in autocomplete payload',
      );
      return;
    }

    final optionName = focused['name'] as String;
    final optionValue = '${focused['value'] ?? ''}';

    // Collect other options (non-focused).
    final otherOptions = <String, dynamic>{};
    _collectNonFocused(rawOptions, otherOptions);

    // Look up handler.
    final commandHandlers = _autocompleteHandlers[rootName];
    final handler = commandHandlers?[optionName];
    if (handler == null) {
      _marshaller.logger.warn(
        'No autocomplete handler for command "$rootName" option "$optionName"',
      );
      return;
    }

    final ctx = AutocompleteContext(
      name: optionName,
      value: optionValue,
      options: otherOptions,
    );

    final choices = await handler(ctx);
    // Discord allows max 25 choices.
    final capped = choices.length > 25 ? choices.take(25).toList() : choices;

    final id = Snowflake.parse(payload['id'] as String);
    final token = payload['token'] as String;

    await _dataStore.interaction.sendAutocompleteResult(id, token, capped);
  }

  /// Recurses into options to find the one with `focused == true`.
  Map<String, dynamic>? _findFocused(Iterable<dynamic> options) {
    for (final raw in options) {
      if (raw is! Map<String, dynamic>) {
        continue;
      }
      if (raw['focused'] == true) {
        return raw;
      }
      // Sub-commands nest their own options list.
      final nested = raw['options'];
      if (nested != null) {
        final result = _findFocused(nested as Iterable<dynamic>);
        if (result != null) {
          return result;
        }
      }
    }
    return null;
  }

  /// Collects name→value for all non-focused options at any depth.
  void _collectNonFocused(Iterable<dynamic> options, Map<String, dynamic> out) {
    for (final raw in options) {
      if (raw is! Map<String, dynamic>) {
        continue;
      }
      if (raw['focused'] != true) {
        final name = raw['name'] as String?;
        if (name != null && raw.containsKey('value')) {
          out[name] = raw['value'];
        }
      }
      final nested = raw['options'];
      if (nested != null) {
        _collectNonFocused(nested as Iterable<dynamic>, out);
      }
    }
  }

  @override
  Future<void> registerGlobal(Bot bot) async {
    final List<CommandBuilder> globalCommands = _getContext(
      CommandContextType.global,
    );
    final payload = _serializeCommand(globalCommands);

    final req = Request.json(
      endpoint: '/applications/${bot.id}/commands',
      body: payload,
    );

    // Routed through the rate-limit bucket (not `_dataStore.client`
    // directly) so backoff and bucket accounting apply, and any non-success
    // status raises instead of completing as a silent success (#470).
    await _dataStore.requestBucket.put<dynamic>(
      req,
      onError: (response) =>
          _registrationFailure(response, scope: 'application ${bot.id}'),
    );
  }

  @override
  Future<void> registerServer(Bot bot, Guild guild) async {
    final List<CommandBuilder> guildCommands = _getContext(
      CommandContextType.guild,
    );
    final payload = _serializeCommand(guildCommands);

    final req = Request.json(
      endpoint: '/applications/${bot.id}/guilds/${guild.id}/commands',
      body: payload,
    );

    // `registerServer` runs once per GUILD_CREATE, so a bot in N guilds
    // fires N PUTs at startup: routing through the bucket (instead of
    // `_dataStore.client` directly) throttles that burst, and any
    // non-success status (401/403/429/5xx — not just 400) raises instead of
    // completing as a silent success (#470).
    await _dataStore.requestBucket.put<dynamic>(
      req,
      onError: (response) =>
          _registrationFailure(response, scope: 'guild ${guild.id}'),
    );
  }

  /// Builds the exception raised when Discord rejects a command-registration
  /// PUT, whatever the status: 400 (invalid payload), 401 (bad token), 403
  /// (missing `applications.commands` scope), 429 (rate limited — bucket
  /// retry budget exhausted), or a 5xx. Discord's 400 responses carry a
  /// structured `errors` object; when present, the first nested `_errors`
  /// entry is surfaced verbatim for a precise diagnostic. Every other status
  /// falls back to the raw status, body and scope (application or guild) so
  /// the failure is never silent (#470).
  InvalidCommandException _registrationFailure(
    Response response, {
    required String scope,
  }) {
    final detail = _extractValidationDetail(response.body) ?? response.bodyString;

    return InvalidCommandException(
      'Command registration failed for $scope '
      '(status ${response.statusCode}): $detail',
    );
  }

  /// Extracts Discord's structured `{code, message}` validation detail from
  /// a 400 response body, if present. Returns `null` for any other shape
  /// (including every other error status) instead of throwing, so callers
  /// can fall back to the raw body.
  String? _extractValidationDetail(Object? body) {
    if (body is! Map) {
      return null;
    }

    final errors = body['errors'];
    if (errors is! Map) {
      return null;
    }

    final firstField = Map<String, dynamic>.from(errors).values.firstOrNull;
    if (firstField is! Map) {
      return null;
    }

    final nameField = firstField['name'];
    final nestedErrors = nameField is Map ? nameField['_errors'] : null;
    if (nestedErrors is! Iterable) {
      return null;
    }

    final first = nestedErrors.cast<dynamic>().firstOrNull;
    if (first is! Map) {
      return null;
    }

    return '${first['code']}: ${first['message']}';
  }

  List<CommandBuilder> _getContext(CommandContextType contextType) {
    return commands.where((command) {
      final context = switch (command) {
        final CommandDeclarationBuilder command => command.context,
        final CommandDefinitionBuilder definition => definition.command.context,
        final UserCommandBuilder b => b.context,
        final MessageCommandBuilder b => b.context,
        final _ => throw InvalidCommandException('Unknown command type'),
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
        final _ => throw InvalidCommandException('Unknown command type'),
      };
    }).toList();
  }
}
