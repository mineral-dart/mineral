import 'dart:async';

import 'package:collection/collection.dart';
import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class CommandInteractionDispatcher
    implements InteractionDispatcherContract {
  @override
  InteractionType get type => InteractionType.applicationCommand;

  final MarshallerContract _marshaller;
  final DataStoreContract _dataStore;
  final EntityContext _ctx;
  final CommandInteractionManagerContract _interactionManager;

  CommandInteractionDispatcher(
    this._interactionManager, {
    required MarshallerContract marshaller,
    required DataStoreContract dataStore,
    required EntityContext ctx,
  })  : _marshaller = marshaller,
        _dataStore = dataStore,
        _ctx = ctx;

  @override
  Future<void> dispatch(Map<String, dynamic> data) async {
    await _handleCommand(data);
  }

  Future<void> _handleGroups(
      Map<String, dynamic> data, Map<String, dynamic> group) async {
    data['data']['options'] = group['options'];
    return _handleSubCommand(data, group);
  }

  Future<void> _handleSubCommand(
      Map<String, dynamic> data, Map<String, dynamic> option) async {
    data['data']['name'] = "${data['data']['name']}.${option['name']}";
    data['data']['options'] = option['options'];

    return _handleCommand(data);
  }

  Future<void> _handleCommand(Map<String, dynamic> data) async {
    final rawData = data['data'];
    if (rawData is! Map<String, dynamic>) {
      _marshaller.logger
          .warn('Malformed interaction payload: data.data is not a Map');
      return;
    }
    final dataData = rawData;

    final kind = CommandKind.of(dataData['type'] as int? ?? 1);
    if (kind == CommandKind.user || kind == CommandKind.message) {
      return _handleContextMenu(data, kind);
    }

    if (dataData['options'] != null) {
      for (final option in dataData['options'] as Iterable<dynamic>) {
        if (option is! Map<String, dynamic>) {
          _marshaller.logger.warn(
              'Unexpected option format: expected Map, got ${option.runtimeType}');
          continue;
        }
        final opt = option;
        final type = CommandType.values
            .firstWhereOrNull((e) => e.value == opt['type']);

        if (type == null) {
          continue;
        }

        return switch (type) {
          CommandType.subCommand => await _handleSubCommand(data, opt),
          CommandType.subCommandGroup => await _handleGroups(data, opt),
          CommandType.unknown => null,
        };
      }
    }

    final registration = _interactionManager.commandsHandler
        .firstWhereOrNull((reg) => reg.name == dataData['name']);

    if (registration == null) {
      _marshaller.logger
          .warn('Unknown command received: "${dataData['name']}"');
      return;
    }

    final guildId = Snowflake.nullable(dataData['guild_id'] as String?);
    final commandContext = await switch (guildId) {
      String() =>
        GuildCommandContext.fromMap(_marshaller, _dataStore, _ctx, data),
      _ => GlobalCommandContext.fromMap(_marshaller, _dataStore, _ctx, data),
    };

    final Map<String, dynamic> optionValues = {};

    if (dataData['options'] != null) {
      for (final option in dataData['options'] as Iterable<dynamic>) {
        if (option is! Map<String, dynamic>) {
          _marshaller.logger.warn(
              'Unexpected option format: expected Map, got ${option.runtimeType}');
          continue;
        }
        final opt = option;
        final type = CommandOptionType.values
            .firstWhereOrNull((e) => e.value == opt['type']);

        if (type == null) {
          _marshaller.logger.warn("Unknown option type: ${opt['type']}");
          continue;
        }

        optionValues[opt['name'] as String] = await switch (type) {
          CommandOptionType.user => switch (commandContext) {
              GuildCommandContext() => _dataStore.member
                  .get(commandContext.guild.id.value, opt['value'] as String, false),
              _ => _dataStore.user.get(opt['value'] as String, false),
            },
          CommandOptionType.channel =>
            _dataStore.channel.get(opt['value'] as String, false),
          CommandOptionType.role => switch (data['guild_id'] as String?) {
              final String gid =>
                _dataStore.role.get(gid, opt['value'] as String, false),
              null => null,
            },
          _ => opt['value'],
        };
      }
    }

    for (final declared in registration.declaredOptions) {
      if (declared.isRequired && !optionValues.containsKey(declared.name)) {
        _marshaller.logger.error(
            'Command "${registration.name}" requires option "${declared.name}" '
            'but it was not provided in the payload');
        return;
      }
    }

    await _invokeHandler(registration, commandContext, optionValues);
  }

  Future<void> _handleContextMenu(
      Map<String, dynamic> data, CommandKind kind) async {
    final dataData = data['data'] as Map<String, dynamic>;

    final registration = _interactionManager.commandsHandler
        .firstWhereOrNull((reg) => reg.name == dataData['name']);

    if (registration == null) {
      _marshaller.logger.warn(
          'Unknown ${kind.name} context command received: "${dataData['name']}"');
      return;
    }

    final commandContext = await switch (kind) {
      CommandKind.user =>
        UserCommandContext.fromMap(_marshaller, _dataStore, _ctx, data),
      CommandKind.message =>
        MessageCommandContext.fromMap(_marshaller, _dataStore, _ctx, data),
      _ => throw StateError('unreachable'),
    };

    await _invokeHandler(registration, commandContext, const {});
  }

  Future<void> _invokeHandler(CommandRegistration registration,
      CommandContext commandContext, Map<String, dynamic> optionValues) async {
    try {
      await registration.handler(commandContext, CommandOptions(optionValues));
    } on Exception catch (e, stackTrace) {
      final failure = CommandFailure(
        commandName: registration.name,
        error: e,
        stackTrace: stackTrace,
      );
      _marshaller.logger
          .error('Failed to execute command handler "${registration.name}"');
      _marshaller.logger.error('$e');
      _marshaller.logger.trace('$stackTrace');
      _interactionManager.onCommandError?.call(failure);
      // ignore: avoid_catching_errors, crash-safety boundary for command handlers
    } on Error catch (e, stackTrace) {
      final failure = CommandFailure(
        commandName: registration.name,
        error: e,
        stackTrace: stackTrace,
      );

      _marshaller.logger
          .error('Failed to execute command handler "${registration.name}"');
      _marshaller.logger.error('$e');
      _marshaller.logger.trace('$stackTrace');

      _interactionManager.onCommandError?.call(failure);
    }
  }
}
