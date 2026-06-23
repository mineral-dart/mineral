import 'package:mineral/src/api/common/types/enhanced_enum.dart';
import 'package:mineral/src/domains/events/contracts/common_events.dart';
import 'package:mineral/src/domains/events/contracts/private_events.dart';
import 'package:mineral/src/domains/events/contracts/server_events.dart';

interface class EventType {}

enum Event implements EnhancedEnum<Type>, EventType {
  ready(ReadyEvent, [
    ['Bot', 'bot']
  ]),
  userUpdate(UserUpdateEvent, [
    ['User?', 'before'],
    ['User', 'after']
  ]),
  inviteCreate(InviteCreateEvent, [
    ['Invite', 'invite']
  ]),
  inviteDelete(InviteDeleteEvent, [
    ['String', 'code'],
    ['Channel', 'channel']
  ]),
  typing(TypingEvent, [
    ['Typing', 'typing']
  ]),
  serverAuditLog(ServerAuditLogEvent, [
    ['Server', 'server']
  ]),
  serverCreate(ServerCreateEvent, [
    ['Server', 'server']
  ]),
  serverUpdate(ServerUpdateEvent, [
    ['Server', 'before'],
    ['Server', 'after']
  ]),
  serverDelete(ServerDeleteEvent, [
    ['Server', 'server']
  ]),
  serverMessageCreate(ServerMessageCreateEvent, [
    ['ServerMessage', 'message']
  ]),
  serverMessageDelete(ServerMessageDeleteEvent, [
    ['Server', 'server'],
    ['ServerChannel', 'channel'],
    ['Snowflake', 'messageId'],
    ['Message?', 'message']
  ]),
  serverMessageDeleteBulk(ServerMessageDeleteBulkEvent, [
    ['Server', 'server'],
    ['ServerChannel', 'channel'],
    ['List<Snowflake>', 'messageIds'],
    ['Map<Snowflake, Message>', 'messages']
  ]),
  serverChannelCreate(ServerChannelCreateEvent, [
    ['ServerChannel', 'channel']
  ]),
  serverChannelUpdate(ServerChannelUpdateEvent, [
    ['ServerChannel', 'before'],
    ['ServerChannel', 'after']
  ]),
  serverChannelDelete(ServerChannelDeleteEvent, [
    ['ServerChannel', 'channel']
  ]),
  serverChannelPinsUpdate(ServerChannelPinsUpdateEvent, [
    ['ServerChannel', 'channel']
  ]),
  privateChannelPinsUpdate(PrivateChannelPinsUpdateEvent, [
    ['PrivateChannel', 'channel']
  ]),
  serverMemberAdd(ServerMemberAddEvent, [
    ['Server', 'server'],
    ['Member', 'member']
  ]),
  serverMemberRemove(ServerMemberRemoveEvent, [
    ['Server', 'server'],
    ['User', 'user']
  ]),
  serverBanAdd(ServerBanAddEvent, [
    ['Server', 'server'],
    ['User', 'user']
  ]),
  serverBanRemove(ServerBanRemoveEvent, [
    ['Server', 'server'],
    ['User', 'user']
  ]),
  serverMemberUpdate(ServerMemberUpdateEvent, [
    ['Server', 'server'],
    ['ServerMember', 'before'],
    ['Member', 'after']
  ]),
  serverPresenceUpdate(ServerPresenceUpdateEvent, [
    ['Member', 'member'],
    ['Server', 'server'],
    ['Presence', 'presence']
  ]),
  serverEmojisUpdate(ServerEmojisUpdateEvent, [
    ['Map<Snowflake, Emoji>', 'emojis'],
    ['Server', 'server']
  ]),
  serverStickersUpdate(ServerStickersUpdateEvent, [
    ['Server', 'server'],
    ['Map<Snowflake, Sticker>', 'stickers']
  ]),
  serverRoleCreate(ServerRolesCreateEvent, [
    ['Server', 'server'],
    ['Role', 'role']
  ]),
  serverRoleUpdate(ServerRolesUpdateEvent, [
    ['Server', 'server'],
    ['Role', 'before'],
    ['Role', 'after']
  ]),
  serverRoleDelete(ServerRolesDeleteEvent, [
    ['Server', 'server'],
    ['Role', 'role']
  ]),
  serverButtonClick(ServerButtonClickEvent, [
    ['ServerButtonContext', 'ctx']
  ]),
  serverModalSubmit(ServerModalSubmitEvent, [
    ['ServerModalContext', 'ctx']
  ]),
  serverChannelSelect(ServerChannelSelectEvent, [
    ['ServerSelectContext', 'ctx'],
    ['List<ServerChannel>', 'channels']
  ]),
  serverRoleSelect(ServerRoleSelectEvent, [
    ['ServerSelectContext', 'ctx'],
    ['List<Role>', 'roles']
  ]),
  serverMemberSelect(ServerMemberSelectEvent, [
    ['ServerSelectContext', 'ctx'],
    ['List<Member>', 'members']
  ]),
  serverMentionableSelect(ServerMentionableSelectEvent, [
    ['ServerSelectContext', 'ctx'],
    ['List<dynamic>', 'mentionables']
  ]),
  serverTextSelect(ServerTextSelectEvent, [
    ['ServerSelectContext', 'ctx'],
    ['List<String>', 'values']
  ]),
  serverThreadCreate(ServerThreadCreateEvent, [
    ['Server', 'server'],
    ['ThreadChannel', 'channel']
  ]),
  serverThreadUpdate(ServerThreadUpdateEvent, [
    ['Server', 'server'],
    ['ThreadChannel', 'before'],
    ['ThreadChannel', 'after']
  ]),
  serverThreadDelete(ServerThreadDeleteEvent, [
    ['ThreadChannel', 'thread'],
    ['Server', 'server']
  ]),
  serverThreadMemberUpdate(ServerThreadMemberUpdateEvent, [
    ['ThreadChannel', 'thread'],
    ['Server', 'server'],
    ['Member', 'member']
  ]),
  serverThreadMemberAdd(ServerThreadMemberAddEvent, [
    ['ThreadChannel', 'thread'],
    ['Server', 'server'],
    ['Member', 'member']
  ]),
  serverThreadMemberRemove(ServerThreadMemberRemoveEvent, [
    ['ThreadChannel', 'thread'],
    ['Server', 'server'],
    ['Member', 'member']
  ]),
  serverThreadListSync(ServerThreadListSyncEvent, [
    ['List<ThreadChannel>', 'threads'],
    ['Server', 'server']
  ]),
  serverMemberChunk(ServerMemberChunkEvent, [
    ['Server', 'server'],
    ['Map<Snowflake, Member>', 'members']
  ]),
  serverMessageReactionAdd(ServerMessageReactionAddEvent, [
    ['MessageReaction', 'reaction']
  ]),
  serverMessageReactionRemove(ServerMessageReactionRemoveEvent, [
    ['MessageReaction', 'reaction']
  ]),
  serverMessageReactionRemoveAll(ServerMessageReactionRemoveAllEvent, [
    ['Server', 'server'],
    ['ServerTextChannel', 'channel'],
    ['Message', 'message']
  ]),
  serverPollVoteAdd(ServerPollVoteAddEvent, [
    ['PollAnswerVote<ServerMessage>', 'message'],
    ['User', 'user']
  ]),
  serverPollVoteRemove(ServerPollVoteRemoveEvent, [
    ['PollAnswerVote<ServerMessage>', 'message'],
    ['User', 'user']
  ]),
  serverRuleCreate(ServerRuleCreateEvent, [
    ['AutoModerationRule', 'rule']
  ]),
  serverRuleUpdate(ServerRuleUpdateEvent, [
    ['AutoModerationRule?', 'before'],
    ['AutoModerationRule', 'after']
  ]),
  serverRuleDelete(ServerRuleDeleteEvent, [
    ['AutoModerationRule', 'rule']
  ]),
  serverRuleExecution(ServerRuleExecutionEvent, [
    ['RuleExecution', 'execution']
  ]),

  // private
  privateMessageCreate(PrivateMessageCreateEvent, [
    ['PrivateMessage', 'message']
  ]),
  privateMessageDelete(PrivateMessageDeleteEvent, [
    ['PrivateChannel', 'channel'],
    ['Snowflake', 'messageId'],
    ['Message?', 'message']
  ]),
  privateChannelCreate(PrivateChannelCreateEvent, [
    ['PrivateChannel', 'channel']
  ]),
  privateChannelUpdate(PrivateChannelUpdateEvent, [
    ['PrivateChannel', 'before'],
    ['PrivateChannel', 'after']
  ]),
  privatePollVoteAdd(PrivatePollVoteAddEvent, [
    ['PollAnswerVote<PrivateMessage>', 'message'],
    ['User', 'user']
  ]),
  privatePollVoteRemove(PrivatePollVoteRemoveEvent, [
    ['PollAnswerVote<PrivateMessage>', 'message'],
    ['User', 'user']
  ]),
  privateChannelDelete(PrivateChannelDeleteEvent, [
    ['PrivateChannel', 'channel']
  ]),
  privateButtonClick(PrivateButtonClickEvent, [
    ['PrivateButtonContext', 'ctx']
  ]),
  privateModalSubmit(PrivateModalSubmitEvent, [
    ['PrivateModalContext', 'ctx']
  ]),
  privateUserSelect(PrivateUserSelectEvent, [
    ['PrivateSelectContext', 'ctx'],
    ['List<User>', 'users']
  ]),
  privateMentionableSelect(PrivateMentionableSelectEvent, [
    ['PrivateSelectContext', 'ctx'],
    ['List<dynamic>', 'mentionables']
  ]),
  privateTextSelect(PrivateTextSelectEvent, [
    ['PrivateSelectContext', 'ctx'],
    ['List<String>', 'values']
  ]),
  privateMessageReactionAdd(PrivateMessageReactionAddEvent, [
    ['MessageReaction', 'reaction']
  ]),
  privateMessageReactionRemove(PrivateMessageReactionRemoveEvent, [
    ['MessageReaction', 'reaction']
  ]),
  privateMessageReactionRemoveAll(PrivateMessageReactionRemoveAllEvent, [
    ['PrivateChannel', 'channel'],
    ['Message', 'message']
  ]),
  voiceStateUpdate(VoiceStateUpdateEvent, [
    ['VoiceState', 'before'],
    ['VoiceState', 'after']
  ]),
  voiceConnect(VoiceConnectEvent, [
    ['VoiceState', 'state']
  ]),
  voiceDisconnect(VoiceDisconnectEvent, [
    ['VoiceState', 'state']
  ]),
  voiceJoin(VoiceJoinEvent, [
    ['VoiceState', 'state']
  ]),
  voiceLeave(VoiceLeaveEvent, [
    ['VoiceState', 'state']
  ]),
  voiceMove(VoiceMoveEvent, [
    ['VoiceState', 'before'],
    ['VoiceState', 'after']
  ]);

  @override
  final Type value;

  final List<List<String>> parameters;

  const Event(this.value, this.parameters);
}
