import 'package:mineral/src/api/common/commands/builder/sub_command_builder.dart';
import 'package:mineral/src/api/common/commands/builder/translation.dart';
import 'package:mineral/src/api/common/commands/command_helper.dart';
import 'package:mineral/src/api/common/commands/command_type.dart';
import 'package:mineral/src/infrastructure/io/exceptions/missing_property_exception.dart';

final class CommandGroupBuilder {
  final CommandHelper _helper = CommandHelper();

  String? name;
  Map<String, String>? _nameLocalizations;
  String? _description;
  Map<String, String>? _descriptionLocalizations;
  final List<SubCommandBuilder> commands = [];

  CommandGroupBuilder();

  CommandGroupBuilder setName(String name, {Translation? translation}) {
    this.name = name;
    if (translation != null) {
      _nameLocalizations = _helper.extractTranslations('name', translation);
    }

    return this;
  }

  CommandGroupBuilder setDescription(
    String description, {
    Translation? translation,
  }) {
    _description = description;
    if (translation != null) {
      _descriptionLocalizations = _helper.extractTranslations(
        'description',
        translation,
      );
    }
    return this;
  }

  CommandGroupBuilder addSubCommand(void Function(SubCommandBuilder) command) {
    final builder = SubCommandBuilder();
    command(builder);
    commands.add(builder);
    return this;
  }

  Map<String, dynamic> toJson() {
    if (name == null) {
      throw MissingPropertyException('Command name is required');
    }

    if (_description == null) {
      throw MissingPropertyException('Command description is required');
    }

    return {
      'name': name,
      'name_localizations': _nameLocalizations,
      'description': _description,
      'description_localizations': _descriptionLocalizations,
      'type': CommandType.subCommandGroup.value,
      'options': commands.map((e) => e.toJson()).toList(),
    };
  }

  factory CommandGroupBuilder.fromJson(Map<String, dynamic> json) {
    final builder = CommandGroupBuilder()
      ..setName(json['name'] as String)
      ..setDescription(json['description'] as String);

    for (final command in json['commands'] as Iterable<dynamic>) {
      final commandMap = command as Map<String, dynamic>;
      builder.addSubCommand((builder) {
        builder
          ..setName(commandMap['name'] as String)
          ..setDescription(commandMap['description'] as String);
      });
    }

    return builder;
  }
}
