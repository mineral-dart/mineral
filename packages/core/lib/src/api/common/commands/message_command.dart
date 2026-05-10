import 'package:mineral/src/api/common/commands/builder/message_command_builder.dart';
import 'package:mineral/src/api/common/commands/command_contract.dart';
import 'package:mineral/src/domains/common/utils/listenable.dart';

abstract interface class MessageCommand
    implements CommandContract<MessageCommandBuilder>, Listenable {
  @override
  MessageCommandBuilder build();
}
