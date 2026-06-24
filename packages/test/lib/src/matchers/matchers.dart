import 'package:test/test.dart';

import '../recorders/recorded_action.dart';

Matcher _stringOrMatcher(Object? value) {
  if (value is Matcher) {
    return value;
  }
  if (value == null) {
    return isNull;
  }
  return equals(value);
}

/// Matches a [SentMessage] against optional channel id and content predicates.
///
/// ```dart
/// expect(
///   bot.actions.sentMessages,
///   contains(isMessageSent(channelId: 'general', content: 'hello bob')),
/// );
/// expect(
///   bot.actions.sentMessages,
///   contains(isMessageSent(content: contains('hello'))),
/// );
/// ```
Matcher isMessageSent({Object? channelId, Object? content}) {
  return _SentMessageMatcher(
    channelMatcher: channelId == null ? null : _stringOrMatcher(channelId),
    contentMatcher: content == null ? null : _stringOrMatcher(content),
  );
}

/// Matches an [InteractionReply].
Matcher isInteractionReplied({Object? content, bool? ephemeral}) {
  return _InteractionReplyMatcher(
    contentMatcher: content == null ? null : _stringOrMatcher(content),
    ephemeral: ephemeral,
  );
}

/// Matches a [ModalShown] against optional custom id and title predicates.
Matcher isModalShown({Object? customId, Object? title}) {
  return _ModalShownMatcher(
    customIdMatcher: customId == null ? null : _stringOrMatcher(customId),
    titleMatcher: title == null ? null : _stringOrMatcher(title),
  );
}

/// Matches a [MemberBanned] against optional member id and reason predicates.
Matcher isMemberBanned({Object? memberId, Object? reason}) {
  return _MemberBannedMatcher(
    memberMatcher: memberId == null ? null : _stringOrMatcher(memberId),
    reasonMatcher: reason == null ? null : _stringOrMatcher(reason),
  );
}

/// Matches a [RoleAssigned].
Matcher isRoleAssigned({Object? memberId, Object? roleId}) {
  return _RoleAssignedMatcher(
    memberMatcher: memberId == null ? null : _stringOrMatcher(memberId),
    roleMatcher: roleId == null ? null : _stringOrMatcher(roleId),
  );
}

/// Matches a [RoleRemoved].
Matcher isRoleRemoved({Object? memberId, Object? roleId}) {
  return _RoleRemovedMatcher(
    memberMatcher: memberId == null ? null : _stringOrMatcher(memberId),
    roleMatcher: roleId == null ? null : _stringOrMatcher(roleId),
  );
}

class _SentMessageMatcher extends Matcher {
  final Matcher? channelMatcher;
  final Matcher? contentMatcher;

  _SentMessageMatcher({this.channelMatcher, this.contentMatcher});

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! SentMessage) {
      return false;
    }
    if (channelMatcher != null &&
        !channelMatcher!.matches(item.channelId, matchState)) {
      return false;
    }
    if (contentMatcher != null &&
        !contentMatcher!.matches(item.content, matchState)) {
      return false;
    }
    return true;
  }

  @override
  Description describe(Description description) {
    description.add('a SentMessage');
    if (channelMatcher != null) {
      description.add(' channelId=').addDescriptionOf(channelMatcher);
    }
    if (contentMatcher != null) {
      description.add(' content=').addDescriptionOf(contentMatcher);
    }
    return description;
  }
}

class _InteractionReplyMatcher extends Matcher {
  final Matcher? contentMatcher;
  final bool? ephemeral;

  _InteractionReplyMatcher({this.contentMatcher, this.ephemeral});

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! InteractionReply) {
      return false;
    }
    if (contentMatcher != null &&
        !contentMatcher!.matches(item.content, matchState)) {
      return false;
    }
    if (ephemeral != null && item.ephemeral != ephemeral) {
      return false;
    }
    return true;
  }

  @override
  Description describe(Description description) {
    description.add('an InteractionReply');
    if (contentMatcher != null) {
      description.add(' content=').addDescriptionOf(contentMatcher);
    }
    if (ephemeral != null) {
      description.add(' ephemeral=$ephemeral');
    }
    return description;
  }
}

class _ModalShownMatcher extends Matcher {
  final Matcher? customIdMatcher;
  final Matcher? titleMatcher;

  _ModalShownMatcher({this.customIdMatcher, this.titleMatcher});

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! ModalShown) {
      return false;
    }
    if (customIdMatcher != null &&
        !customIdMatcher!.matches(item.customId, matchState)) {
      return false;
    }
    if (titleMatcher != null &&
        !titleMatcher!.matches(item.title, matchState)) {
      return false;
    }
    return true;
  }

  @override
  Description describe(Description description) {
    description.add('a ModalShown');
    if (customIdMatcher != null) {
      description.add(' customId=').addDescriptionOf(customIdMatcher);
    }
    if (titleMatcher != null) {
      description.add(' title=').addDescriptionOf(titleMatcher);
    }
    return description;
  }
}

class _MemberBannedMatcher extends Matcher {
  final Matcher? memberMatcher;
  final Matcher? reasonMatcher;

  _MemberBannedMatcher({this.memberMatcher, this.reasonMatcher});

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! MemberBanned) {
      return false;
    }
    if (memberMatcher != null &&
        !memberMatcher!.matches(item.memberId, matchState)) {
      return false;
    }
    if (reasonMatcher != null &&
        !reasonMatcher!.matches(item.reason, matchState)) {
      return false;
    }
    return true;
  }

  @override
  Description describe(Description description) {
    description.add('a MemberBanned');
    if (memberMatcher != null) {
      description.add(' memberId=').addDescriptionOf(memberMatcher);
    }
    if (reasonMatcher != null) {
      description.add(' reason=').addDescriptionOf(reasonMatcher);
    }
    return description;
  }
}

class _RoleAssignedMatcher extends Matcher {
  final Matcher? memberMatcher;
  final Matcher? roleMatcher;

  _RoleAssignedMatcher({this.memberMatcher, this.roleMatcher});

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! RoleAssigned) {
      return false;
    }
    if (memberMatcher != null &&
        !memberMatcher!.matches(item.memberId, matchState)) {
      return false;
    }
    if (roleMatcher != null && !roleMatcher!.matches(item.roleId, matchState)) {
      return false;
    }
    return true;
  }

  @override
  Description describe(Description description) {
    description.add('a RoleAssigned');
    if (memberMatcher != null) {
      description.add(' memberId=').addDescriptionOf(memberMatcher);
    }
    if (roleMatcher != null) {
      description.add(' roleId=').addDescriptionOf(roleMatcher);
    }
    return description;
  }
}

class _RoleRemovedMatcher extends Matcher {
  final Matcher? memberMatcher;
  final Matcher? roleMatcher;

  _RoleRemovedMatcher({this.memberMatcher, this.roleMatcher});

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! RoleRemoved) {
      return false;
    }
    if (memberMatcher != null &&
        !memberMatcher!.matches(item.memberId, matchState)) {
      return false;
    }
    if (roleMatcher != null && !roleMatcher!.matches(item.roleId, matchState)) {
      return false;
    }
    return true;
  }

  @override
  Description describe(Description description) {
    description.add('a RoleRemoved');
    if (memberMatcher != null) {
      description.add(' memberId=').addDescriptionOf(memberMatcher);
    }
    if (roleMatcher != null) {
      description.add(' roleId=').addDescriptionOf(roleMatcher);
    }
    return description;
  }
}
