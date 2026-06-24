import 'dart:async';

import 'package:mineral/api.dart';
import 'package:mineral/src/api/common/polls/poll_answer_vote.dart';
import 'package:mineral/src/api/guild/audit_log/audit_log.dart';
import 'package:mineral/src/domains/events/contracts/guild_events.dart';
import 'package:mineral/src/domains/events/event.dart';
import 'package:mineral/src/domains/events/event_bucket.dart';

final class GuildBucket {
  final EventBucket _events;

  GuildBucket(this._events);

  void guildCreate(FutureOr<void> Function(Guild guild) handle) =>
      _events.make(Event.guildCreate, (GuildCreateArgs p) => handle(p.guild));

  void guildUpdate(
    FutureOr<void> Function(Guild? before, Guild after) handle,
  ) => _events.make(
    Event.guildUpdate,
    (GuildUpdateArgs p) => handle(p.before, p.after),
  );

  void guildDelete(FutureOr<void> Function(Guild? guild) handle) =>
      _events.make(Event.guildDelete, (GuildDeleteArgs p) => handle(p.guild));

  void messageCreate(FutureOr<void> Function(GuildMessage message) handle) =>
      _events.make(
        Event.guildMessageCreate,
        (GuildMessageCreateArgs p) => handle(p.message),
      );

  void messageUpdate(
    FutureOr<void> Function(GuildMessage? before, GuildMessage after) handle,
  ) => _events.make(
    Event.guildMessageUpdate,
    (GuildMessageUpdateArgs p) => handle(p.before, p.after),
  );

  void messageDelete(
    FutureOr<void> Function(
      Guild guild,
      GuildChannel channel,
      Snowflake messageId,
      Message? message,
    )
    handle,
  ) => _events.make(
    Event.guildMessageDelete,
    (GuildMessageDeleteArgs p) =>
        handle(p.guild, p.channel, p.messageId, p.message),
  );

  void messageDeleteBulk(
    FutureOr<void> Function(
      Guild guild,
      GuildChannel channel,
      List<Snowflake> messageIds,
      Map<Snowflake, Message> messages,
    )
    handle,
  ) => _events.make(
    Event.guildMessageDeleteBulk,
    (GuildMessageDeleteBulkArgs p) =>
        handle(p.guild, p.channel, p.messageIds, p.messages),
  );

  void channelCreate(FutureOr<void> Function(GuildChannel channel) handle) =>
      _events.make(
        Event.guildChannelCreate,
        (GuildChannelCreateArgs p) => handle(p.channel),
      );

  void channelUpdate(
    FutureOr<void> Function(GuildChannel? before, GuildChannel after) handle,
  ) => _events.make(
    Event.guildChannelUpdate,
    (GuildChannelUpdateArgs p) => handle(p.before, p.after),
  );

  void channelDelete(FutureOr<void> Function(GuildChannel? channel) handle) =>
      _events.make(
        Event.guildChannelDelete,
        (GuildChannelDeleteArgs p) => handle(p.channel),
      );

  void channelPinsUpdate(
    FutureOr<void> Function(Guild guild, GuildChannel channel) handle,
  ) => _events.make(
    Event.guildChannelPinsUpdate,
    (GuildChannelPinsUpdateArgs p) => handle(p.guild, p.channel),
  );

  void webhooksUpdate(
    FutureOr<void> Function(Guild guild, GuildChannel? channel) handle,
  ) => _events.make(
    Event.guildWebhooksUpdate,
    (GuildWebhooksUpdateArgs p) => handle(p.guild, p.channel),
  );

  void memberAdd(FutureOr<void> Function(Member member, Guild guild) handle) =>
      _events.make(
        Event.guildMemberAdd,
        (GuildMemberAddArgs p) => handle(p.member, p.guild),
      );

  void memberRemove(FutureOr<void> Function(User? user, Guild guild) handle) =>
      _events.make(
        Event.guildMemberRemove,
        (GuildMemberRemoveArgs p) => handle(p.user, p.guild),
      );

  void memberUpdate(
    FutureOr<void> Function(Guild guild, Member after, Member before) handle,
  ) => _events.make(
    Event.guildMemberUpdate,
    (GuildMemberUpdateArgs p) => handle(p.guild, p.after, p.before),
  );

  void memberChunk(
    FutureOr<void> Function(Guild guild, List<Member> members) handle,
  ) => _events.make(
    Event.guildMemberChunk,
    (GuildMemberChunkArgs p) => handle(p.guild, p.members),
  );

  void roleCreate(FutureOr<void> Function(Guild guild, Role role) handle) =>
      _events.make(
        Event.guildRoleCreate,
        (GuildRoleCreateArgs p) => handle(p.guild, p.role),
      );

  void roleUpdate(
    FutureOr<void> Function(Guild guild, Role? before, Role after) handle,
  ) => _events.make(
    Event.guildRoleUpdate,
    (GuildRoleUpdateArgs p) => handle(p.guild, p.before, p.after),
  );

  void roleDelete(FutureOr<void> Function(Guild guild, Role? role) handle) =>
      _events.make(
        Event.guildRoleDelete,
        (GuildRoleDeleteArgs p) => handle(p.guild, p.role),
      );

  void presenceUpdate(
    FutureOr<void> Function(Member member, Presence presence) handle,
  ) => _events.make(
    Event.guildPresenceUpdate,
    (GuildPresenceUpdateArgs p) => handle(p.member, p.presence),
  );

  void banAdd(FutureOr<void> Function(User user, Guild guild) handle) => _events
      .make(Event.guildBanAdd, (GuildBanAddArgs p) => handle(p.user, p.guild));

  void banRemove(FutureOr<void> Function(User user, Guild guild) handle) =>
      _events.make(
        Event.guildBanRemove,
        (GuildBanRemoveArgs p) => handle(p.user, p.guild),
      );

  void emojisUpdate(
    FutureOr<void> Function(Map<Snowflake, Emoji> emojis, Guild guild) handle,
  ) => _events.make(
    Event.guildEmojisUpdate,
    (GuildEmojisUpdateArgs p) => handle(p.emojis, p.guild),
  );

  void stickersUpdate(
    FutureOr<void> Function(Guild guild, Map<Snowflake, Sticker> stickers)
    handle,
  ) => _events.make(
    Event.guildStickersUpdate,
    (GuildStickersUpdateArgs p) => handle(p.guild, p.stickers),
  );

  void buttonClick(
    FutureOr<void> Function(GuildButtonContext ctx) handle, {
    String? customId,
  }) => _events.make(
    Event.guildButtonClick,
    (GuildButtonClickArgs p) => handle(p.ctx),
    customId: customId,
  );

  void modalSubmit<T>(
    FutureOr<void> Function(GuildModalContext ctx, T data) handle, {
    String? customId,
  }) => _events.make(
    Event.guildModalSubmit,
    (GuildModalSubmitArgs<T> p) => handle(p.ctx, p.data),
    customId: customId,
  );

  void selectChannel(
    FutureOr<void> Function(GuildSelectContext ctx, List<GuildChannel> channels)
    handle, {
    String? customId,
  }) => _events.make(
    Event.guildChannelSelect,
    (GuildChannelSelectArgs p) => handle(p.ctx, p.channels),
    customId: customId,
  );

  void selectRole(
    FutureOr<void> Function(GuildSelectContext ctx, List<Role> roles) handle, {
    String? customId,
  }) => _events.make(
    Event.guildRoleSelect,
    (GuildRoleSelectArgs p) => handle(p.ctx, p.roles),
    customId: customId,
  );

  void selectMember(
    FutureOr<void> Function(GuildSelectContext ctx, List<Member> members)
    handle, {
    String? customId,
  }) => _events.make(
    Event.guildMemberSelect,
    (GuildMemberSelectArgs p) => handle(p.ctx, p.members),
    customId: customId,
  );

  void selectText(
    FutureOr<void> Function(GuildSelectContext ctx, List<String> values)
    handle, {
    String? customId,
  }) => _events.make(
    Event.guildTextSelect,
    (GuildTextSelectArgs p) => handle(p.ctx, p.values),
    customId: customId,
  );

  void threadCreate(
    FutureOr<void> Function(Guild guild, ThreadChannel channel) handle,
  ) => _events.make(
    Event.guildThreadCreate,
    (GuildThreadCreateArgs p) => handle(p.guild, p.channel),
  );

  void threadUpdate(
    FutureOr<void> Function(
      Guild guild,
      ThreadChannel? before,
      ThreadChannel after,
    )
    handle,
  ) => _events.make(
    Event.guildThreadUpdate,
    (GuildThreadUpdateArgs p) => handle(p.guild, p.before, p.after),
  );

  void threadDelete(
    FutureOr<void> Function(ThreadChannel? thread, Guild guild) handle,
  ) => _events.make(
    Event.guildThreadDelete,
    (GuildThreadDeleteArgs p) => handle(p.thread, p.guild),
  );

  void threadMemberUpdate(
    FutureOr<void> Function(ThreadChannel thread, Guild guild, Member member)
    handle,
  ) => _events.make(
    Event.guildThreadMemberUpdate,
    (GuildThreadMemberArgs p) => handle(p.thread, p.guild, p.member),
  );

  void threadMemberAdd(
    FutureOr<void> Function(ThreadChannel thread, Guild guild, Member member)
    handle,
  ) => _events.make(
    Event.guildThreadMemberAdd,
    (GuildThreadMemberArgs p) => handle(p.thread, p.guild, p.member),
  );

  void threadMemberRemove(
    FutureOr<void> Function(ThreadChannel thread, Guild guild, Member member)
    handle,
  ) => _events.make(
    Event.guildThreadMemberRemove,
    (GuildThreadMemberArgs p) => handle(p.thread, p.guild, p.member),
  );

  void messageReactionAdd(
    FutureOr<void> Function(MessageReaction reaction) handle,
  ) => _events.make(
    Event.guildMessageReactionAdd,
    (GuildMessageReactionAddArgs p) => handle(p.reaction),
  );

  void messageReactionRemove(
    FutureOr<void> Function(MessageReaction reaction) handle,
  ) => _events.make(
    Event.guildMessageReactionRemove,
    (GuildMessageReactionRemoveArgs p) => handle(p.reaction),
  );

  void messageReactionRemoveAll(
    FutureOr<void> Function(
      Guild guild,
      GuildTextChannel channel,
      Message message,
    )
    handle,
  ) => _events.make(
    Event.guildMessageReactionRemoveAll,
    (GuildMessageReactionRemoveAllArgs p) =>
        handle(p.guild, p.channel, p.message),
  );

  void messageReactionRemoveEmoji(
    FutureOr<void> Function(
      Guild guild,
      GuildTextChannel channel,
      Message message,
      PartialEmoji emoji,
    )
    handle,
  ) => _events.make(
    Event.guildMessageReactionRemoveEmoji,
    (GuildMessageReactionRemoveEmojiArgs p) =>
        handle(p.guild, p.channel, p.message, p.emoji),
  );

  void auditLog(FutureOr<void> Function(AuditLog audit) handle) => _events.make(
    Event.guildAuditLog,
    (GuildAuditLogArgs p) => handle(p.audit),
  );

  void pollVoteAdd(
    FutureOr<void> Function(PollAnswerVote<Message> answer, User user) handle,
  ) => _events.make(
    Event.guildPollVoteAdd,
    (GuildPollVoteAddArgs p) => handle(p.answer, p.user),
  );

  void pollVoteRemove(
    FutureOr<void> Function(PollAnswerVote<Message> answer, User user) handle,
  ) => _events.make(
    Event.guildPollVoteRemove,
    (GuildPollVoteRemoveArgs p) => handle(p.answer, p.user),
  );

  void ruleCreate(FutureOr<void> Function(AutoModerationRule rule) handle) =>
      _events.make(
        Event.guildRuleCreate,
        (GuildRuleCreateArgs p) => handle(p.rule),
      );

  void ruleUpdate(
    FutureOr<void> Function(
      AutoModerationRule? before,
      AutoModerationRule after,
    )
    handle,
  ) => _events.make(
    Event.guildRuleUpdate,
    (GuildRuleUpdateArgs p) => handle(p.before, p.after),
  );

  void ruleDelete(FutureOr<void> Function(AutoModerationRule rule) handle) =>
      _events.make(
        Event.guildRuleDelete,
        (GuildRuleDeleteArgs p) => handle(p.rule),
      );

  void ruleExecution(FutureOr<void> Function(RuleExecution execution) handle) =>
      _events.make(
        Event.guildRuleExecution,
        (GuildRuleExecutionArgs p) => handle(p.execution),
      );

  void integrationsUpdate(FutureOr<void> Function(Guild guild) handle) =>
      _events.make(
        Event.guildIntegrationsUpdate,
        (GuildIntegrationsUpdateArgs p) => handle(p.guild),
      );

  void integrationCreate(
    FutureOr<void> Function(Guild guild, Integration integration) handle,
  ) => _events.make(
    Event.guildIntegrationCreate,
    (GuildIntegrationCreateArgs p) => handle(p.guild, p.integration),
  );

  void integrationUpdate(
    FutureOr<void> Function(Guild guild, Integration integration) handle,
  ) => _events.make(
    Event.guildIntegrationUpdate,
    (GuildIntegrationUpdateArgs p) => handle(p.guild, p.integration),
  );

  void integrationDelete(
    FutureOr<void> Function(
      Guild guild,
      Snowflake integrationId,
      Snowflake? applicationId,
    )
    handle,
  ) => _events.make(
    Event.guildIntegrationDelete,
    (GuildIntegrationDeleteArgs p) =>
        handle(p.guild, p.integrationId, p.applicationId),
  );

  void applicationCommandPermissionsUpdate(
    FutureOr<void> Function(
      Guild guild,
      GuildApplicationCommandPermissions permissions,
    )
    handle,
  ) => _events.make(
    Event.guildApplicationCommandPermissionsUpdate,
    (GuildApplicationCommandPermissionsUpdateArgs p) =>
        handle(p.guild, p.permissions),
  );

  void scheduledEventCreate(
    FutureOr<void> Function(Guild guild, GuildScheduledEvent event) handle,
  ) => _events.make(
    Event.guildScheduledEventCreate,
    (GuildScheduledEventCreateArgs p) => handle(p.guild, p.event),
  );

  void scheduledEventUpdate(
    FutureOr<void> Function(
      Guild guild,
      GuildScheduledEvent? before,
      GuildScheduledEvent after,
    )
    handle,
  ) => _events.make(
    Event.guildScheduledEventUpdate,
    (GuildScheduledEventUpdateArgs p) => handle(p.guild, p.before, p.after),
  );

  void scheduledEventDelete(
    FutureOr<void> Function(Guild guild, GuildScheduledEvent event) handle,
  ) => _events.make(
    Event.guildScheduledEventDelete,
    (GuildScheduledEventDeleteArgs p) => handle(p.guild, p.event),
  );

  void scheduledEventUserAdd(
    FutureOr<void> Function(Guild guild, Snowflake eventId, User user) handle,
  ) => _events.make(
    Event.guildScheduledEventUserAdd,
    (GuildScheduledEventUserAddArgs p) => handle(p.guild, p.eventId, p.user),
  );

  void scheduledEventUserRemove(
    FutureOr<void> Function(Guild guild, Snowflake eventId, User user) handle,
  ) => _events.make(
    Event.guildScheduledEventUserRemove,
    (GuildScheduledEventUserRemoveArgs p) => handle(p.guild, p.eventId, p.user),
  );

  void voiceChannelEffectSend(
    FutureOr<void> Function(
      Guild guild,
      GuildChannel channel,
      Member member,
      PartialEmoji? emoji,
      VoiceChannelEffectAnimationType? animationType,
      int? animationId,
      Snowflake? soundId,
      double? soundVolume,
    )
    handle,
  ) => _events.make(
    Event.guildVoiceChannelEffectSend,
    (GuildVoiceChannelEffectSendArgs p) => handle(
      p.guild,
      p.channel,
      p.member,
      p.emoji,
      p.animationType,
      p.animationId,
      p.soundId,
      p.soundVolume,
    ),
  );

  void stageInstanceCreate(
    FutureOr<void> Function(Guild guild, StageInstance instance) handle,
  ) => _events.make(
    Event.guildStageInstanceCreate,
    (GuildStageInstanceCreateArgs p) => handle(p.guild, p.instance),
  );

  void stageInstanceUpdate(
    FutureOr<void> Function(Guild guild, StageInstance instance) handle,
  ) => _events.make(
    Event.guildStageInstanceUpdate,
    (GuildStageInstanceUpdateArgs p) => handle(p.guild, p.instance),
  );

  void stageInstanceDelete(
    FutureOr<void> Function(Guild guild, StageInstance instance) handle,
  ) => _events.make(
    Event.guildStageInstanceDelete,
    (GuildStageInstanceDeleteArgs p) => handle(p.guild, p.instance),
  );

  void soundboardSoundCreate(
    FutureOr<void> Function(Guild guild, SoundboardSound sound) handle,
  ) => _events.make(
    Event.guildSoundboardSoundCreate,
    (GuildSoundboardSoundCreateArgs p) => handle(p.guild, p.sound),
  );

  void soundboardSoundUpdate(
    FutureOr<void> Function(Guild guild, SoundboardSound sound) handle,
  ) => _events.make(
    Event.guildSoundboardSoundUpdate,
    (GuildSoundboardSoundUpdateArgs p) => handle(p.guild, p.sound),
  );

  void soundboardSoundDelete(
    FutureOr<void> Function(Guild guild, Snowflake soundId) handle,
  ) => _events.make(
    Event.guildSoundboardSoundDelete,
    (GuildSoundboardSoundDeleteArgs p) => handle(p.guild, p.soundId),
  );

  void soundboardSoundsUpdate(
    FutureOr<void> Function(Guild guild, List<SoundboardSound> sounds) handle,
  ) => _events.make(
    Event.guildSoundboardSoundsUpdate,
    (GuildSoundboardSoundsUpdateArgs p) => handle(p.guild, p.sounds),
  );

  void soundboardSounds(
    FutureOr<void> Function(Guild guild, List<SoundboardSound> sounds) handle,
  ) => _events.make(
    Event.guildSoundboardSounds,
    (GuildSoundboardSoundsArgs p) => handle(p.guild, p.sounds),
  );
}
