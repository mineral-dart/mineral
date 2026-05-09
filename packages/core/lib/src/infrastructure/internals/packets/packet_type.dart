import 'package:mineral/contracts.dart';

enum PacketType implements PacketTypeContract {
  ready('READY'),
  resumed('RESUMED'),

  interactionCreate('INTERACTION_CREATE'),

  messageCreate('MESSAGE_CREATE'),
  messageDelete('MESSAGE_DELETE'),
  messageDeleteBulk('MESSAGE_DELETE_BULK'),
  messageReactionAdd('MESSAGE_REACTION_ADD'),
  messageReactionRemove('MESSAGE_REACTION_REMOVE'),
  messageReactionRemoveAll('MESSAGE_REACTION_REMOVE_ALL'),

  threadCreate('THREAD_CREATE'),
  threadUpdate('THREAD_UPDATE'),
  threadDelete('THREAD_DELETE'),
  threadListSync('THREAD_LIST_SYNC'),
  threadMemberUpdate('THREAD_MEMBER_UPDATE'),
  threadMembersUpdate('THREAD_MEMBERS_UPDATE'),

  guildCreate('GUILD_CREATE'),
  guildUpdate('GUILD_UPDATE'),
  guildDelete('GUILD_DELETE'),

  channelCreate('CHANNEL_CREATE'),
  channelUpdate('CHANNEL_UPDATE'),
  channelDelete('CHANNEL_DELETE'),

  guildMemberAdd('GUILD_MEMBER_ADD'),
  guildMemberRemove('GUILD_MEMBER_REMOVE'),
  guildMemberUpdate('GUILD_MEMBER_UPDATE'),
  guildMemberChunk('GUILD_MEMBERS_CHUNK'),

  guildBanAdd('GUILD_BAN_ADD'),
  guildBanRemove('GUILD_BAN_REMOVE'),

  guildAuditLogEntryCreate('GUILD_AUDIT_LOG_ENTRY_CREATE'),

  presenceUpdate('PRESENCE_UPDATE'),

  guildRoleCreate('GUILD_ROLE_CREATE'),
  guildRoleUpdate('GUILD_ROLE_UPDATE'),
  guildRoleDelete('GUILD_ROLE_DELETE'),

  guildEmojisUpdate('GUILD_EMOJIS_UPDATE'),
  guildStickersUpdate('GUILD_STICKERS_UPDATE'),

  autoModerationRuleCreate('AUTO_MODERATION_RULE_CREATE'),
  autoModerationRuleUpdate('AUTO_MODERATION_RULE_UPDATE'),
  autoModerationRuleDelete('AUTO_MODERATION_RULE_DELETE'),
  autoModerationActionExecution('AUTO_MODERATION_ACTION_EXECUTION'),

  channelPinsUpdate('CHANNEL_PINS_UPDATE'),

  voiceStateUpdate('VOICE_STATE_UPDATE'),
  voiceChannelStatusUpdate('VOICE_CHANNEL_STATUS_UPDATE'),

  inviteCreate('INVITE_CREATE'),
  inviteDelete('INVITE_DELETE'),

  messagePollVoteAdd('MESSAGE_POLL_VOTE_ADD'),
  messagePollVoteRemove('MESSAGE_POLL_VOTE_REMOVE'),

  typingStart('TYPING_START');

  @override
  final String name;

  const PacketType(this.name);
}
