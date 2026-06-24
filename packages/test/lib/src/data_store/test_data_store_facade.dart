import '../payloads/test_payloads.dart';
import '../recorders/bot_actions.dart';
import '../recorders/recorded_action.dart';

/// In-memory data store exposed via `bot.dataStore`.
///
/// Two responsibilities:
///   * accept seed data via [seed]
///   * stay consistent with the observed REST traffic by listening to
///     [BotActions] (e.g. role assignments mutate the seeded member's roles)
///
/// This is intentionally separate from Mineral's runtime [DataStoreContract]
/// — that contract makes HTTP calls; this one is what tests assert against.
final class TestDataStoreFacade {
  final Map<String, TestGuild> _guilds = {};
  final Map<String, TestRole> _roles = {};
  final Map<String, TestChannel> _channels = {};

  /// Members keyed by composite (guildId|memberId).
  final Map<String, TestMember> _members = {};

  TestDataStoreFacade(BotActions actions) {
    actions.onAction(_apply);
  }

  void seed({
    List<TestGuild> guilds = const [],
    List<TestRole> roles = const [],
    List<TestChannel> channels = const [],
    List<TestMember> members = const [],
  }) {
    for (final g in guilds) {
      _guilds[g.id] = g;
    }
    for (final r in roles) {
      _roles[r.id] = r;
    }
    for (final c in channels) {
      _channels[c.id] = c;
    }
    for (final m in members) {
      _members[_memberKey(m.guildId, m.id)] = m;
    }
  }

  /// Returns the seeded member with the given id in the given guild.
  ///
  /// Throws [StateError] if the member is unknown — tests must seed before
  /// asserting.
  TestMember member(String id, {required TestGuild in_}) {
    final m = _members[_memberKey(in_.id, id)];
    if (m == null) {
      throw StateError('No seeded member with id "$id" in guild "${in_.id}"');
    }
    return m;
  }

  /// Returns every seeded member in the given guild.
  List<TestMember> members({required TestGuild in_}) {
    return _members.values
        .where((m) => m.guildId == in_.id)
        .toList(growable: false);
  }

  TestGuild? guild(String id) => _guilds[id];

  TestRole? role(String id) => _roles[id];

  TestChannel? channel(String id) => _channels[id];

  String _memberKey(String guildId, String memberId) => '$guildId|$memberId';

  void _apply(RecordedAction action) {
    switch (action) {
      case RoleAssigned():
        final key = _memberKey(action.guildId, action.memberId);
        final member = _members[key];
        final role = _roles[action.roleId];
        if (member != null && role != null && !member.roles.contains(role)) {
          _members[key] = TestMember(
            id: member.id,
            guildId: member.guildId,
            user: member.user,
            roles: [...member.roles, role],
            nickname: member.nickname,
          );
        }
      case RoleRemoved():
        final key = _memberKey(action.guildId, action.memberId);
        final member = _members[key];
        if (member != null) {
          _members[key] = TestMember(
            id: member.id,
            guildId: member.guildId,
            user: member.user,
            roles: member.roles.where((r) => r.id != action.roleId).toList(),
            nickname: member.nickname,
          );
        }
      case MemberBanned():
        _members.remove(_memberKey(action.guildId, action.memberId));
      case SentMessage():
      case InteractionReply():
      case ModalShown():
      case MessageEdited():
      case MessageDeleted():
        // No data store mutation for pure I/O actions.
        break;
    }
  }
}
