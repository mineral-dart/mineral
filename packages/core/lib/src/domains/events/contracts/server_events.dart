import 'dart:async';

import 'package:mineral/api.dart';
import 'package:mineral/src/api/common/polls/poll_answer_vote.dart';
import 'package:mineral/src/api/server/audit_log/audit_log.dart';
import 'package:mineral/src/domains/events/event.dart';
import 'package:mineral/src/domains/events/types/base_listenable_event.dart';

typedef ServerAuditLogArgs = ({AuditLog audit});

abstract class ServerAuditLogEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverAuditLog;

  @override
  Function get handler => (ServerAuditLogArgs p) => handle(p.audit);

  FutureOr<void> handle(AuditLog audit);
}

typedef ServerBanAddArgs = ({User user, Server server});

abstract class ServerBanAddEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverBanAdd;

  @override
  Function get handler => (ServerBanAddArgs p) => handle(p.user, p.server);

  FutureOr<void> handle(User user, Server server);
}

typedef ServerBanRemoveArgs = ({User user, Server server});

abstract class ServerBanRemoveEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverBanRemove;

  @override
  Function get handler => (ServerBanRemoveArgs p) => handle(p.user, p.server);

  FutureOr<void> handle(User user, Server server);
}

typedef ServerButtonClickArgs = ({ServerButtonContext ctx});

abstract class ServerButtonClickEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverButtonClick;

  @override
  Function get handler => (ServerButtonClickArgs p) => handle(p.ctx);

  FutureOr<void> handle(ServerButtonContext ctx);
}

typedef ServerChannelCreateArgs = ({ServerChannel channel});

abstract class ServerChannelCreateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverChannelCreate;

  @override
  Function get handler => (ServerChannelCreateArgs p) => handle(p.channel);

  FutureOr<void> handle(ServerChannel channel);
}

typedef ServerChannelDeleteArgs = ({ServerChannel? channel});

abstract class ServerChannelDeleteEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverChannelDelete;

  @override
  Function get handler => (ServerChannelDeleteArgs p) => handle(p.channel);

  FutureOr<void> handle(ServerChannel? channel);
}

typedef ServerChannelPinsUpdateArgs = ({Server server, ServerChannel channel});

abstract class ServerChannelPinsUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverChannelPinsUpdate;

  @override
  Function get handler =>
      (ServerChannelPinsUpdateArgs p) => handle(p.server, p.channel);

  FutureOr<void> handle(Server server, ServerChannel channel);
}

typedef ServerChannelUpdateArgs = ({ServerChannel? before, ServerChannel after});

abstract class ServerChannelUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverChannelUpdate;

  @override
  Function get handler =>
      (ServerChannelUpdateArgs p) => handle(p.before, p.after);

  FutureOr<void> handle(ServerChannel? before, ServerChannel after);
}

typedef ServerCreateArgs = ({Server server});

abstract class ServerCreateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverCreate;

  @override
  Function get handler => (ServerCreateArgs p) => handle(p.server);

  FutureOr<void> handle(Server server);
}

typedef ServerDeleteArgs = ({Server? server});

abstract class ServerDeleteEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverDelete;

  @override
  Function get handler => (ServerDeleteArgs p) => handle(p.server);

  FutureOr<void> handle(Server? server);
}

typedef ServerUpdateArgs = ({Server? before, Server after});

abstract class ServerUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverUpdate;

  @override
  Function get handler => (ServerUpdateArgs p) => handle(p.before, p.after);

  FutureOr<void> handle(Server? before, Server after);
}

typedef ServerEmojisUpdateArgs = ({Map<Snowflake, Emoji> emojis, Server server});

abstract class ServerEmojisUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverEmojisUpdate;

  @override
  Function get handler =>
      (ServerEmojisUpdateArgs p) => handle(p.emojis, p.server);

  FutureOr<void> handle(Map<Snowflake, Emoji> emojis, Server server);
}

typedef ServerStickersUpdateArgs = ({
  Server server,
  Map<Snowflake, Sticker> stickers
});

abstract class ServerStickersUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverStickersUpdate;

  @override
  Function get handler =>
      (ServerStickersUpdateArgs p) => handle(p.server, p.stickers);

  FutureOr<void> handle(Server server, Map<Snowflake, Sticker> stickers);
}

typedef ServerMemberAddArgs = ({Member member, Server server});

abstract class ServerMemberAddEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverMemberAdd;

  @override
  Function get handler => (ServerMemberAddArgs p) => handle(p.member, p.server);

  FutureOr<void> handle(Member member, Server server);
}

typedef ServerMemberChunkArgs = ({Server server, List<Member> members});

abstract class ServerMemberChunkEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverMemberChunk;

  @override
  Function get handler =>
      (ServerMemberChunkArgs p) => handle(p.server, p.members);

  FutureOr<void> handle(Server server, List<Member> members);
}

typedef ServerMemberRemoveArgs = ({User? user, Server server});

abstract class ServerMemberRemoveEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverMemberRemove;

  @override
  Function get handler =>
      (ServerMemberRemoveArgs p) => handle(p.user, p.server);

  FutureOr<void> handle(User? user, Server server);
}

typedef ServerMemberUpdateArgs = ({Server server, Member after, Member before});

abstract class ServerMemberUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverMemberUpdate;

  @override
  Function get handler =>
      (ServerMemberUpdateArgs p) => handle(p.server, p.after, p.before);

  FutureOr<void> handle(Server server, Member after, Member before);
}

typedef ServerMessageCreateArgs = ({ServerMessage message});

abstract class ServerMessageCreateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverMessageCreate;

  @override
  Function get handler => (ServerMessageCreateArgs p) => handle(p.message);

  FutureOr<void> handle(ServerMessage message);
}

typedef ServerMessageUpdateArgs = ({ServerMessage? before, ServerMessage after});

abstract class ServerMessageUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverMessageUpdate;

  @override
  Function get handler =>
      (ServerMessageUpdateArgs p) => handle(p.before, p.after);

  FutureOr<void> handle(ServerMessage? before, ServerMessage after);
}

typedef ServerMessageDeleteArgs = ({
  Server server,
  ServerChannel channel,
  Snowflake messageId,
  Message? message,
});

abstract class ServerMessageDeleteEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverMessageDelete;

  @override
  Function get handler => (ServerMessageDeleteArgs p) =>
      handle(p.server, p.channel, p.messageId, p.message);

  FutureOr<void> handle(Server server, ServerChannel channel,
      Snowflake messageId, Message? message);
}

typedef ServerMessageDeleteBulkArgs = ({
  Server server,
  ServerChannel channel,
  List<Snowflake> messageIds,
  Map<Snowflake, Message> messages,
});

abstract class ServerMessageDeleteBulkEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverMessageDeleteBulk;

  @override
  Function get handler => (ServerMessageDeleteBulkArgs p) =>
      handle(p.server, p.channel, p.messageIds, p.messages);

  FutureOr<void> handle(Server server, ServerChannel channel,
      List<Snowflake> messageIds, Map<Snowflake, Message> messages);
}

typedef ServerMessageReactionAddArgs = ({MessageReaction reaction});

abstract class ServerMessageReactionAddEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverMessageReactionAdd;

  @override
  Function get handler =>
      (ServerMessageReactionAddArgs p) => handle(p.reaction);

  FutureOr<void> handle(MessageReaction reaction);
}

typedef ServerMessageReactionRemoveArgs = ({MessageReaction reaction});

abstract class ServerMessageReactionRemoveEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverMessageReactionRemove;

  @override
  Function get handler =>
      (ServerMessageReactionRemoveArgs p) => handle(p.reaction);

  FutureOr<void> handle(MessageReaction reaction);
}

typedef ServerMessageReactionRemoveAllArgs = ({
  Server server,
  ServerTextChannel channel,
  Message message
});

abstract class ServerMessageReactionRemoveAllEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverMessageReactionRemoveAll;

  @override
  Function get handler => (ServerMessageReactionRemoveAllArgs p) =>
      handle(p.server, p.channel, p.message);

  FutureOr<void> handle(
      Server server, ServerTextChannel channel, Message message);
}

typedef ServerMessageReactionRemoveEmojiArgs = ({
  Server server,
  ServerTextChannel channel,
  Message message,
  PartialEmoji emoji
});

abstract class ServerMessageReactionRemoveEmojiEvent
    extends BaseListenableEvent {
  @override
  Event get event => Event.serverMessageReactionRemoveEmoji;

  @override
  Function get handler => (ServerMessageReactionRemoveEmojiArgs p) =>
      handle(p.server, p.channel, p.message, p.emoji);

  FutureOr<void> handle(
      Server server, ServerTextChannel channel, Message message, PartialEmoji emoji);
}

typedef ServerModalSubmitArgs<T> = ({ServerModalContext ctx, T data});

abstract class ServerModalSubmitEvent<T> extends BaseListenableEvent {
  @override
  Event get event => Event.serverModalSubmit;

  @override
  Function get handler => (ServerModalSubmitArgs<T> p) => handle(p.ctx, p.data);

  FutureOr<void> handle(ServerModalContext ctx, T data);
}

typedef ServerPollVoteAddArgs = ({PollAnswerVote<Message> answer, User user});

abstract class ServerPollVoteAddEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverPollVoteAdd;

  @override
  Function get handler => (ServerPollVoteAddArgs p) => handle(p.answer, p.user);

  FutureOr<void> handle(PollAnswerVote<Message> answer, User user);
}

typedef ServerPollVoteRemoveArgs = ({
  PollAnswerVote<Message> answer,
  User user
});

abstract class ServerPollVoteRemoveEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverPollVoteRemove;

  @override
  Function get handler =>
      (ServerPollVoteRemoveArgs p) => handle(p.answer, p.user);

  FutureOr<void> handle(PollAnswerVote<Message> answer, User user);
}

typedef ServerPresenceUpdateArgs = ({Member member, Presence presence});

abstract class ServerPresenceUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverPresenceUpdate;

  @override
  Function get handler =>
      (ServerPresenceUpdateArgs p) => handle(p.member, p.presence);

  FutureOr<void> handle(Member member, Presence presence);
}

typedef ServerRoleCreateArgs = ({Server server, Role role});

abstract class ServerRolesCreateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverRoleCreate;

  @override
  Function get handler => (ServerRoleCreateArgs p) => handle(p.server, p.role);

  FutureOr<void> handle(Server server, Role role);
}

typedef ServerRoleDeleteArgs = ({Server server, Role? role});

abstract class ServerRolesDeleteEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverRoleDelete;

  @override
  Function get handler => (ServerRoleDeleteArgs p) => handle(p.server, p.role);

  FutureOr<void> handle(Server server, Role? role);
}

typedef ServerRoleUpdateArgs = ({Server server, Role? before, Role after});

abstract class ServerRolesUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverRoleUpdate;

  @override
  Function get handler =>
      (ServerRoleUpdateArgs p) => handle(p.server, p.before, p.after);

  FutureOr<void> handle(Server server, Role? before, Role after);
}

typedef ServerRuleCreateArgs = ({AutoModerationRule rule});

abstract class ServerRuleCreateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverRuleCreate;

  @override
  Function get handler => (ServerRuleCreateArgs p) => handle(p.rule);

  FutureOr<void> handle(AutoModerationRule rule);
}

typedef ServerRuleDeleteArgs = ({AutoModerationRule rule});

abstract class ServerRuleDeleteEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverRuleDelete;

  @override
  Function get handler => (ServerRuleDeleteArgs p) => handle(p.rule);

  FutureOr<void> handle(AutoModerationRule rule);
}

typedef ServerRuleExecutionArgs = ({RuleExecution execution});

abstract class ServerRuleExecutionEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverRuleExecution;

  @override
  Function get handler => (ServerRuleExecutionArgs p) => handle(p.execution);

  FutureOr<void> handle(RuleExecution execution);
}

typedef ServerRuleUpdateArgs = ({
  AutoModerationRule? before,
  AutoModerationRule after
});

abstract class ServerRuleUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverRuleUpdate;

  @override
  Function get handler => (ServerRuleUpdateArgs p) => handle(p.before, p.after);

  FutureOr<void> handle(AutoModerationRule? before, AutoModerationRule after);
}

typedef ServerChannelSelectArgs = ({
  ServerSelectContext ctx,
  List<ServerChannel> channels
});

abstract class ServerChannelSelectEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverChannelSelect;

  @override
  Function get handler =>
      (ServerChannelSelectArgs p) => handle(p.ctx, p.channels);

  FutureOr<void> handle(ServerSelectContext ctx, List<ServerChannel> channels);
}

typedef ServerMemberSelectArgs = ({
  ServerSelectContext ctx,
  List<Member> members
});

abstract class ServerMemberSelectEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverMemberSelect;

  @override
  Function get handler =>
      (ServerMemberSelectArgs p) => handle(p.ctx, p.members);

  FutureOr<void> handle(ServerSelectContext ctx, List<Member> members);
}

typedef ServerMentionableSelectArgs = ({
  ServerSelectContext ctx,
  List<dynamic> mentionables
});

abstract class ServerMentionableSelectEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverMentionableSelect;

  @override
  Function get handler =>
      (ServerMentionableSelectArgs p) => handle(p.ctx, p.mentionables);

  FutureOr<void> handle(ServerSelectContext ctx, List<dynamic> mentionables);
}

typedef ServerRoleSelectArgs = ({ServerSelectContext ctx, List<Role> roles});

abstract class ServerRoleSelectEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverRoleSelect;

  @override
  Function get handler => (ServerRoleSelectArgs p) => handle(p.ctx, p.roles);

  FutureOr<void> handle(ServerSelectContext ctx, List<Role> roles);
}

typedef ServerTextSelectArgs = ({ServerSelectContext ctx, List<String> values});

abstract class ServerTextSelectEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverTextSelect;

  @override
  Function get handler => (ServerTextSelectArgs p) => handle(p.ctx, p.values);

  FutureOr<void> handle(ServerSelectContext ctx, List<String> values);
}

typedef ServerThreadCreateArgs = ({Server server, ThreadChannel channel});

abstract class ServerThreadCreateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverThreadCreate;

  @override
  Function get handler =>
      (ServerThreadCreateArgs p) => handle(p.server, p.channel);

  FutureOr<void> handle(Server server, ThreadChannel channel);
}

typedef ServerThreadDeleteArgs = ({ThreadChannel? thread, Server server});

abstract class ServerThreadDeleteEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverThreadDelete;

  @override
  Function get handler =>
      (ServerThreadDeleteArgs p) => handle(p.thread, p.server);

  FutureOr<void> handle(ThreadChannel? thread, Server server);
}

typedef ServerThreadListSyncArgs = ({
  List<ThreadChannel> threads,
  Server server
});

abstract class ServerThreadListSyncEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverThreadListSync;

  @override
  Function get handler =>
      (ServerThreadListSyncArgs p) => handle(p.threads, p.server);

  FutureOr<void> handle(List<ThreadChannel> threads, Server server);
}

typedef ServerThreadMemberArgs = ({
  ThreadChannel thread,
  Server server,
  Member member
});

abstract class ServerThreadMemberAddEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverThreadMemberAdd;

  @override
  Function get handler =>
      (ServerThreadMemberArgs p) => handle(p.thread, p.server, p.member);

  FutureOr<void> handle(ThreadChannel thread, Server server, Member member);
}

abstract class ServerThreadMemberRemoveEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverThreadMemberRemove;

  @override
  Function get handler =>
      (ServerThreadMemberArgs p) => handle(p.thread, p.server, p.member);

  FutureOr<void> handle(ThreadChannel thread, Server server, Member member);
}

abstract class ServerThreadMemberUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverThreadMemberUpdate;

  @override
  Function get handler =>
      (ServerThreadMemberArgs p) => handle(p.thread, p.server, p.member);

  FutureOr<void> handle(ThreadChannel thread, Server server, Member member);
}

typedef ServerWebhooksUpdateArgs = ({Server server, ServerChannel? channel});

abstract class ServerWebhooksUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverWebhooksUpdate;

  @override
  Function get handler =>
      (ServerWebhooksUpdateArgs p) => handle(p.server, p.channel);

  FutureOr<void> handle(Server server, ServerChannel? channel);
}

typedef ServerThreadUpdateArgs = ({
  Server server,
  ThreadChannel? before,
  ThreadChannel after
});

abstract class ServerThreadUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverThreadUpdate;

  @override
  Function get handler =>
      (ServerThreadUpdateArgs p) => handle(p.server, p.before, p.after);

  FutureOr<void> handle(
      Server server, ThreadChannel? before, ThreadChannel after);
}

typedef ServerVoiceChannelEffectSendArgs = ({
  Server server,
  ServerChannel channel,
  Member member,
  PartialEmoji? emoji,
  VoiceChannelEffectAnimationType? animationType,
  int? animationId,
  Snowflake? soundId,
  double? soundVolume,
});

abstract class ServerVoiceChannelEffectSendEvent extends BaseListenableEvent {
  @override
  Event get event => Event.serverVoiceChannelEffectSend;

  @override
  Function get handler => (ServerVoiceChannelEffectSendArgs p) => handle(
        p.server,
        p.channel,
        p.member,
        p.emoji,
        p.animationType,
        p.animationId,
        p.soundId,
        p.soundVolume,
      );

  FutureOr<void> handle(
    Server server,
    ServerChannel channel,
    Member member,
    PartialEmoji? emoji,
    VoiceChannelEffectAnimationType? animationType,
    int? animationId,
    Snowflake? soundId,
    double? soundVolume,
  );
}
