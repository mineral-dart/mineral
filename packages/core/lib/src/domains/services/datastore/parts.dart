import 'package:mineral/api.dart';
import 'package:mineral/src/api/common/polls/poll_answer_vote.dart';
import 'package:mineral/src/api/guild/channels/private_thread_channel.dart';
import 'package:mineral/src/api/guild/channels/public_thread_channel.dart';
import 'package:mineral/src/api/guild/moderation/enums/auto_moderation_event_type.dart';
import 'package:mineral/src/api/guild/moderation/enums/trigger_type.dart';
import 'package:mineral/src/api/guild/moderation/trigger_metadata.dart';

abstract interface class DataStorePart {}

abstract interface class ChannelPartContract implements DataStorePart {
  Future<Map<Snowflake, T>> fetch<T extends Channel>(
    Object guildId,
    bool force,
  );

  Future<T?> get<T extends Channel>(Object id, bool force);

  Future<T> create<T extends Channel>(
    Object? guildId,
    ChannelBuilderContract builder, {
    String? reason,
  });

  Future<PrivateChannel?> createPrivateChannel(Object id, String recipientId);

  Future<T?> update<T extends Channel>(
    Object id,
    ChannelBuilderContract builder, {
    Object? guildId,
    String? reason,
  });

  Future<void> delete(Object id, String? reason);
}

abstract interface class ThreadPartContract implements DataStorePart {
  Future<ThreadResult> fetchActives(Object guildId);

  Future<Map<Snowflake, PublicThreadChannel>> fetchPublicArchived(
    Object channelId,
  );

  Future<Map<Snowflake, PrivateThreadChannel>> fetchPrivateArchived(
    Object channelId,
  );

  Future<T> createWithoutMessage<T extends ThreadChannel>(
    Object? guildId,
    Object? channelId,
    ThreadChannelBuilder builder, {
    String? reason,
  });

  Future<T> createFromMessage<T extends ThreadChannel>(
    Object? guildId,
    Object? channelId,
    Object? messageId,
    ThreadChannelBuilder builder, {
    String? reason,
  });
}

abstract interface class InteractionPartContract implements DataStorePart {
  Future<void> replyInteraction(
    Snowflake id,
    String token,
    MessageBuilder builder,
    bool ephemeral,
  );

  Future<void> editInteraction(
    Snowflake botId,
    String token,
    MessageBuilder builder,
    bool ephemeral,
  );

  Future<void> deleteInteraction(Snowflake botId, String token);

  Future<void> noReplyInteraction(Snowflake id, String token, bool ephemeral);

  Future<void> createFollowup(
    Snowflake botId,
    String token,
    MessageBuilder builder,
    bool ephemeral,
  );

  Future<void> editFollowup(
    Snowflake botId,
    String token,
    Snowflake messageId,
    MessageBuilder builder,
    bool ephemeral,
  );

  Future<void> deleteFollowup(
    Snowflake botId,
    String token,
    Snowflake messageId,
  );

  Future<void> waitInteraction(Snowflake id, String token);

  Future<void> sendModal(Snowflake id, String token, ModalBuilder modal);

  Future<void> sendAutocompleteResult(
    Snowflake id,
    String token,
    List<Choice> choices,
  );
}

abstract interface class MemberPartContract implements DataStorePart {
  Future<Map<Snowflake, Member>> fetch(Object guildId, bool force);

  Future<Member?> get(Object guildId, Object id, bool force);

  Future<Member> update({
    required Object guildId,
    required String memberId,
    required Map<String, dynamic> payload,
    String? reason,
  });

  Future<void> ban({
    required Object guildId,
    required Duration? deleteSince,
    required String memberId,
    String? reason,
  });

  Future<void> kick({
    required Object guildId,
    required String memberId,
    String? reason,
  });

  Future<VoiceState?> getVoiceState(Object guildId, String userId, bool force);
}

abstract interface class MessagePartContract implements DataStorePart {
  Future<Map<Snowflake, T>> fetch<T extends BaseMessage>(
    Object channelId, {
    Snowflake? around,
    Snowflake? before,
    Snowflake? after,
    int? limit,
  });

  Future<T?> get<T extends BaseMessage>(
    Object channelId,
    Object id,
    bool force,
  );

  Future<PollAnswerVote> getPollVotes(
    Snowflake? guildId,
    Snowflake channelId,
    Snowflake messageId,
    int answerId,
  );

  Future<T> update<T extends Message>({
    required Object id,
    required Object channelId,
    required MessageBuilder builder,
  });

  Future<void> pin(Snowflake channelId, Snowflake id);

  Future<void> unpin(Snowflake channelId, Snowflake id);

  Future<void> crosspost(Snowflake channelId, Snowflake id);

  Future<void> delete(Snowflake channelId, Snowflake id);

  Future<T> send<T extends Message>(
    String? guildId,
    String channelId,
    MessageBuilder builder,
  );

  Future<T> sendPoll<T extends Message>(String channelId, Poll poll);

  Future<R> reply<T extends Channel, R extends Message>(
    Snowflake id,
    Snowflake channelId,
    MessageBuilder builder,
  );

  /// Forward a message to another channel.
  ///
  /// Posts a `message_reference` with `type: 1` (FORWARD) to [targetChannelId].
  /// [messageId] is the id of the message being forwarded.
  /// [sourceChannelId] is the channel the original message lives in.
  /// [guildId] is optional; include it for guild messages.
  Future<T> forward<T extends Message>(
    Snowflake targetChannelId, {
    required Snowflake messageId,
    required Snowflake sourceChannelId,
    Snowflake? guildId,
  });
}

abstract interface class RolePartContract implements DataStorePart {
  Future<Map<Snowflake, Role>> fetch(Object guildId, bool force);

  Future<Role?> get(Object guildId, Object id, bool force);

  Future<Role> create(
    Object guildId,
    String name,
    List<Permission> permissions,
    Color color,
    bool hoist,
    bool mentionable,
    String? reason,
  );

  Future<void> add({
    required String memberId,
    required Object guildId,
    required String roleId,
    required String? reason,
  });

  Future<void> remove({
    required String memberId,
    required Object guildId,
    required String roleId,
    required String? reason,
  });

  Future<void> sync({
    required String memberId,
    required Object guildId,
    required List<String> roleIds,
    required String? reason,
  });

  Future<Role?> update({
    required Object id,
    required Object guildId,
    required Map<String, dynamic> payload,
    required String? reason,
  });

  Future<void> delete({
    required Object id,
    required String guildId,
    required String? reason,
  });
}

abstract interface class GuildPartContract implements DataStorePart {
  Future<Guild> get(Object id, bool force);

  Future<Guild> update(Object id, Map<String, dynamic> payload, String? reason);

  Future<void> delete(Object id, String? reason);
}

abstract interface class StickerPartContract implements DataStorePart {
  Future<Map<Snowflake, Sticker>> fetch(Object guildId, bool force);

  Future<Sticker?> get(Object guildId, Object id, bool force);

  Future<void> delete(Object guildId, Object stickerId);
}

abstract interface class UserPartContract implements DataStorePart {
  Future<User?> get(Object id, bool force);
}

abstract interface class EmojiPartContract implements DataStorePart {
  Future<Map<Snowflake, Emoji>> fetch(Object guildId, bool force);

  Future<Emoji?> get(Object guildId, Object id, bool force);

  Future<Emoji> create(
    Object guildId,
    String name,
    Image image,
    List<Object> roles, {
    String? reason,
  });

  Future<Emoji?> update({
    required Object id,
    required Object guildId,
    required Map<String, dynamic> payload,
    required String? reason,
  });

  Future<void> delete(Object guildId, String emojiId, {String? reason});
}

abstract interface class RulesPartContract implements DataStorePart {
  Future<Map<Snowflake, AutoModerationRule>> fetch(Object guildId, bool force);

  Future<AutoModerationRule?> get(Object guildId, Object id, bool force);

  Future<AutoModerationRule> create({
    required Object guildId,
    required String name,
    required AutoModerationEventType eventType,
    required TriggerType triggerType,
    required List<Action> actions,
    TriggerMetadata? triggerMetadata,
    List<Snowflake> exemptRoles = const [],
    List<Snowflake> exemptChannels = const [],
    bool enabled = true,
    String? reason,
  });

  Future<AutoModerationRule?> update({
    required Object id,
    required Object guildId,
    required Map<String, dynamic> payload,
    required String? reason,
  });

  Future<void> delete(Object guildId, Object ruleId, {String? reason});
}

abstract interface class ReactionPartContract implements DataStorePart {
  Future<Map<Snowflake, User>> getUsersForEmoji(
    Object channelId,
    Object messageId,
    PartialEmoji emoji,
  );

  Future<void> add(Object channelId, Object messageId, PartialEmoji emoji);

  Future<void> remove(Object channelId, Object messageId, PartialEmoji emoji);

  Future<void> removeAll(Object channelId, Object messageId);

  Future<void> removeForEmoji(
    Object channelId,
    Object messageId,
    PartialEmoji emoji,
  );

  Future<void> removeForUser(
    String userId,
    Object channelId,
    Object messageId,
    PartialEmoji emoji,
  );
}

abstract interface class WebhookPartContract implements DataStorePart {
  Future<Map<Snowflake, Webhook>> fetchForChannel(Object channelId);

  Future<Map<Snowflake, Webhook>> fetchForServer(Object guildId);

  Future<Webhook?> get(Object id, bool force);

  Future<Webhook?> getWithToken(Object id, String token);

  Future<Webhook> create({
    required Object channelId,
    required String name,
    String? avatar,
    String? reason,
  });

  Future<Webhook?> update({
    required Object id,
    String? name,
    String? avatar,
    Object? channelId,
    String? reason,
  });

  Future<Webhook?> updateWithToken({
    required Object id,
    required String token,
    String? name,
    String? avatar,
  });

  Future<void> delete({required Object id, String? reason});

  Future<void> deleteWithToken({required Object id, required String token});

  Future<Message?> execute({
    required Object id,
    required String token,
    required MessageBuilder builder,
    Object? threadId,
    bool wait,
  });

  Future<Message?> getMessage({
    required Object id,
    required String token,
    required Object messageId,
    Object? threadId,
  });

  Future<Message?> editMessage({
    required Object id,
    required String token,
    required Object messageId,
    required MessageBuilder builder,
    Object? threadId,
  });

  Future<void> deleteMessage({
    required Object id,
    required String token,
    required Object messageId,
    Object? threadId,
  });

  Future<void> executeGithub({
    required Object id,
    required String token,
    required Map<String, dynamic> payload,
    Object? threadId,
  });

  Future<void> executeSlack({
    required Object id,
    required String token,
    required Map<String, dynamic> payload,
    Object? threadId,
  });
}

abstract interface class GuildScheduledEventPartContract
    implements DataStorePart {
  Future<Map<Snowflake, GuildScheduledEvent>> fetchForServer(
    Object guildId, {
    bool? withUserCount,
  });

  Future<GuildScheduledEvent?> get(
    Object guildId,
    Object id,
    bool force, {
    bool? withUserCount,
  });

  Future<GuildScheduledEvent> create({
    required Object guildId,
    required String name,
    required GuildScheduledEventPrivacyLevel privacyLevel,
    required DateTime scheduledStartTime,
    required GuildScheduledEventEntityType entityType,
    Object? channelId,
    GuildScheduledEventEntityMetadata? entityMetadata,
    DateTime? scheduledEndTime,
    String? description,
    String? image,
    String? reason,
  });

  Future<GuildScheduledEvent?> update({
    required Object guildId,
    required Object id,
    Object? channelId,
    GuildScheduledEventEntityMetadata? entityMetadata,
    String? name,
    GuildScheduledEventPrivacyLevel? privacyLevel,
    DateTime? scheduledStartTime,
    DateTime? scheduledEndTime,
    String? description,
    GuildScheduledEventEntityType? entityType,
    GuildScheduledEventStatus? status,
    String? image,
    String? reason,
  });

  Future<void> delete({
    required Object guildId,
    required Object id,
    String? reason,
  });

  Future<List<GuildScheduledEventUser>> fetchUsers({
    required Object guildId,
    required Object id,
    int? limit,
    bool? withMember,
    Object? before,
    Object? after,
  });
}

abstract interface class InvitePartContract implements DataStorePart {
  Future<Invite?> get(String code, bool force);

  Future<InviteMetadata?> getExtrasMetadata(String code, bool force);

  Future<Invite> create({
    required Object channelId,
    Duration? maxAge,
    int? maxUses,
    bool? temporary,
    bool? unique,
    InviteTargetType? targetType,
    Object? targetUserId,
    Object? targetApplicationId,
    String? reason,
  });

  Future<void> delete(String code, String? reason);
}

abstract interface class ApplicationEmojiPartContract implements DataStorePart {
  Future<Map<Snowflake, Emoji>> fetch(Object applicationId);

  Future<Emoji?> get(Object applicationId, Object emojiId);

  Future<Emoji> create(Object applicationId, String name, Image image);

  Future<Emoji?> update(Object applicationId, Object emojiId, String name);

  Future<void> delete(Object applicationId, Object emojiId);
}

abstract interface class WelcomeScreenPartContract implements DataStorePart {
  Future<WelcomeScreen> fetch(Object guildId);

  Future<WelcomeScreen> update(
    Object guildId, {
    bool? enabled,
    List<Map<String, dynamic>>? welcomeChannels,
    String? description,
    String? reason,
  });
}

abstract interface class OnboardingPartContract implements DataStorePart {
  Future<Onboarding> fetch(Object guildId);

  Future<Onboarding> update(
    Object guildId, {
    List<OnboardingPrompt>? prompts,
    List<Object>? defaultChannelIds,
    bool? enabled,
    OnboardingMode? mode,
    String? reason,
  });
}

abstract interface class TemplatePartContract implements DataStorePart {
  Future<Map<String, GuildTemplate>> fetchForServer(Object guildId);

  Future<GuildTemplate> getByCode(String code);

  Future<GuildTemplate> create(
    Object guildId, {
    required String name,
    String? description,
  });

  Future<GuildTemplate> sync(Object guildId, String code);

  Future<GuildTemplate> update(
    Object guildId,
    String code, {
    String? name,
    String? description,
  });

  Future<GuildTemplate> delete(Object guildId, String code);
}

abstract interface class StageInstancePartContract implements DataStorePart {
  Future<StageInstance> get(Object channelId);

  Future<StageInstance> create({
    required Object channelId,
    required String topic,
    StagePrivacyLevel? privacyLevel,
    bool? sendStartNotification,
    Object? guildScheduledEventId,
    String? reason,
  });

  Future<StageInstance> update({
    required Object channelId,
    String? topic,
    StagePrivacyLevel? privacyLevel,
    String? reason,
  });

  Future<void> delete({required Object channelId, String? reason});
}

abstract interface class SoundboardPartContract implements DataStorePart {
  Future<List<SoundboardSound>> fetchDefault();

  Future<Map<Snowflake, SoundboardSound>> fetchForServer(Object guildId);

  Future<SoundboardSound> get(Object guildId, Object soundId);

  Future<SoundboardSound> create(
    Object guildId, {
    required String name,
    required String sound,
    double? volume,
    Object? emojiId,
    String? emojiName,
    String? reason,
  });

  Future<SoundboardSound> update(
    Object guildId,
    Object soundId, {
    String? name,
    double? volume,
    Object? emojiId,
    String? emojiName,
    String? reason,
  });

  Future<void> delete(Object guildId, Object soundId, {String? reason});

  Future<void> sendToChannel(
    Object channelId, {
    required Object soundId,
    Object? sourceGuildId,
  });
}

abstract interface class MonetizationPartContract implements DataStorePart {
  Future<List<Sku>> fetchSkus(Object applicationId);

  Future<List<Entitlement>> fetchEntitlements(
    Object applicationId, {
    Object? userId,
    List<Object>? skuIds,
    Object? guildId,
    bool? excludeEnded,
    int? limit,
    Object? before,
    Object? after,
  });

  Future<Entitlement> createTestEntitlement(
    Object applicationId, {
    required Object skuId,
    required Object ownerId,
    required EntitlementOwnerType ownerType,
  });

  Future<void> consumeEntitlement(Object applicationId, Object entitlementId);

  Future<void> deleteTestEntitlement(
    Object applicationId,
    Object entitlementId,
  );

  Future<List<Subscription>> fetchSubscriptions(
    Object skuId, {
    Object? userId,
    int? limit,
    Object? before,
    Object? after,
  });

  Future<Subscription> getSubscription(Object skuId, Object subscriptionId);
}
