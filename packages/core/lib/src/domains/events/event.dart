import 'package:mineral/src/api/common/types/enhanced_enum.dart';
import 'package:mineral/src/domains/events/contracts/common_events.dart';
import 'package:mineral/src/domains/events/contracts/guild_events.dart';
import 'package:mineral/src/domains/events/contracts/private_events.dart';

interface class EventType {}

enum Event implements EnhancedEnum<Type>, EventType {
  ready(ReadyEvent, [
    ['Bot', 'bot'],
  ]),
  userUpdate(UserUpdateEvent, [
    ['User?', 'before'],
    ['User', 'after'],
  ]),
  inviteCreate(InviteCreateEvent, [
    ['Invite', 'invite'],
  ]),
  inviteDelete(InviteDeleteEvent, [
    ['String', 'code'],
    ['Channel', 'channel'],
  ]),
  typing(TypingEvent, [
    ['Typing', 'typing'],
  ]),
  guildAuditLog(GuildAuditLogEvent, [
    ['Guild', 'guild'],
  ]),
  guildCreate(GuildCreateEvent, [
    ['Guild', 'guild'],
  ]),
  guildUpdate(GuildUpdateEvent, [
    ['Guild', 'before'],
    ['Guild', 'after'],
  ]),
  guildDelete(GuildDeleteEvent, [
    ['Guild', 'guild'],
  ]),
  guildMessageCreate(GuildMessageCreateEvent, [
    ['GuildMessage', 'message'],
  ]),
  guildMessageUpdate(GuildMessageUpdateEvent, [
    ['GuildMessage?', 'before'],
    ['GuildMessage', 'after'],
  ]),
  guildMessageDelete(GuildMessageDeleteEvent, [
    ['Guild', 'guild'],
    ['GuildChannel', 'channel'],
    ['Snowflake', 'messageId'],
    ['Message?', 'message'],
  ]),
  guildMessageDeleteBulk(GuildMessageDeleteBulkEvent, [
    ['Guild', 'guild'],
    ['GuildChannel', 'channel'],
    ['List<Snowflake>', 'messageIds'],
    ['Map<Snowflake, Message>', 'messages'],
  ]),
  guildChannelCreate(GuildChannelCreateEvent, [
    ['GuildChannel', 'channel'],
  ]),
  guildChannelUpdate(GuildChannelUpdateEvent, [
    ['GuildChannel', 'before'],
    ['GuildChannel', 'after'],
  ]),
  guildChannelDelete(GuildChannelDeleteEvent, [
    ['GuildChannel', 'channel'],
  ]),
  guildChannelPinsUpdate(GuildChannelPinsUpdateEvent, [
    ['GuildChannel', 'channel'],
  ]),
  guildWebhooksUpdate(GuildWebhooksUpdateEvent, [
    ['Guild', 'guild'],
    ['GuildChannel', 'channel'],
  ]),
  privateChannelPinsUpdate(PrivateChannelPinsUpdateEvent, [
    ['PrivateChannel', 'channel'],
  ]),
  guildMemberAdd(GuildMemberAddEvent, [
    ['Guild', 'guild'],
    ['Member', 'member'],
  ]),
  guildMemberRemove(GuildMemberRemoveEvent, [
    ['Guild', 'guild'],
    ['User', 'user'],
  ]),
  guildBanAdd(GuildBanAddEvent, [
    ['Guild', 'guild'],
    ['User', 'user'],
  ]),
  guildBanRemove(GuildBanRemoveEvent, [
    ['Guild', 'guild'],
    ['User', 'user'],
  ]),
  guildMemberUpdate(GuildMemberUpdateEvent, [
    ['Guild', 'guild'],
    ['GuildMember', 'before'],
    ['Member', 'after'],
  ]),
  guildPresenceUpdate(GuildPresenceUpdateEvent, [
    ['Member', 'member'],
    ['Guild', 'guild'],
    ['Presence', 'presence'],
  ]),
  guildEmojisUpdate(GuildEmojisUpdateEvent, [
    ['Map<Snowflake, Emoji>', 'emojis'],
    ['Guild', 'guild'],
  ]),
  guildStickersUpdate(GuildStickersUpdateEvent, [
    ['Guild', 'guild'],
    ['Map<Snowflake, Sticker>', 'stickers'],
  ]),
  guildRoleCreate(GuildRolesCreateEvent, [
    ['Guild', 'guild'],
    ['Role', 'role'],
  ]),
  guildRoleUpdate(GuildRolesUpdateEvent, [
    ['Guild', 'guild'],
    ['Role', 'before'],
    ['Role', 'after'],
  ]),
  guildRoleDelete(GuildRolesDeleteEvent, [
    ['Guild', 'guild'],
    ['Role', 'role'],
  ]),
  guildButtonClick(GuildButtonClickEvent, [
    ['GuildButtonContext', 'ctx'],
  ]),
  guildModalSubmit(GuildModalSubmitEvent, [
    ['GuildModalContext', 'ctx'],
  ]),
  guildChannelSelect(GuildChannelSelectEvent, [
    ['GuildSelectContext', 'ctx'],
    ['List<GuildChannel>', 'channels'],
  ]),
  guildRoleSelect(GuildRoleSelectEvent, [
    ['GuildSelectContext', 'ctx'],
    ['List<Role>', 'roles'],
  ]),
  guildMemberSelect(GuildMemberSelectEvent, [
    ['GuildSelectContext', 'ctx'],
    ['List<Member>', 'members'],
  ]),
  guildMentionableSelect(GuildMentionableSelectEvent, [
    ['GuildSelectContext', 'ctx'],
    ['List<dynamic>', 'mentionables'],
  ]),
  guildTextSelect(GuildTextSelectEvent, [
    ['GuildSelectContext', 'ctx'],
    ['List<String>', 'values'],
  ]),
  guildThreadCreate(GuildThreadCreateEvent, [
    ['Guild', 'guild'],
    ['ThreadChannel', 'channel'],
  ]),
  guildThreadUpdate(GuildThreadUpdateEvent, [
    ['Guild', 'guild'],
    ['ThreadChannel', 'before'],
    ['ThreadChannel', 'after'],
  ]),
  guildThreadDelete(GuildThreadDeleteEvent, [
    ['ThreadChannel', 'thread'],
    ['Guild', 'guild'],
  ]),
  guildThreadMemberUpdate(GuildThreadMemberUpdateEvent, [
    ['ThreadChannel', 'thread'],
    ['Guild', 'guild'],
    ['Member', 'member'],
  ]),
  guildThreadMemberAdd(GuildThreadMemberAddEvent, [
    ['ThreadChannel', 'thread'],
    ['Guild', 'guild'],
    ['Member', 'member'],
  ]),
  guildThreadMemberRemove(GuildThreadMemberRemoveEvent, [
    ['ThreadChannel', 'thread'],
    ['Guild', 'guild'],
    ['Member', 'member'],
  ]),
  guildThreadListSync(GuildThreadListSyncEvent, [
    ['List<ThreadChannel>', 'threads'],
    ['Guild', 'guild'],
  ]),
  guildMemberChunk(GuildMemberChunkEvent, [
    ['Guild', 'guild'],
    ['Map<Snowflake, Member>', 'members'],
  ]),
  guildMessageReactionAdd(GuildMessageReactionAddEvent, [
    ['MessageReaction', 'reaction'],
  ]),
  guildMessageReactionRemove(GuildMessageReactionRemoveEvent, [
    ['MessageReaction', 'reaction'],
  ]),
  guildMessageReactionRemoveAll(GuildMessageReactionRemoveAllEvent, [
    ['Guild', 'guild'],
    ['GuildTextChannel', 'channel'],
    ['Message', 'message'],
  ]),
  guildMessageReactionRemoveEmoji(GuildMessageReactionRemoveEmojiEvent, [
    ['Guild', 'guild'],
    ['GuildTextChannel', 'channel'],
    ['Message', 'message'],
    ['PartialEmoji', 'emoji'],
  ]),
  guildPollVoteAdd(GuildPollVoteAddEvent, [
    ['PollAnswerVote<GuildMessage>', 'message'],
    ['User', 'user'],
  ]),
  guildPollVoteRemove(GuildPollVoteRemoveEvent, [
    ['PollAnswerVote<GuildMessage>', 'message'],
    ['User', 'user'],
  ]),
  guildRuleCreate(GuildRuleCreateEvent, [
    ['AutoModerationRule', 'rule'],
  ]),
  guildRuleUpdate(GuildRuleUpdateEvent, [
    ['AutoModerationRule?', 'before'],
    ['AutoModerationRule', 'after'],
  ]),
  guildRuleDelete(GuildRuleDeleteEvent, [
    ['AutoModerationRule', 'rule'],
  ]),
  guildRuleExecution(GuildRuleExecutionEvent, [
    ['RuleExecution', 'execution'],
  ]),

  // private
  privateMessageCreate(PrivateMessageCreateEvent, [
    ['PrivateMessage', 'message'],
  ]),
  privateMessageUpdate(PrivateMessageUpdateEvent, [
    ['PrivateMessage?', 'before'],
    ['PrivateMessage', 'after'],
  ]),
  privateMessageDelete(PrivateMessageDeleteEvent, [
    ['PrivateChannel', 'channel'],
    ['Snowflake', 'messageId'],
    ['Message?', 'message'],
  ]),
  privateChannelCreate(PrivateChannelCreateEvent, [
    ['PrivateChannel', 'channel'],
  ]),
  privateChannelUpdate(PrivateChannelUpdateEvent, [
    ['PrivateChannel', 'before'],
    ['PrivateChannel', 'after'],
  ]),
  privatePollVoteAdd(PrivatePollVoteAddEvent, [
    ['PollAnswerVote<PrivateMessage>', 'message'],
    ['User', 'user'],
  ]),
  privatePollVoteRemove(PrivatePollVoteRemoveEvent, [
    ['PollAnswerVote<PrivateMessage>', 'message'],
    ['User', 'user'],
  ]),
  privateChannelDelete(PrivateChannelDeleteEvent, [
    ['PrivateChannel', 'channel'],
  ]),
  privateButtonClick(PrivateButtonClickEvent, [
    ['PrivateButtonContext', 'ctx'],
  ]),
  privateModalSubmit(PrivateModalSubmitEvent, [
    ['PrivateModalContext', 'ctx'],
  ]),
  privateUserSelect(PrivateUserSelectEvent, [
    ['PrivateSelectContext', 'ctx'],
    ['List<User>', 'users'],
  ]),
  privateMentionableSelect(PrivateMentionableSelectEvent, [
    ['PrivateSelectContext', 'ctx'],
    ['List<dynamic>', 'mentionables'],
  ]),
  privateTextSelect(PrivateTextSelectEvent, [
    ['PrivateSelectContext', 'ctx'],
    ['List<String>', 'values'],
  ]),
  privateMessageReactionAdd(PrivateMessageReactionAddEvent, [
    ['MessageReaction', 'reaction'],
  ]),
  privateMessageReactionRemove(PrivateMessageReactionRemoveEvent, [
    ['MessageReaction', 'reaction'],
  ]),
  privateMessageReactionRemoveAll(PrivateMessageReactionRemoveAllEvent, [
    ['PrivateChannel', 'channel'],
    ['Message', 'message'],
  ]),
  privateMessageReactionRemoveEmoji(PrivateMessageReactionRemoveEmojiEvent, [
    ['PrivateChannel', 'channel'],
    ['Message', 'message'],
    ['PartialEmoji', 'emoji'],
  ]),
  voiceStateUpdate(VoiceStateUpdateEvent, [
    ['VoiceState', 'before'],
    ['VoiceState', 'after'],
  ]),
  voiceConnect(VoiceConnectEvent, [
    ['VoiceState', 'state'],
  ]),
  voiceDisconnect(VoiceDisconnectEvent, [
    ['VoiceState', 'state'],
  ]),
  voiceJoin(VoiceJoinEvent, [
    ['VoiceState', 'state'],
  ]),
  voiceLeave(VoiceLeaveEvent, [
    ['VoiceState', 'state'],
  ]),
  voiceMove(VoiceMoveEvent, [
    ['VoiceState', 'before'],
    ['VoiceState', 'after'],
  ]),
  guildApplicationCommandPermissionsUpdate(
    GuildApplicationCommandPermissionsUpdateEvent,
    [
      ['Guild', 'guild'],
      ['GuildApplicationCommandPermissions', 'permissions'],
    ],
  ),
  guildIntegrationsUpdate(GuildIntegrationsUpdateEvent, [
    ['Guild', 'guild'],
  ]),
  guildIntegrationCreate(GuildIntegrationCreateEvent, [
    ['Guild', 'guild'],
    ['Integration', 'integration'],
  ]),
  guildIntegrationUpdate(GuildIntegrationUpdateEvent, [
    ['Guild', 'guild'],
    ['Integration', 'integration'],
  ]),
  guildIntegrationDelete(GuildIntegrationDeleteEvent, [
    ['Guild', 'guild'],
    ['Snowflake', 'integrationId'],
    ['Snowflake?', 'applicationId'],
  ]),
  guildVoiceChannelEffectSend(GuildVoiceChannelEffectSendEvent, [
    ['Guild', 'guild'],
    ['GuildChannel', 'channel'],
    ['Member', 'member'],
    ['PartialEmoji?', 'emoji'],
    ['VoiceChannelEffectAnimationType?', 'animationType'],
    ['int?', 'animationId'],
    ['Snowflake?', 'soundId'],
    ['double?', 'soundVolume'],
  ]),
  guildScheduledEventCreate(GuildScheduledEventCreateEvent, [
    ['Guild', 'guild'],
    ['GuildScheduledEvent', 'event'],
  ]),
  guildScheduledEventUpdate(GuildScheduledEventUpdateEvent, [
    ['Guild', 'guild'],
    ['GuildScheduledEvent?', 'before'],
    ['GuildScheduledEvent', 'after'],
  ]),
  guildScheduledEventDelete(GuildScheduledEventDeleteEvent, [
    ['Guild', 'guild'],
    ['GuildScheduledEvent', 'event'],
  ]),
  guildScheduledEventUserAdd(GuildScheduledEventUserAddEvent, [
    ['Guild', 'guild'],
    ['Snowflake', 'eventId'],
    ['User', 'user'],
  ]),
  guildScheduledEventUserRemove(GuildScheduledEventUserRemoveEvent, [
    ['Guild', 'guild'],
    ['Snowflake', 'eventId'],
    ['User', 'user'],
  ]),
  guildStageInstanceCreate(GuildStageInstanceCreateEvent, [
    ['Guild', 'guild'],
    ['StageInstance', 'instance'],
  ]),
  guildStageInstanceUpdate(GuildStageInstanceUpdateEvent, [
    ['Guild', 'guild'],
    ['StageInstance', 'instance'],
  ]),
  guildStageInstanceDelete(GuildStageInstanceDeleteEvent, [
    ['Guild', 'guild'],
    ['StageInstance', 'instance'],
  ]),
  entitlementCreate(EntitlementCreateEvent, [
    ['Entitlement', 'entitlement'],
  ]),
  entitlementUpdate(EntitlementUpdateEvent, [
    ['Entitlement', 'entitlement'],
  ]),
  entitlementDelete(EntitlementDeleteEvent, [
    ['Entitlement', 'entitlement'],
  ]),
  subscriptionCreate(SubscriptionCreateEvent, [
    ['Subscription', 'subscription'],
  ]),
  subscriptionUpdate(SubscriptionUpdateEvent, [
    ['Subscription', 'subscription'],
  ]),
  subscriptionDelete(SubscriptionDeleteEvent, [
    ['Subscription', 'subscription'],
  ]),

  guildSoundboardSoundCreate(GuildSoundboardSoundCreateEvent, [
    ['Guild', 'guild'],
    ['SoundboardSound', 'sound'],
  ]),
  guildSoundboardSoundUpdate(GuildSoundboardSoundUpdateEvent, [
    ['Guild', 'guild'],
    ['SoundboardSound', 'sound'],
  ]),
  guildSoundboardSoundDelete(GuildSoundboardSoundDeleteEvent, [
    ['Guild', 'guild'],
    ['Snowflake', 'soundId'],
  ]),
  guildSoundboardSoundsUpdate(GuildSoundboardSoundsUpdateEvent, [
    ['Guild', 'guild'],
    ['List<SoundboardSound>', 'sounds'],
  ]),
  guildSoundboardSounds(GuildSoundboardSoundsEvent, [
    ['Guild', 'guild'],
    ['List<SoundboardSound>', 'sounds'],
  ]);

  @override
  final Type value;

  final List<List<String>> parameters;

  const Event(this.value, this.parameters);
}
