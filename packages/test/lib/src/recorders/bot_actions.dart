import 'recorded_action.dart';

/// Aggregated, human-readable view of every side-effect a Mineral bot has
/// produced during a test. Exposed via `bot.actions`.
///
/// ```dart
/// expect(
///   bot.actions.interactionReplies,
///   contains(isInteractionReplied(content: 'pong')),
/// );
/// ```
final class BotActions {
  final List<RecordedAction> _all = [];
  final List<void Function(RecordedAction)> _listeners = [];

  /// Every recorded action, in chronological order.
  List<RecordedAction> get all => List.unmodifiable(_all);

  /// Registers a listener invoked synchronously after each record.
  ///
  /// Internal callers (the data store façade) use this to keep their state
  /// in sync with observed Discord side-effects.
  void onAction(void Function(RecordedAction) listener) {
    _listeners.add(listener);
  }

  /// Messages sent into a channel via `channel.send(...)`.
  List<SentMessage> get sentMessages => _all.whereType<SentMessage>().toList();

  /// Replies produced by slash commands or component handlers.
  List<InteractionReply> get interactionReplies =>
      _all.whereType<InteractionReply>().toList();

  /// Modals opened in response to an interaction.
  List<ModalShown> get modals => _all.whereType<ModalShown>().toList();

  /// Bans produced by `guild.members.ban(...)`.
  List<MemberBanned> get bans => _all.whereType<MemberBanned>().toList();

  /// Role assignments produced by `member.roles.add(...)`.
  List<RoleAssigned> get roleAssignments =>
      _all.whereType<RoleAssigned>().toList();

  /// Role removals produced by `member.roles.remove(...)`.
  List<RoleRemoved> get roleRemovals => _all.whereType<RoleRemoved>().toList();

  /// Message edits produced by `message.update(...)`.
  List<MessageEdited> get messageEdits =>
      _all.whereType<MessageEdited>().toList();

  /// Message deletions produced by `message.delete(...)`.
  List<MessageDeleted> get messageDeletions =>
      _all.whereType<MessageDeleted>().toList();

  void record(RecordedAction action) {
    _all.add(action);
    for (final l in _listeners) {
      l(action);
    }
  }

  void clear() => _all.clear();
}
