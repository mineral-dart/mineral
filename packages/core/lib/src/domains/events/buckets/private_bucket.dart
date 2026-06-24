import 'dart:async';

import 'package:mineral/api.dart';
import 'package:mineral/src/api/common/polls/poll_answer_vote.dart';
import 'package:mineral/src/domains/events/contracts/private_events.dart';
import 'package:mineral/src/domains/events/event.dart';
import 'package:mineral/src/domains/events/event_bucket.dart';

final class PrivateBucket {
  final EventBucket _events;

  PrivateBucket(this._events);

  void messageCreate(FutureOr<void> Function(PrivateMessage message) handle) =>
      _events.make(
        Event.privateMessageCreate,
        (PrivateMessageCreateArgs p) => handle(p.message),
      );

  void messageUpdate(
    FutureOr<void> Function(PrivateMessage? before, PrivateMessage after)
    handle,
  ) => _events.make(
    Event.privateMessageUpdate,
    (PrivateMessageUpdateArgs p) => handle(p.before, p.after),
  );

  void messageDelete(
    FutureOr<void> Function(
      PrivateChannel channel,
      Snowflake messageId,
      Message? message,
    )
    handle,
  ) => _events.make(
    Event.privateMessageDelete,
    (PrivateMessageDeleteArgs p) => handle(p.channel, p.messageId, p.message),
  );

  void channelCreate(FutureOr<void> Function(PrivateChannel channel) handle) =>
      _events.make(
        Event.privateChannelCreate,
        (PrivateChannelCreateArgs p) => handle(p.channel),
      );

  void channelPinsUpdate(
    FutureOr<void> Function(PrivateChannel channel) handle,
  ) => _events.make(
    Event.privateChannelPinsUpdate,
    (PrivateChannelPinsUpdateArgs p) => handle(p.channel),
  );

  void buttonClick(FutureOr<void> Function(PrivateButtonContext ctx) handle) =>
      _events.make(
        Event.privateButtonClick,
        (PrivateButtonClickArgs p) => handle(p.ctx),
      );

  void modalSubmit<T>(
    FutureOr<void> Function(PrivateModalContext ctx, T data) handle, {
    String? customId,
  }) => _events.make(
    Event.privateModalSubmit,
    (PrivateModalSubmitArgs<T> p) => handle(p.ctx, p.data),
    customId: customId,
  );

  void selectUser(
    FutureOr<void> Function(PrivateSelectContext ctx, List<User> users)
    handle, {
    String? customId,
  }) => _events.make(
    Event.privateUserSelect,
    (PrivateUserSelectArgs p) => handle(p.ctx, p.users),
    customId: customId,
  );

  void selectText(
    FutureOr<void> Function(PrivateSelectContext ctx, List<String> values)
    handle, {
    String? customId,
  }) => _events.make(
    Event.privateTextSelect,
    (PrivateTextSelectArgs p) => handle(p.ctx, p.values),
    customId: customId,
  );

  void messageReactionAdd(
    FutureOr<void> Function(MessageReaction reaction) handle,
  ) => _events.make(
    Event.privateMessageReactionAdd,
    (PrivateMessageReactionAddArgs p) => handle(p.reaction),
  );

  void messageReactionRemove(
    FutureOr<void> Function(MessageReaction reaction) handle,
  ) => _events.make(
    Event.privateMessageReactionRemove,
    (PrivateMessageReactionRemoveArgs p) => handle(p.reaction),
  );

  void messageReactionRemoveAll(
    FutureOr<void> Function(PrivateChannel channel, Message message) handle,
  ) => _events.make(
    Event.privateMessageReactionRemoveAll,
    (PrivateMessageReactionRemoveAllArgs p) => handle(p.channel, p.message),
  );

  void messageReactionRemoveEmoji(
    FutureOr<void> Function(
      PrivateChannel channel,
      Message message,
      PartialEmoji emoji,
    )
    handle,
  ) => _events.make(
    Event.privateMessageReactionRemoveEmoji,
    (PrivateMessageReactionRemoveEmojiArgs p) =>
        handle(p.channel, p.message, p.emoji),
  );

  void pollVoteAdd(
    FutureOr<void> Function(PollAnswerVote<Message> answer, User user) handle,
  ) => _events.make(
    Event.privatePollVoteAdd,
    (PrivatePollVoteAddArgs p) => handle(p.answer, p.user),
  );

  void pollVoteRemove(
    FutureOr<void> Function(PollAnswerVote<Message> answer, User user) handle,
  ) => _events.make(
    Event.privatePollVoteRemove,
    (PrivatePollVoteRemoveArgs p) => handle(p.answer, p.user),
  );
}
