import 'dart:async';

import 'package:mineral/src/domains/commands/command_context.dart';
import 'package:mineral/src/domains/commands/command_options.dart';

typedef CommandHandler<T extends CommandContext> =
    FutureOr<void> Function(T context, CommandOptions options);
