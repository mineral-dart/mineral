import 'package:mineral/container.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral_test/mineral_test.dart';

/// Assigns the configured "Member" role to every newcomer if it exists.
final class AutoRoleListener extends OnMemberJoinListener {
  static const defaultRoleName = 'Member';

  @override
  Future<void> handle(TestMember member, TestGuild server) async {
    final logger = ioc.resolve<LoggerContract>();
    final dataStore = ioc.resolve<DataStoreContract>();

    // Look up the role through the in-memory data store.
    // (The simulator wires the same `BotActions` stream into the test data
    // store, so role assignments observed below are reflected in
    // `bot.dataStore.member(...)`.)
    final testStore = _seededRoleId(server);
    if (testStore == null) {
      logger.warn('AutoRoleListener: default role not configured');
      return;
    }

    await dataStore.role.add(
      memberId: member.id,
      guildId: server.id,
      roleId: testStore,
      reason: 'auto-role on join',
    );
  }

  /// Bots typically read the configured role from a database. For the test
  /// example, we look it up by name in a tiny static registry seeded by the
  /// test. Real bots would resolve this via their own provider.
  String? _seededRoleId(TestGuild server) =>
      AutoRoleConfig.roleIdsByGuild[server.id];
}

/// Static config seeded by tests — a stand-in for the bot's real
/// configuration provider.
class AutoRoleConfig {
  AutoRoleConfig._();

  static final Map<String, String> roleIdsByGuild = {};
}
