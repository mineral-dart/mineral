/// Sealed hierarchy describing every observable side-effect a Mineral bot can
/// produce during a test. Each variant captures just enough context to make
/// human-readable assertions ergonomic — see `bot.actions.*` and the
/// matchers library.
sealed class RecordedAction {
  const RecordedAction();
}

/// A message sent into a channel via `channel.send(...)`.
final class SentMessage extends RecordedAction {
  final String channelId;
  final String? content;
  final List<Map<String, dynamic>> components;

  const SentMessage({
    required this.channelId,
    required this.content,
    required this.components,
  });

  @override
  String toString() => 'SentMessage(channel: $channelId, content: $content)';
}

/// A reply produced by a slash command or component handler.
final class InteractionReply extends RecordedAction {
  final String interactionId;
  final String token;
  final String? content;
  final bool ephemeral;
  final List<Map<String, dynamic>> components;

  const InteractionReply({
    required this.interactionId,
    required this.token,
    required this.content,
    required this.ephemeral,
    required this.components,
  });

  @override
  String toString() =>
      'InteractionReply(content: $content, ephemeral: $ephemeral)';
}

/// A modal opened in response to an interaction.
final class ModalShown extends RecordedAction {
  final String interactionId;
  final String token;
  final String customId;
  final String? title;

  const ModalShown({
    required this.interactionId,
    required this.token,
    required this.customId,
    required this.title,
  });

  @override
  String toString() => 'ModalShown(customId: $customId)';
}

/// A member ban produced by `guild.members.ban(...)`.
final class MemberBanned extends RecordedAction {
  final String guildId;
  final String memberId;
  final String? reason;
  final Duration? deleteSince;

  const MemberBanned({
    required this.guildId,
    required this.memberId,
    required this.reason,
    required this.deleteSince,
  });

  @override
  String toString() => 'MemberBanned(member: $memberId, reason: $reason)';
}

/// A role assignment produced by `member.roles.add(...)`.
final class RoleAssigned extends RecordedAction {
  final String guildId;
  final String memberId;
  final String roleId;
  final String? reason;

  const RoleAssigned({
    required this.guildId,
    required this.memberId,
    required this.roleId,
    required this.reason,
  });

  @override
  String toString() => 'RoleAssigned(member: $memberId, role: $roleId)';
}

/// A role removal produced by `member.roles.remove(...)`.
final class RoleRemoved extends RecordedAction {
  final String guildId;
  final String memberId;
  final String roleId;
  final String? reason;

  const RoleRemoved({
    required this.guildId,
    required this.memberId,
    required this.roleId,
    required this.reason,
  });
}

/// A message edit produced by `message.update(...)`.
final class MessageEdited extends RecordedAction {
  final String channelId;
  final String messageId;
  final String? content;

  const MessageEdited({
    required this.channelId,
    required this.messageId,
    required this.content,
  });
}

/// A message deletion produced by `message.delete(...)`.
final class MessageDeleted extends RecordedAction {
  final String channelId;
  final String messageId;

  const MessageDeleted({required this.channelId, required this.messageId});
}
