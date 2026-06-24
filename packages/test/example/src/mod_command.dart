import 'package:mineral/container.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral_test/mineral_test.dart';

/// `/mod ban user:<user> reason:<reason>` — bans the target if the caller is
/// authorized.
final class ModBanListener extends OnCommandListener {
  /// Set of moderator user-ids authorized to ban — provided by tests.
  final Set<String> moderatorIds;

  ModBanListener({required this.moderatorIds});

  @override
  String get command => 'mod.ban';

  @override
  Future<void> handle(CommandInvocation invocation) async {
    final dataStore = ioc.resolve<DataStoreContract>();

    if (!moderatorIds.contains(invocation.invokedBy.id)) {
      await TestInteractionResponder.reply(
        interactionId: invocation.interactionId,
        token: invocation.token,
        content: 'You are not allowed to run this command.',
        ephemeral: true,
      );
      return;
    }

    final target = invocation.options['user'];
    final reason = invocation.options['reason'] as String?;
    final guild = invocation.guild;

    if (target is! TestUser || guild == null) {
      await TestInteractionResponder.reply(
        interactionId: invocation.interactionId,
        token: invocation.token,
        content: 'Invalid arguments.',
        ephemeral: true,
      );
      return;
    }

    await dataStore.member.ban(
      guildId: guild.id,
      memberId: target.id,
      deleteSince: null,
      reason: reason,
    );

    await TestInteractionResponder.reply(
      interactionId: invocation.interactionId,
      token: invocation.token,
      content: 'Banned ${target.username}.',
    );
  }
}
