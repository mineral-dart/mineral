import 'dart:async';

import 'package:mineral/api.dart';
import 'package:mineral/src/api/common/polls/poll_answer_vote.dart';
import 'package:mineral/src/domains/events/event.dart';
import 'package:mineral/src/domains/events/types/base_listenable_event.dart';

typedef PrivateButtonClickArgs = ({PrivateButtonContext ctx});

abstract class PrivateButtonClickEvent extends BaseListenableEvent {
  @override
  Event get event => Event.privateButtonClick;

  @override
  Function get handler => (PrivateButtonClickArgs p) => handle(p.ctx);

  FutureOr<void> handle(PrivateButtonContext ctx);
}

typedef PrivateChannelCreateArgs = ({PrivateChannel channel});

abstract class PrivateChannelCreateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.privateChannelCreate;

  @override
  Function get handler => (PrivateChannelCreateArgs p) => handle(p.channel);

  FutureOr<void> handle(PrivateChannel channel);
}

typedef PrivateChannelDeleteArgs = ({PrivateChannel channel});

abstract class PrivateChannelDeleteEvent extends BaseListenableEvent {
  @override
  Event get event => Event.privateChannelDelete;

  @override
  Function get handler => (PrivateChannelDeleteArgs p) => handle(p.channel);

  FutureOr<void> handle(PrivateChannel channel);
}

typedef PrivateChannelPinsUpdateArgs = ({PrivateChannel channel});

abstract class PrivateChannelPinsUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.privateChannelPinsUpdate;

  @override
  Function get handler => (PrivateChannelPinsUpdateArgs p) => handle(p.channel);

  FutureOr<void> handle(PrivateChannel channel);
}

typedef PrivateChannelUpdateArgs = ({
  PrivateChannel? before,
  PrivateChannel after
});

abstract class PrivateChannelUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.privateChannelUpdate;

  @override
  Function get handler =>
      (PrivateChannelUpdateArgs p) => handle(p.before, p.after);

  FutureOr<void> handle(PrivateChannel? before, PrivateChannel after);
}

typedef PrivateMessageCreateArgs = ({PrivateMessage message});

abstract class PrivateMessageCreateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.privateMessageCreate;

  @override
  Function get handler => (PrivateMessageCreateArgs p) => handle(p.message);

  FutureOr<void> handle(PrivateMessage message);
}

typedef PrivateMessageUpdateArgs = ({PrivateMessage? before, PrivateMessage after});

abstract class PrivateMessageUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.privateMessageUpdate;

  @override
  Function get handler =>
      (PrivateMessageUpdateArgs p) => handle(p.before, p.after);

  FutureOr<void> handle(PrivateMessage? before, PrivateMessage after);
}

typedef PrivateMessageDeleteArgs = ({
  PrivateChannel channel,
  Snowflake messageId,
  Message? message,
});

abstract class PrivateMessageDeleteEvent extends BaseListenableEvent {
  @override
  Event get event => Event.privateMessageDelete;

  @override
  Function get handler => (PrivateMessageDeleteArgs p) =>
      handle(p.channel, p.messageId, p.message);

  FutureOr<void> handle(
      PrivateChannel channel, Snowflake messageId, Message? message);
}

typedef PrivateMessageReactionAddArgs = ({MessageReaction reaction});

abstract class PrivateMessageReactionAddEvent extends BaseListenableEvent {
  @override
  Event get event => Event.privateMessageReactionAdd;

  @override
  Function get handler =>
      (PrivateMessageReactionAddArgs p) => handle(p.reaction);

  FutureOr<void> handle(MessageReaction reaction);
}

typedef PrivateMessageReactionRemoveArgs = ({MessageReaction reaction});

abstract class PrivateMessageReactionRemoveEvent extends BaseListenableEvent {
  @override
  Event get event => Event.privateMessageReactionRemove;

  @override
  Function get handler =>
      (PrivateMessageReactionRemoveArgs p) => handle(p.reaction);

  FutureOr<void> handle(MessageReaction reaction);
}

typedef PrivateMessageReactionRemoveAllArgs = ({
  PrivateChannel channel,
  Message message
});

abstract class PrivateMessageReactionRemoveAllEvent
    extends BaseListenableEvent {
  @override
  Event get event => Event.privateMessageReactionRemoveAll;

  @override
  Function get handler =>
      (PrivateMessageReactionRemoveAllArgs p) => handle(p.channel, p.message);

  FutureOr<void> handle(PrivateChannel channel, Message message);
}

typedef PrivateMessageReactionRemoveEmojiArgs = ({
  PrivateChannel channel,
  Message message,
  PartialEmoji emoji
});

abstract class PrivateMessageReactionRemoveEmojiEvent
    extends BaseListenableEvent {
  @override
  Event get event => Event.privateMessageReactionRemoveEmoji;

  @override
  Function get handler => (PrivateMessageReactionRemoveEmojiArgs p) =>
      handle(p.channel, p.message, p.emoji);

  FutureOr<void> handle(PrivateChannel channel, Message message, PartialEmoji emoji);
}

typedef PrivateModalSubmitArgs<T> = ({PrivateModalContext ctx, T data});

abstract class PrivateModalSubmitEvent<T> extends BaseListenableEvent {
  @override
  Event get event => Event.privateModalSubmit;

  @override
  Function get handler =>
      (PrivateModalSubmitArgs<T> p) => handle(p.ctx, p.data);

  FutureOr<void> handle(PrivateModalContext ctx, T data);
}

typedef PrivatePollVoteAddArgs = ({PollAnswerVote<Message> answer, User user});

abstract class PrivatePollVoteAddEvent extends BaseListenableEvent {
  @override
  Event get event => Event.privatePollVoteAdd;

  @override
  Function get handler =>
      (PrivatePollVoteAddArgs p) => handle(p.answer, p.user);

  FutureOr<void> handle(PollAnswerVote<Message> answer, User user);
}

typedef PrivatePollVoteRemoveArgs = ({
  PollAnswerVote<Message> answer,
  User user
});

abstract class PrivatePollVoteRemoveEvent extends BaseListenableEvent {
  @override
  Event get event => Event.privatePollVoteRemove;

  @override
  Function get handler =>
      (PrivatePollVoteRemoveArgs p) => handle(p.answer, p.user);

  FutureOr<void> handle(PollAnswerVote<Message> answer, User user);
}

typedef PrivateMentionableSelectArgs = ({
  PrivateSelectContext ctx,
  List<dynamic> mentionables
});

abstract class PrivateMentionableSelectEvent extends BaseListenableEvent {
  @override
  Event get event => Event.privateMentionableSelect;

  @override
  Function get handler =>
      (PrivateMentionableSelectArgs p) => handle(p.ctx, p.mentionables);

  FutureOr<void> handle(PrivateSelectContext ctx, List<dynamic> mentionables);
}

typedef PrivateTextSelectArgs = ({
  PrivateSelectContext ctx,
  List<String> values
});

abstract class PrivateTextSelectEvent extends BaseListenableEvent {
  @override
  Event get event => Event.privateTextSelect;

  @override
  Function get handler => (PrivateTextSelectArgs p) => handle(p.ctx, p.values);

  FutureOr<void> handle(PrivateSelectContext ctx, List<String> values);
}

typedef PrivateUserSelectArgs = ({PrivateSelectContext ctx, List<User> users});

abstract class PrivateUserSelectEvent extends BaseListenableEvent {
  @override
  Event get event => Event.privateUserSelect;

  @override
  Function get handler => (PrivateUserSelectArgs p) => handle(p.ctx, p.users);

  FutureOr<void> handle(PrivateSelectContext ctx, List<User> users);
}
