import 'dart:async';

import 'package:mineral/api.dart';
import 'package:mineral/src/api/common/polls/poll_answer_vote.dart';
import 'package:mineral/src/api/server/audit_log/audit_log.dart';
import 'package:mineral/src/domains/events/contracts/server_events.dart';
import 'package:mineral/src/domains/events/event.dart';
import 'package:mineral/src/domains/events/event_bucket.dart';

final class ServerBucket {
  final EventBucket _events;

  ServerBucket(this._events);

  void serverCreate(FutureOr<void> Function(Server server) handle) => _events
      .make(Event.serverCreate, (ServerCreateArgs p) => handle(p.server));

  void serverUpdate(
          FutureOr<void> Function(Server? before, Server after) handle) =>
      _events.make(Event.serverUpdate,
          (ServerUpdateArgs p) => handle(p.before, p.after));

  void serverDelete(FutureOr<void> Function(Server? server) handle) => _events
      .make(Event.serverDelete, (ServerDeleteArgs p) => handle(p.server));

  void messageCreate(FutureOr<void> Function(ServerMessage message) handle) =>
      _events.make(Event.serverMessageCreate,
          (ServerMessageCreateArgs p) => handle(p.message));

  void messageUpdate(
          FutureOr<void> Function(ServerMessage? before, ServerMessage after)
              handle) =>
      _events.make(Event.serverMessageUpdate,
          (ServerMessageUpdateArgs p) => handle(p.before, p.after));

  void messageDelete(
          FutureOr<void> Function(Server server, ServerChannel channel,
                  Snowflake messageId, Message? message)
              handle) =>
      _events.make(
          Event.serverMessageDelete,
          (ServerMessageDeleteArgs p) =>
              handle(p.server, p.channel, p.messageId, p.message));

  void messageDeleteBulk(
          FutureOr<void> Function(
                  Server server,
                  ServerChannel channel,
                  List<Snowflake> messageIds,
                  Map<Snowflake, Message> messages)
              handle) =>
      _events.make(
          Event.serverMessageDeleteBulk,
          (ServerMessageDeleteBulkArgs p) =>
              handle(p.server, p.channel, p.messageIds, p.messages));

  void channelCreate(FutureOr<void> Function(ServerChannel channel) handle) =>
      _events.make(Event.serverChannelCreate,
          (ServerChannelCreateArgs p) => handle(p.channel));

  void channelUpdate(
          FutureOr<void> Function(ServerChannel? before, ServerChannel after)
              handle) =>
      _events.make(Event.serverChannelUpdate,
          (ServerChannelUpdateArgs p) => handle(p.before, p.after));

  void channelDelete(FutureOr<void> Function(ServerChannel? channel) handle) =>
      _events.make(Event.serverChannelDelete,
          (ServerChannelDeleteArgs p) => handle(p.channel));

  void channelPinsUpdate(
          FutureOr<void> Function(Server server, ServerChannel channel)
              handle) =>
      _events.make(Event.serverChannelPinsUpdate,
          (ServerChannelPinsUpdateArgs p) => handle(p.server, p.channel));

  void memberAdd(
          FutureOr<void> Function(Member member, Server server) handle) =>
      _events.make(Event.serverMemberAdd,
          (ServerMemberAddArgs p) => handle(p.member, p.server));

  void memberRemove(
          FutureOr<void> Function(User? user, Server server) handle) =>
      _events.make(Event.serverMemberRemove,
          (ServerMemberRemoveArgs p) => handle(p.user, p.server));

  void memberUpdate(
          FutureOr<void> Function(Server server, Member after, Member before)
              handle) =>
      _events.make(Event.serverMemberUpdate,
          (ServerMemberUpdateArgs p) => handle(p.server, p.after, p.before));

  void memberChunk(
          FutureOr<void> Function(Server server, List<Member> members)
              handle) =>
      _events.make(Event.serverMemberChunk,
          (ServerMemberChunkArgs p) => handle(p.server, p.members));

  void roleCreate(FutureOr<void> Function(Server server, Role role) handle) =>
      _events.make(Event.serverRoleCreate,
          (ServerRoleCreateArgs p) => handle(p.server, p.role));

  void roleUpdate(
          FutureOr<void> Function(Server server, Role? before, Role after)
              handle) =>
      _events.make(Event.serverRoleUpdate,
          (ServerRoleUpdateArgs p) => handle(p.server, p.before, p.after));

  void roleDelete(FutureOr<void> Function(Server server, Role? role) handle) =>
      _events.make(Event.serverRoleDelete,
          (ServerRoleDeleteArgs p) => handle(p.server, p.role));

  void presenceUpdate(
          FutureOr<void> Function(Member member, Presence presence) handle) =>
      _events.make(Event.serverPresenceUpdate,
          (ServerPresenceUpdateArgs p) => handle(p.member, p.presence));

  void banAdd(FutureOr<void> Function(User user, Server server) handle) =>
      _events.make(
          Event.serverBanAdd, (ServerBanAddArgs p) => handle(p.user, p.server));

  void banRemove(FutureOr<void> Function(User user, Server server) handle) =>
      _events.make(Event.serverBanRemove,
          (ServerBanRemoveArgs p) => handle(p.user, p.server));

  void emojisUpdate(
          FutureOr<void> Function(Map<Snowflake, Emoji> emojis, Server server)
              handle) =>
      _events.make(Event.serverEmojisUpdate,
          (ServerEmojisUpdateArgs p) => handle(p.emojis, p.server));

  void stickersUpdate(
          FutureOr<void> Function(
                  Server server, Map<Snowflake, Sticker> stickers)
              handle) =>
      _events.make(Event.serverStickersUpdate,
          (ServerStickersUpdateArgs p) => handle(p.server, p.stickers));

  void buttonClick(FutureOr<void> Function(ServerButtonContext ctx) handle,
          {String? customId}) =>
      _events.make(
          Event.serverButtonClick, (ServerButtonClickArgs p) => handle(p.ctx),
          customId: customId);

  void modalSubmit<T>(
          FutureOr<void> Function(ServerModalContext ctx, T data) handle,
          {String? customId}) =>
      _events.make(Event.serverModalSubmit,
          (ServerModalSubmitArgs<T> p) => handle(p.ctx, p.data),
          customId: customId);

  void selectChannel(
          FutureOr<void> Function(
                  ServerSelectContext ctx, List<ServerChannel> channels)
              handle,
          {String? customId}) =>
      _events.make(Event.serverChannelSelect,
          (ServerChannelSelectArgs p) => handle(p.ctx, p.channels),
          customId: customId);

  void selectRole(
          FutureOr<void> Function(ServerSelectContext ctx, List<Role> roles)
              handle,
          {String? customId}) =>
      _events.make(Event.serverRoleSelect,
          (ServerRoleSelectArgs p) => handle(p.ctx, p.roles),
          customId: customId);

  void selectMember(
          FutureOr<void> Function(ServerSelectContext ctx, List<Member> members)
              handle,
          {String? customId}) =>
      _events.make(Event.serverMemberSelect,
          (ServerMemberSelectArgs p) => handle(p.ctx, p.members),
          customId: customId);

  void selectText(
          FutureOr<void> Function(ServerSelectContext ctx, List<String> values)
              handle,
          {String? customId}) =>
      _events.make(Event.serverTextSelect,
          (ServerTextSelectArgs p) => handle(p.ctx, p.values),
          customId: customId);

  void threadCreate(
          FutureOr<void> Function(Server server, ThreadChannel channel)
              handle) =>
      _events.make(Event.serverThreadCreate,
          (ServerThreadCreateArgs p) => handle(p.server, p.channel));

  void threadUpdate(
          FutureOr<void> Function(
                  Server server, ThreadChannel? before, ThreadChannel after)
              handle) =>
      _events.make(Event.serverThreadUpdate,
          (ServerThreadUpdateArgs p) => handle(p.server, p.before, p.after));

  void threadDelete(
          FutureOr<void> Function(ThreadChannel? thread, Server server)
              handle) =>
      _events.make(Event.serverThreadDelete,
          (ServerThreadDeleteArgs p) => handle(p.thread, p.server));

  void threadMemberUpdate(
          FutureOr<void> Function(
                  ThreadChannel thread, Server server, Member member)
              handle) =>
      _events.make(Event.serverThreadMemberUpdate,
          (ServerThreadMemberArgs p) => handle(p.thread, p.server, p.member));

  void threadMemberAdd(
          FutureOr<void> Function(
                  ThreadChannel thread, Server server, Member member)
              handle) =>
      _events.make(Event.serverThreadMemberAdd,
          (ServerThreadMemberArgs p) => handle(p.thread, p.server, p.member));

  void threadMemberRemove(
          FutureOr<void> Function(
                  ThreadChannel thread, Server server, Member member)
              handle) =>
      _events.make(Event.serverThreadMemberRemove,
          (ServerThreadMemberArgs p) => handle(p.thread, p.server, p.member));

  void messageReactionAdd(
          FutureOr<void> Function(MessageReaction reaction) handle) =>
      _events.make(Event.serverMessageReactionAdd,
          (ServerMessageReactionAddArgs p) => handle(p.reaction));

  void messageReactionRemove(
          FutureOr<void> Function(MessageReaction reaction) handle) =>
      _events.make(Event.serverMessageReactionRemove,
          (ServerMessageReactionRemoveArgs p) => handle(p.reaction));

  void messageReactionRemoveAll(
          FutureOr<void> Function(
                  Server server, ServerTextChannel channel, Message message)
              handle) =>
      _events.make(
          Event.serverMessageReactionRemoveAll,
          (ServerMessageReactionRemoveAllArgs p) =>
              handle(p.server, p.channel, p.message));

  void messageReactionRemoveEmoji(
          FutureOr<void> Function(Server server, ServerTextChannel channel,
                  Message message, PartialEmoji emoji)
              handle) =>
      _events.make(
          Event.serverMessageReactionRemoveEmoji,
          (ServerMessageReactionRemoveEmojiArgs p) =>
              handle(p.server, p.channel, p.message, p.emoji));

  void auditLog(FutureOr<void> Function(AuditLog audit) handle) => _events.make(
      Event.serverAuditLog, (ServerAuditLogArgs p) => handle(p.audit));

  void pollVoteAdd(
          FutureOr<void> Function(PollAnswerVote<Message> answer, User user)
              handle) =>
      _events.make(Event.serverPollVoteAdd,
          (ServerPollVoteAddArgs p) => handle(p.answer, p.user));

  void pollVoteRemove(
          FutureOr<void> Function(PollAnswerVote<Message> answer, User user)
              handle) =>
      _events.make(Event.serverPollVoteRemove,
          (ServerPollVoteRemoveArgs p) => handle(p.answer, p.user));

  void ruleCreate(FutureOr<void> Function(AutoModerationRule rule) handle) =>
      _events.make(
          Event.serverRuleCreate, (ServerRuleCreateArgs p) => handle(p.rule));

  void ruleUpdate(
          FutureOr<void> Function(
                  AutoModerationRule? before, AutoModerationRule after)
              handle) =>
      _events.make(Event.serverRuleUpdate,
          (ServerRuleUpdateArgs p) => handle(p.before, p.after));

  void ruleDelete(FutureOr<void> Function(AutoModerationRule rule) handle) =>
      _events.make(
          Event.serverRuleDelete, (ServerRuleDeleteArgs p) => handle(p.rule));

  void ruleExecution(FutureOr<void> Function(RuleExecution execution) handle) =>
      _events.make(Event.serverRuleExecution,
          (ServerRuleExecutionArgs p) => handle(p.execution));
}
