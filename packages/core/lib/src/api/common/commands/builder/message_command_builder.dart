import 'package:mineral/src/api/common/commands/builder/translation.dart';
import 'package:mineral/src/api/common/commands/command_context_type.dart';
import 'package:mineral/src/api/common/commands/command_helper.dart';
import 'package:mineral/src/api/common/commands/command_kind.dart';
import 'package:mineral/src/domains/commands/command_builder.dart';
import 'package:mineral/src/domains/commands/command_handler.dart';
import 'package:mineral/src/domains/commands/contexts/message_command_context.dart';
import 'package:mineral/src/infrastructure/io/exceptions/command_name_exception.dart';
import 'package:mineral/src/infrastructure/io/exceptions/missing_property_exception.dart';

final class MessageCommandBuilder implements CommandBuilder {
  final CommandHelper _helper = CommandHelper();

  String? name;
  Map<String, String>? _nameLocalizations;
  CommandContextType context = CommandContextType.server;
  CommandHandler<MessageCommandContext>? handle;

  MessageCommandBuilder setName(String name, {Translation? translation}) {
    if (name.isEmpty || name.length > 32) {
      throw CommandNameException(
          'Message command name "$name" must be 1–32 characters long');
    }

    this.name = name;

    if (translation != null) {
      _nameLocalizations = _helper.extractTranslations('name', translation);
    }

    return this;
  }

  MessageCommandBuilder setContext(CommandContextType context) {
    this.context = context;
    return this;
  }

  MessageCommandBuilder setHandle(CommandHandler<MessageCommandContext> fn) {
    handle = fn;
    return this;
  }

  Map<String, dynamic> toJson() {
    if (name == null) {
      throw MissingPropertyException('Message command name is required');
    }

    return {
      'name': name,
      'name_localizations': _nameLocalizations,
      'type': CommandKind.message.value,
    };
  }
}
