import 'dart:async';

import 'package:mineral/api.dart';
import 'package:mineral/src/api/common/polls/poll_answer_vote.dart';
import 'package:mineral/src/api/guild/audit_log/audit_log.dart';
import 'package:mineral/src/domains/events/event.dart';
import 'package:mineral/src/domains/events/types/base_listenable_event.dart';

typedef GuildAuditLogArgs = ({AuditLog audit});

abstract class GuildAuditLogEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildAuditLog;

  @override
  Function get handler => (GuildAuditLogArgs p) => handle(p.audit);

  FutureOr<void> handle(AuditLog audit);
}

typedef GuildBanAddArgs = ({User user, Guild guild});

abstract class GuildBanAddEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildBanAdd;

  @override
  Function get handler => (GuildBanAddArgs p) => handle(p.user, p.guild);

  FutureOr<void> handle(User user, Guild guild);
}

typedef GuildBanRemoveArgs = ({User user, Guild guild});

abstract class GuildBanRemoveEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildBanRemove;

  @override
  Function get handler => (GuildBanRemoveArgs p) => handle(p.user, p.guild);

  FutureOr<void> handle(User user, Guild guild);
}

typedef GuildButtonClickArgs = ({GuildButtonContext ctx});

abstract class GuildButtonClickEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildButtonClick;

  @override
  Function get handler => (GuildButtonClickArgs p) => handle(p.ctx);

  FutureOr<void> handle(GuildButtonContext ctx);
}

typedef GuildChannelCreateArgs = ({GuildChannel channel});

abstract class GuildChannelCreateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildChannelCreate;

  @override
  Function get handler => (GuildChannelCreateArgs p) => handle(p.channel);

  FutureOr<void> handle(GuildChannel channel);
}

typedef GuildChannelDeleteArgs = ({GuildChannel? channel});

abstract class GuildChannelDeleteEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildChannelDelete;

  @override
  Function get handler => (GuildChannelDeleteArgs p) => handle(p.channel);

  FutureOr<void> handle(GuildChannel? channel);
}

typedef GuildChannelPinsUpdateArgs = ({Guild guild, GuildChannel channel});

abstract class GuildChannelPinsUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildChannelPinsUpdate;

  @override
  Function get handler =>
      (GuildChannelPinsUpdateArgs p) => handle(p.guild, p.channel);

  FutureOr<void> handle(Guild guild, GuildChannel channel);
}

typedef GuildChannelUpdateArgs = ({GuildChannel? before, GuildChannel after});

abstract class GuildChannelUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildChannelUpdate;

  @override
  Function get handler =>
      (GuildChannelUpdateArgs p) => handle(p.before, p.after);

  FutureOr<void> handle(GuildChannel? before, GuildChannel after);
}

typedef GuildCreateArgs = ({Guild guild});

abstract class GuildCreateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildCreate;

  @override
  Function get handler => (GuildCreateArgs p) => handle(p.guild);

  FutureOr<void> handle(Guild guild);
}

typedef GuildDeleteArgs = ({Guild? guild});

abstract class GuildDeleteEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildDelete;

  @override
  Function get handler => (GuildDeleteArgs p) => handle(p.guild);

  FutureOr<void> handle(Guild? guild);
}

typedef GuildUpdateArgs = ({Guild? before, Guild after});

abstract class GuildUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildUpdate;

  @override
  Function get handler => (GuildUpdateArgs p) => handle(p.before, p.after);

  FutureOr<void> handle(Guild? before, Guild after);
}

typedef GuildEmojisUpdateArgs = ({Map<Snowflake, Emoji> emojis, Guild guild});

abstract class GuildEmojisUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildEmojisUpdate;

  @override
  Function get handler =>
      (GuildEmojisUpdateArgs p) => handle(p.emojis, p.guild);

  FutureOr<void> handle(Map<Snowflake, Emoji> emojis, Guild guild);
}

typedef GuildStickersUpdateArgs = ({
  Guild guild,
  Map<Snowflake, Sticker> stickers
});

abstract class GuildStickersUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildStickersUpdate;

  @override
  Function get handler =>
      (GuildStickersUpdateArgs p) => handle(p.guild, p.stickers);

  FutureOr<void> handle(Guild guild, Map<Snowflake, Sticker> stickers);
}

typedef GuildMemberAddArgs = ({Member member, Guild guild});

abstract class GuildMemberAddEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildMemberAdd;

  @override
  Function get handler => (GuildMemberAddArgs p) => handle(p.member, p.guild);

  FutureOr<void> handle(Member member, Guild guild);
}

typedef GuildMemberChunkArgs = ({Guild guild, List<Member> members});

abstract class GuildMemberChunkEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildMemberChunk;

  @override
  Function get handler =>
      (GuildMemberChunkArgs p) => handle(p.guild, p.members);

  FutureOr<void> handle(Guild guild, List<Member> members);
}

typedef GuildMemberRemoveArgs = ({User? user, Guild guild});

abstract class GuildMemberRemoveEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildMemberRemove;

  @override
  Function get handler =>
      (GuildMemberRemoveArgs p) => handle(p.user, p.guild);

  FutureOr<void> handle(User? user, Guild guild);
}

typedef GuildMemberUpdateArgs = ({Guild guild, Member after, Member before});

abstract class GuildMemberUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildMemberUpdate;

  @override
  Function get handler =>
      (GuildMemberUpdateArgs p) => handle(p.guild, p.after, p.before);

  FutureOr<void> handle(Guild guild, Member after, Member before);
}

typedef GuildMessageCreateArgs = ({GuildMessage message});

abstract class GuildMessageCreateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildMessageCreate;

  @override
  Function get handler => (GuildMessageCreateArgs p) => handle(p.message);

  FutureOr<void> handle(GuildMessage message);
}

typedef GuildMessageUpdateArgs = ({GuildMessage? before, GuildMessage after});

abstract class GuildMessageUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildMessageUpdate;

  @override
  Function get handler =>
      (GuildMessageUpdateArgs p) => handle(p.before, p.after);

  FutureOr<void> handle(GuildMessage? before, GuildMessage after);
}

typedef GuildMessageDeleteArgs = ({
  Guild guild,
  GuildChannel channel,
  Snowflake messageId,
  Message? message,
});

abstract class GuildMessageDeleteEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildMessageDelete;

  @override
  Function get handler => (GuildMessageDeleteArgs p) =>
      handle(p.guild, p.channel, p.messageId, p.message);

  FutureOr<void> handle(Guild guild, GuildChannel channel,
      Snowflake messageId, Message? message);
}

typedef GuildMessageDeleteBulkArgs = ({
  Guild guild,
  GuildChannel channel,
  List<Snowflake> messageIds,
  Map<Snowflake, Message> messages,
});

abstract class GuildMessageDeleteBulkEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildMessageDeleteBulk;

  @override
  Function get handler => (GuildMessageDeleteBulkArgs p) =>
      handle(p.guild, p.channel, p.messageIds, p.messages);

  FutureOr<void> handle(Guild guild, GuildChannel channel,
      List<Snowflake> messageIds, Map<Snowflake, Message> messages);
}

typedef GuildMessageReactionAddArgs = ({MessageReaction reaction});

abstract class GuildMessageReactionAddEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildMessageReactionAdd;

  @override
  Function get handler =>
      (GuildMessageReactionAddArgs p) => handle(p.reaction);

  FutureOr<void> handle(MessageReaction reaction);
}

typedef GuildMessageReactionRemoveArgs = ({MessageReaction reaction});

abstract class GuildMessageReactionRemoveEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildMessageReactionRemove;

  @override
  Function get handler =>
      (GuildMessageReactionRemoveArgs p) => handle(p.reaction);

  FutureOr<void> handle(MessageReaction reaction);
}

typedef GuildMessageReactionRemoveAllArgs = ({
  Guild guild,
  GuildTextChannel channel,
  Message message
});

abstract class GuildMessageReactionRemoveAllEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildMessageReactionRemoveAll;

  @override
  Function get handler => (GuildMessageReactionRemoveAllArgs p) =>
      handle(p.guild, p.channel, p.message);

  FutureOr<void> handle(
      Guild guild, GuildTextChannel channel, Message message);
}

typedef GuildMessageReactionRemoveEmojiArgs = ({
  Guild guild,
  GuildTextChannel channel,
  Message message,
  PartialEmoji emoji
});

abstract class GuildMessageReactionRemoveEmojiEvent
    extends BaseListenableEvent {
  @override
  Event get event => Event.guildMessageReactionRemoveEmoji;

  @override
  Function get handler => (GuildMessageReactionRemoveEmojiArgs p) =>
      handle(p.guild, p.channel, p.message, p.emoji);

  FutureOr<void> handle(
      Guild guild, GuildTextChannel channel, Message message, PartialEmoji emoji);
}

typedef GuildModalSubmitArgs<T> = ({GuildModalContext ctx, T data});

abstract class GuildModalSubmitEvent<T> extends BaseListenableEvent {
  @override
  Event get event => Event.guildModalSubmit;

  @override
  Function get handler => (GuildModalSubmitArgs<T> p) => handle(p.ctx, p.data);

  FutureOr<void> handle(GuildModalContext ctx, T data);
}

typedef GuildPollVoteAddArgs = ({PollAnswerVote<Message> answer, User user});

abstract class GuildPollVoteAddEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildPollVoteAdd;

  @override
  Function get handler => (GuildPollVoteAddArgs p) => handle(p.answer, p.user);

  FutureOr<void> handle(PollAnswerVote<Message> answer, User user);
}

typedef GuildPollVoteRemoveArgs = ({
  PollAnswerVote<Message> answer,
  User user
});

abstract class GuildPollVoteRemoveEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildPollVoteRemove;

  @override
  Function get handler =>
      (GuildPollVoteRemoveArgs p) => handle(p.answer, p.user);

  FutureOr<void> handle(PollAnswerVote<Message> answer, User user);
}

typedef GuildPresenceUpdateArgs = ({Member member, Presence presence});

abstract class GuildPresenceUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildPresenceUpdate;

  @override
  Function get handler =>
      (GuildPresenceUpdateArgs p) => handle(p.member, p.presence);

  FutureOr<void> handle(Member member, Presence presence);
}

typedef GuildRoleCreateArgs = ({Guild guild, Role role});

abstract class GuildRolesCreateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildRoleCreate;

  @override
  Function get handler => (GuildRoleCreateArgs p) => handle(p.guild, p.role);

  FutureOr<void> handle(Guild guild, Role role);
}

typedef GuildRoleDeleteArgs = ({Guild guild, Role? role});

abstract class GuildRolesDeleteEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildRoleDelete;

  @override
  Function get handler => (GuildRoleDeleteArgs p) => handle(p.guild, p.role);

  FutureOr<void> handle(Guild guild, Role? role);
}

typedef GuildRoleUpdateArgs = ({Guild guild, Role? before, Role after});

abstract class GuildRolesUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildRoleUpdate;

  @override
  Function get handler =>
      (GuildRoleUpdateArgs p) => handle(p.guild, p.before, p.after);

  FutureOr<void> handle(Guild guild, Role? before, Role after);
}

typedef GuildRuleCreateArgs = ({AutoModerationRule rule});

abstract class GuildRuleCreateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildRuleCreate;

  @override
  Function get handler => (GuildRuleCreateArgs p) => handle(p.rule);

  FutureOr<void> handle(AutoModerationRule rule);
}

typedef GuildRuleDeleteArgs = ({AutoModerationRule rule});

abstract class GuildRuleDeleteEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildRuleDelete;

  @override
  Function get handler => (GuildRuleDeleteArgs p) => handle(p.rule);

  FutureOr<void> handle(AutoModerationRule rule);
}

typedef GuildRuleExecutionArgs = ({RuleExecution execution});

abstract class GuildRuleExecutionEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildRuleExecution;

  @override
  Function get handler => (GuildRuleExecutionArgs p) => handle(p.execution);

  FutureOr<void> handle(RuleExecution execution);
}

typedef GuildRuleUpdateArgs = ({
  AutoModerationRule? before,
  AutoModerationRule after
});

abstract class GuildRuleUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildRuleUpdate;

  @override
  Function get handler => (GuildRuleUpdateArgs p) => handle(p.before, p.after);

  FutureOr<void> handle(AutoModerationRule? before, AutoModerationRule after);
}

typedef GuildChannelSelectArgs = ({
  GuildSelectContext ctx,
  List<GuildChannel> channels
});

abstract class GuildChannelSelectEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildChannelSelect;

  @override
  Function get handler =>
      (GuildChannelSelectArgs p) => handle(p.ctx, p.channels);

  FutureOr<void> handle(GuildSelectContext ctx, List<GuildChannel> channels);
}

typedef GuildMemberSelectArgs = ({
  GuildSelectContext ctx,
  List<Member> members
});

abstract class GuildMemberSelectEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildMemberSelect;

  @override
  Function get handler =>
      (GuildMemberSelectArgs p) => handle(p.ctx, p.members);

  FutureOr<void> handle(GuildSelectContext ctx, List<Member> members);
}

typedef GuildMentionableSelectArgs = ({
  GuildSelectContext ctx,
  List<dynamic> mentionables
});

abstract class GuildMentionableSelectEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildMentionableSelect;

  @override
  Function get handler =>
      (GuildMentionableSelectArgs p) => handle(p.ctx, p.mentionables);

  FutureOr<void> handle(GuildSelectContext ctx, List<dynamic> mentionables);
}

typedef GuildRoleSelectArgs = ({GuildSelectContext ctx, List<Role> roles});

abstract class GuildRoleSelectEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildRoleSelect;

  @override
  Function get handler => (GuildRoleSelectArgs p) => handle(p.ctx, p.roles);

  FutureOr<void> handle(GuildSelectContext ctx, List<Role> roles);
}

typedef GuildTextSelectArgs = ({GuildSelectContext ctx, List<String> values});

abstract class GuildTextSelectEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildTextSelect;

  @override
  Function get handler => (GuildTextSelectArgs p) => handle(p.ctx, p.values);

  FutureOr<void> handle(GuildSelectContext ctx, List<String> values);
}

typedef GuildThreadCreateArgs = ({Guild guild, ThreadChannel channel});

abstract class GuildThreadCreateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildThreadCreate;

  @override
  Function get handler =>
      (GuildThreadCreateArgs p) => handle(p.guild, p.channel);

  FutureOr<void> handle(Guild guild, ThreadChannel channel);
}

typedef GuildThreadDeleteArgs = ({ThreadChannel? thread, Guild guild});

abstract class GuildThreadDeleteEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildThreadDelete;

  @override
  Function get handler =>
      (GuildThreadDeleteArgs p) => handle(p.thread, p.guild);

  FutureOr<void> handle(ThreadChannel? thread, Guild guild);
}

typedef GuildThreadListSyncArgs = ({
  List<ThreadChannel> threads,
  Guild guild
});

abstract class GuildThreadListSyncEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildThreadListSync;

  @override
  Function get handler =>
      (GuildThreadListSyncArgs p) => handle(p.threads, p.guild);

  FutureOr<void> handle(List<ThreadChannel> threads, Guild guild);
}

typedef GuildThreadMemberArgs = ({
  ThreadChannel thread,
  Guild guild,
  Member member
});

abstract class GuildThreadMemberAddEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildThreadMemberAdd;

  @override
  Function get handler =>
      (GuildThreadMemberArgs p) => handle(p.thread, p.guild, p.member);

  FutureOr<void> handle(ThreadChannel thread, Guild guild, Member member);
}

abstract class GuildThreadMemberRemoveEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildThreadMemberRemove;

  @override
  Function get handler =>
      (GuildThreadMemberArgs p) => handle(p.thread, p.guild, p.member);

  FutureOr<void> handle(ThreadChannel thread, Guild guild, Member member);
}

abstract class GuildThreadMemberUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildThreadMemberUpdate;

  @override
  Function get handler =>
      (GuildThreadMemberArgs p) => handle(p.thread, p.guild, p.member);

  FutureOr<void> handle(ThreadChannel thread, Guild guild, Member member);
}

typedef GuildWebhooksUpdateArgs = ({Guild guild, GuildChannel? channel});

abstract class GuildWebhooksUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildWebhooksUpdate;

  @override
  Function get handler =>
      (GuildWebhooksUpdateArgs p) => handle(p.guild, p.channel);

  FutureOr<void> handle(Guild guild, GuildChannel? channel);
}

typedef GuildThreadUpdateArgs = ({
  Guild guild,
  ThreadChannel? before,
  ThreadChannel after
});

abstract class GuildThreadUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildThreadUpdate;

  @override
  Function get handler =>
      (GuildThreadUpdateArgs p) => handle(p.guild, p.before, p.after);

  FutureOr<void> handle(
      Guild guild, ThreadChannel? before, ThreadChannel after);
}

typedef GuildApplicationCommandPermissionsUpdateArgs = ({
  Guild guild,
  GuildApplicationCommandPermissions permissions
});

abstract class GuildApplicationCommandPermissionsUpdateEvent
    extends BaseListenableEvent {
  @override
  Event get event => Event.guildApplicationCommandPermissionsUpdate;

  @override
  Function get handler =>
      (GuildApplicationCommandPermissionsUpdateArgs p) =>
          handle(p.guild, p.permissions);

  FutureOr<void> handle(
      Guild guild, GuildApplicationCommandPermissions permissions);
}

typedef GuildIntegrationsUpdateArgs = ({Guild guild});

abstract class GuildIntegrationsUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildIntegrationsUpdate;

  @override
  Function get handler =>
      (GuildIntegrationsUpdateArgs p) => handle(p.guild);

  FutureOr<void> handle(Guild guild);
}

typedef GuildIntegrationCreateArgs = ({Guild guild, Integration integration});

abstract class GuildIntegrationCreateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildIntegrationCreate;

  @override
  Function get handler =>
      (GuildIntegrationCreateArgs p) => handle(p.guild, p.integration);

  FutureOr<void> handle(Guild guild, Integration integration);
}

typedef GuildIntegrationUpdateArgs = ({Guild guild, Integration integration});

abstract class GuildIntegrationUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildIntegrationUpdate;

  @override
  Function get handler =>
      (GuildIntegrationUpdateArgs p) => handle(p.guild, p.integration);

  FutureOr<void> handle(Guild guild, Integration integration);
}

typedef GuildIntegrationDeleteArgs = ({
  Guild guild,
  Snowflake integrationId,
  Snowflake? applicationId
});

abstract class GuildIntegrationDeleteEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildIntegrationDelete;

  @override
  Function get handler => (GuildIntegrationDeleteArgs p) =>
      handle(p.guild, p.integrationId, p.applicationId);

  FutureOr<void> handle(
      Guild guild, Snowflake integrationId, Snowflake? applicationId);
}

typedef GuildScheduledEventCreateArgs = ({
  Guild guild,
  GuildScheduledEvent event
});

abstract class GuildScheduledEventCreateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildScheduledEventCreate;

  @override
  Function get handler => (GuildScheduledEventCreateArgs p) =>
      handle(p.guild, p.event);

  FutureOr<void> handle(Guild guild, GuildScheduledEvent event);
}

typedef GuildScheduledEventUpdateArgs = ({
  Guild guild,
  GuildScheduledEvent? before,
  GuildScheduledEvent after
});

abstract class GuildScheduledEventUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildScheduledEventUpdate;

  @override
  Function get handler => (GuildScheduledEventUpdateArgs p) =>
      handle(p.guild, p.before, p.after);

  FutureOr<void> handle(
      Guild guild, GuildScheduledEvent? before, GuildScheduledEvent after);
}

typedef GuildScheduledEventDeleteArgs = ({
  Guild guild,
  GuildScheduledEvent event
});

abstract class GuildScheduledEventDeleteEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildScheduledEventDelete;

  @override
  Function get handler => (GuildScheduledEventDeleteArgs p) =>
      handle(p.guild, p.event);

  FutureOr<void> handle(Guild guild, GuildScheduledEvent event);
}

typedef GuildScheduledEventUserAddArgs = ({
  Guild guild,
  Snowflake eventId,
  User user
});

abstract class GuildScheduledEventUserAddEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildScheduledEventUserAdd;

  @override
  Function get handler => (GuildScheduledEventUserAddArgs p) =>
      handle(p.guild, p.eventId, p.user);

  FutureOr<void> handle(Guild guild, Snowflake eventId, User user);
}

typedef GuildScheduledEventUserRemoveArgs = ({
  Guild guild,
  Snowflake eventId,
  User user
});

abstract class GuildScheduledEventUserRemoveEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildScheduledEventUserRemove;

  @override
  Function get handler => (GuildScheduledEventUserRemoveArgs p) =>
      handle(p.guild, p.eventId, p.user);

  FutureOr<void> handle(Guild guild, Snowflake eventId, User user);
}

typedef GuildVoiceChannelEffectSendArgs = ({
  Guild guild,
  GuildChannel channel,
  Member member,
  PartialEmoji? emoji,
  VoiceChannelEffectAnimationType? animationType,
  int? animationId,
  Snowflake? soundId,
  double? soundVolume,
});

abstract class GuildVoiceChannelEffectSendEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildVoiceChannelEffectSend;

  @override
  Function get handler => (GuildVoiceChannelEffectSendArgs p) => handle(
        p.guild,
        p.channel,
        p.member,
        p.emoji,
        p.animationType,
        p.animationId,
        p.soundId,
        p.soundVolume,
      );

  FutureOr<void> handle(
    Guild guild,
    GuildChannel channel,
    Member member,
    PartialEmoji? emoji,
    VoiceChannelEffectAnimationType? animationType,
    int? animationId,
    Snowflake? soundId,
    double? soundVolume,
  );
}

typedef GuildStageInstanceCreateArgs = ({
  Guild guild,
  StageInstance instance
});

abstract class GuildStageInstanceCreateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildStageInstanceCreate;

  @override
  Function get handler => (GuildStageInstanceCreateArgs p) =>
      handle(p.guild, p.instance);

  FutureOr<void> handle(Guild guild, StageInstance instance);
}

typedef GuildStageInstanceUpdateArgs = ({
  Guild guild,
  StageInstance instance
});

abstract class GuildStageInstanceUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildStageInstanceUpdate;

  @override
  Function get handler => (GuildStageInstanceUpdateArgs p) =>
      handle(p.guild, p.instance);

  FutureOr<void> handle(Guild guild, StageInstance instance);
}

typedef GuildStageInstanceDeleteArgs = ({
  Guild guild,
  StageInstance instance
});

abstract class GuildStageInstanceDeleteEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildStageInstanceDelete;

  @override
  Function get handler => (GuildStageInstanceDeleteArgs p) =>
      handle(p.guild, p.instance);

  FutureOr<void> handle(Guild guild, StageInstance instance);
}

typedef GuildSoundboardSoundCreateArgs = ({
  Guild guild,
  SoundboardSound sound
});

abstract class GuildSoundboardSoundCreateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildSoundboardSoundCreate;

  @override
  Function get handler => (GuildSoundboardSoundCreateArgs p) =>
      handle(p.guild, p.sound);

  FutureOr<void> handle(Guild guild, SoundboardSound sound);
}

typedef GuildSoundboardSoundUpdateArgs = ({
  Guild guild,
  SoundboardSound sound
});

abstract class GuildSoundboardSoundUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildSoundboardSoundUpdate;

  @override
  Function get handler => (GuildSoundboardSoundUpdateArgs p) =>
      handle(p.guild, p.sound);

  FutureOr<void> handle(Guild guild, SoundboardSound sound);
}

typedef GuildSoundboardSoundDeleteArgs = ({Guild guild, Snowflake soundId});

abstract class GuildSoundboardSoundDeleteEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildSoundboardSoundDelete;

  @override
  Function get handler => (GuildSoundboardSoundDeleteArgs p) =>
      handle(p.guild, p.soundId);

  FutureOr<void> handle(Guild guild, Snowflake soundId);
}

typedef GuildSoundboardSoundsUpdateArgs = ({
  Guild guild,
  List<SoundboardSound> sounds
});

abstract class GuildSoundboardSoundsUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildSoundboardSoundsUpdate;

  @override
  Function get handler => (GuildSoundboardSoundsUpdateArgs p) =>
      handle(p.guild, p.sounds);

  FutureOr<void> handle(Guild guild, List<SoundboardSound> sounds);
}

typedef GuildSoundboardSoundsArgs = ({
  Guild guild,
  List<SoundboardSound> sounds
});

abstract class GuildSoundboardSoundsEvent extends BaseListenableEvent {
  @override
  Event get event => Event.guildSoundboardSounds;

  @override
  Function get handler =>
      (GuildSoundboardSoundsArgs p) => handle(p.guild, p.sounds);

  FutureOr<void> handle(Guild guild, List<SoundboardSound> sounds);
}
