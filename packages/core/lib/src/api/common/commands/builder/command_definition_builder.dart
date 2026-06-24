import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/api/common/commands/builder/command_declaration_builder.dart';
import 'package:mineral/src/api/common/commands/builder/sub_command_builder.dart';
import 'package:mineral/src/api/common/commands/builder/translation.dart';
import 'package:mineral/src/api/common/commands/command_choice_option.dart';
import 'package:mineral/src/api/common/commands/command_option.dart';
import 'package:mineral/src/api/common/lang.dart';
import 'package:mineral/src/domains/commands/command_builder.dart';
import 'package:mineral/src/domains/commands/command_context.dart';
import 'package:mineral/src/domains/commands/command_handler.dart';
import 'package:mineral/src/infrastructure/io/exceptions/invalid_command_exception.dart';
import 'package:yaml/yaml.dart';

final class CommandDefinitionBuilder implements CommandBuilder {
  final String _defaultIdentifier = '_default';

  final Map<String, dynamic Function()> _commandMapper = {};
  final CommandDeclarationBuilder command = CommandDeclarationBuilder();

  String _extractDefaultValue(
    String commandKey,
    String key,
    Map<String, dynamic> payload,
  ) {
    final Map<String, dynamic>? elements =
        payload[key] as Map<String, dynamic>?;
    if (elements == null) {
      throw InvalidCommandException('Missing "$key" key under $commandKey');
    }

    if (elements[_defaultIdentifier] case final String value) {
      return value;
    }

    throw InvalidCommandException(
      'Missing "$key.$_defaultIdentifier" key under $commandKey struct',
    );
  }

  Map<Lang, String> _extractTranslations(
    String key,
    Map<String, dynamic> payload,
  ) {
    final Map<String, dynamic>? elements =
        payload[key] as Map<String, dynamic>?;
    if (elements == null) {
      throw InvalidCommandException('Missing "$key" key');
    }

    return elements.entries
        .whereNot((element) => element.key == _defaultIdentifier)
        .fold({}, (acc, element) {
          final lang = Lang.values.firstWhere(
            (lang) => lang.uid == element.key,
          );
          return {...acc, lang: element.value as String};
        });
  }

  void _declareGroups(Map<String, dynamic> content) {
    final Map<String, dynamic> groupList =
        content['groups'] as Map<String, dynamic>? ?? {};

    for (final element in groupList.entries) {
      final elementValue = element.value as Map<String, dynamic>;
      final String defaultName = _extractDefaultValue(
        element.key,
        'name',
        elementValue,
      );
      final String defaultDescription = _extractDefaultValue(
        element.key,
        'description',
        elementValue,
      );

      final nameTranslations = _extractTranslations('name', elementValue);
      final descriptionTranslations = _extractTranslations(
        'description',
        elementValue,
      );

      command.createGroup((group) {
        return group
          ..setName(
            defaultName,
            translation: Translation({'name': nameTranslations}),
          )
          ..setDescription(
            defaultDescription,
            translation: Translation({'name': descriptionTranslations}),
          );
      });
    }
  }

  List<CommandOption> _declareOptions(MapEntry<String, dynamic> element) {
    final elementValue = element.value as Map<String, dynamic>;
    final options = List<Map<String, dynamic>>.from(
      elementValue['options'] as Iterable<dynamic>? ?? [],
    );

    return options.fold([], (acc, Map<String, dynamic> element) {
      final String name = _extractDefaultValue('option', 'name', element);
      final String description = _extractDefaultValue(
        'option',
        'description',
        element,
      );
      final bool required = element['required'] as bool? ?? false;

      final option = switch (element['type']) {
        final String value when value == 'string' => Option.string(
          name: name,
          description: description,
          required: required,
        ),
        final String value when value == 'integer' => Option.integer(
          name: name,
          description: description,
          required: required,
        ),
        final String value when value == 'double' => Option.double(
          name: name,
          description: description,
          required: required,
        ),
        final String value when value == 'string' => Option.boolean(
          name: name,
          description: description,
          required: required,
        ),
        final String value when value == 'user' => Option.user(
          name: name,
          description: description,
          required: required,
        ),
        final String value when value == 'channel' => Option.channel(
          name: name,
          description: description,
          required: required,
        ),
        final String value when value == 'role' => Option.role(
          name: name,
          description: description,
          required: required,
        ),
        final String value when value == 'mention' => Option.mentionable(
          name: name,
          description: description,
          required: required,
        ),
        final String value when value == 'choice.string' => ChoiceOption.string(
          name: name,
          description: description,
          required: required,
          choices: List.from(element['choices'] as Iterable<dynamic>? ?? [])
              .map(
                (element) => Choice<String>(
                  (element as Map<String, dynamic>)['name'] as String,
                  element['value'] as String,
                ),
              )
              .toList(),
        ),
        final String value when value == 'choice.integer' =>
          ChoiceOption.integer(
            name: name,
            description: description,
            required: required,
            choices: List.from(element['choices'] as Iterable<dynamic>? ?? [])
                .map(
                  (element) => Choice(
                    (element as Map<String, dynamic>)['name'] as String,
                    int.parse(element['value'] as String),
                  ),
                )
                .toList(),
          ),
        final String value when value == 'choice.double' => ChoiceOption.double(
          name: name,
          description: description,
          required: required,
          choices: List.from(element['choices'] as Iterable<dynamic>? ?? [])
              .map(
                (element) => Choice(
                  (element as Map<String, dynamic>)['name'] as String,
                  double.parse(element['value'] as String),
                ),
              )
              .toList(),
        ),
        _ => throw InvalidCommandException('Unknown option type'),
      };

      return [...acc, option];
    });
  }

  void _declareSubCommands(Map<String, dynamic> content) {
    final Map<String, dynamic> commandList =
        content['commands'] as Map<String, dynamic>? ?? {};

    for (final element in commandList.entries) {
      if (element.key.contains('.')) {
        final elementValue = element.value as Map<String, dynamic>;
        final String defaultName = _extractDefaultValue(
          element.key,
          'name',
          elementValue,
        );
        final String defaultDescription = _extractDefaultValue(
          element.key,
          'description',
          elementValue,
        );

        final nameTranslations = _extractTranslations('name', elementValue);
        final descriptionTranslations = _extractTranslations(
          'description',
          elementValue,
        );

        if (elementValue['group'] case final String group) {
          final currentGroup =
              command.groups.firstWhere((element) => element.name == group)
                ..addSubCommand((command) {
                  command
                    ..setName(
                      defaultName,
                      translation: Translation({'name': nameTranslations}),
                    )
                    ..setDescription(
                      defaultDescription,
                      translation: Translation({
                        'description': descriptionTranslations,
                      }),
                    );

                  command.options.addAll(_declareOptions(element));
                });

          final int currentGroupIndex = command.groups.indexOf(currentGroup);
          final int currentSubCommandIndex = currentGroup.commands.indexOf(
            currentGroup.commands.last,
          );
          _commandMapper[element.key] = () => command
              .groups[currentGroupIndex]
              .commands[currentSubCommandIndex];
        } else {
          command.addSubCommand((command) {
            command
              ..setName(
                defaultName,
                translation: Translation({'name': nameTranslations}),
              )
              ..setDescription(
                defaultDescription,
                translation: Translation({
                  'description': descriptionTranslations,
                }),
              );

            command.options.addAll(_declareOptions(element));
          });
          final currentSubCommandIndex = command.subCommands.indexOf(
            command.subCommands.last,
          );
          _commandMapper[element.key] = () =>
              command.subCommands[currentSubCommandIndex];
        }
      }
    }
  }

  void _declareCommand(Map<String, dynamic> content) {
    final Map<String, dynamic> commandList =
        content['commands'] as Map<String, dynamic>? ?? {};

    for (final element in commandList.entries) {
      if (!element.key.contains('.')) {
        final elementValue = element.value as Map<String, dynamic>;
        final String defaultName = _extractDefaultValue(
          element.key,
          'name',
          elementValue,
        );
        final String defaultDescription = _extractDefaultValue(
          element.key,
          'description',
          elementValue,
        );

        final nameTranslations = _extractTranslations('name', elementValue);
        final descriptionTranslations = _extractTranslations(
          'description',
          elementValue,
        );

        command
          ..setName(
            defaultName,
            translation: Translation({'name': nameTranslations}),
          )
          ..setDescription(
            defaultDescription,
            translation: Translation({'description': descriptionTranslations}),
          );

        command.options.addAll(_declareOptions(element));

        _commandMapper[element.key] = () => command;
      }
    }
  }

  void context<T>(String key, Function(T) fn) {
    final command = _commandMapper.entries.firstWhere(
      (element) => element.key == key,
    );
    fn(command.value() as T);
  }

  void setHandler<T extends CommandContext>(String key, CommandHandler<T> fn) {
    final command = _commandMapper.entries.firstWhere(
      (element) => element.key == key,
    );

    switch (command.value()) {
      case final SubCommandBuilder command:
        command.setHandle(fn);
      case final CommandDeclarationBuilder command:
        command.setHandle(fn);
    }
  }

  void using(File file, {PlaceholderContract? placeholder}) {
    final String stringContent = file.readAsStringSync();
    final content = switch (placeholder) {
      PlaceholderContract(:final apply) => apply(stringContent),
      _ => stringContent,
    };

    final payload = switch (file.path) {
      final String path when path.contains('.json') =>
        json.decode(content) as Map<String, dynamic>,
      final String path when path.contains('.yaml') =>
        loadYaml(content).toMap() as Map<String, dynamic>,
      final String path when path.contains('.yml') =>
        loadYaml(content).toMap() as Map<String, dynamic>,
      _ => throw InvalidCommandException('File type not supported'),
    };

    _declareCommand(payload);
    _declareGroups(payload);
    _declareSubCommands(payload);
  }
}
