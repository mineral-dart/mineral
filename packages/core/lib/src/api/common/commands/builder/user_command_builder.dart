import 'package:mineral/src/api/common/commands/builder/translation.dart';
import 'package:mineral/src/api/common/commands/command_context_type.dart';
import 'package:mineral/src/api/common/commands/command_helper.dart';
import 'package:mineral/src/api/common/commands/command_kind.dart';
import 'package:mineral/src/domains/commands/command_builder.dart';
import 'package:mineral/src/domains/commands/command_handler.dart';
import 'package:mineral/src/domains/commands/contexts/user_command_context.dart';
import 'package:mineral/src/infrastructure/io/exceptions/command_name_exception.dart';
import 'package:mineral/src/infrastructure/io/exceptions/missing_property_exception.dart';

final class UserCommandBuilder implements CommandBuilder {
  final CommandHelper _helper = CommandHelper();

  String? name;
  Map<String, String>? _nameLocalizations;
  CommandContextType context = CommandContextType.server;
  CommandHandler<UserCommandContext>? handle;

  UserCommandBuilder setName(String name, {Translation? translation}) {
    if (name.isEmpty || name.length > 32) {
      throw CommandNameException(
          'User command name "$name" must be 1–32 characters long');
    }

    this.name = name;

    if (translation != null) {
      _nameLocalizations = _helper.extractTranslations('name', translation);
    }

    return this;
  }

  UserCommandBuilder setContext(CommandContextType context) {
    this.context = context;
    return this;
  }

  UserCommandBuilder setHandle(CommandHandler<UserCommandContext> fn) {
    handle = fn;
    return this;
  }

  Map<String, dynamic> toJson() {
    if (name == null) {
      throw MissingPropertyException('User command name is required');
    }

    return {
      'name': name,
      'name_localizations': _nameLocalizations,
      'type': CommandKind.user.value,
    };
  }
}
