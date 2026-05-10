import 'package:mineral/src/api/common/commands/builder/user_command_builder.dart';
import 'package:mineral/src/api/common/commands/command_contract.dart';
import 'package:mineral/src/domains/common/utils/listenable.dart';

abstract interface class UserCommand
    implements CommandContract<UserCommandBuilder>, Listenable {
  @override
  UserCommandBuilder build();
}
