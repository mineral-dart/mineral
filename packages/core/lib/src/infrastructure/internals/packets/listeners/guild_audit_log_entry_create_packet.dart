import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/api/server/audit_log/audit_log.dart';
import 'package:mineral/src/api/server/audit_log/audit_log_action.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/audit_logs/_default.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/audit_logs/application_command_permission.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/audit_logs/auto_moderation.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/audit_logs/channel.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/audit_logs/channel_overwrite.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/audit_logs/emoji.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/audit_logs/guild_scheduled_event.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/audit_logs/integration.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/audit_logs/invite.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/audit_logs/member.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/audit_logs/message.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/audit_logs/other.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/audit_logs/role.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/audit_logs/server.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/audit_logs/stage_instance.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/audit_logs/sticker.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/audit_logs/thread.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/audit_logs/webhook.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class GuildAuditLogEntryCreatePacket implements ListenablePacket {
  final LoggerContract logger;
  final EntityContext _ctx;

  GuildAuditLogEntryCreatePacket({
    required this.logger,
    required EntityContext ctx,
  }) : _ctx = ctx;

  @override
  PacketType get packetType => PacketType.guildAuditLogEntryCreate;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final payload = message.payload as Map<String, dynamic>;
    final ctx = _ctx;
    final auditLogType = AuditLogType.values.firstWhere(
        (element) => element.value == payload['action_type'],
        orElse: () => AuditLogType.unknown);

    final auditLog = await switch (auditLogType) {
      // Emoji
      AuditLogType.emojiCreate => emojiCreateAuditLogHandler(payload, ctx),
      AuditLogType.emojiUpdate => emojiUpdateAuditLogHandler(payload, ctx),
      AuditLogType.emojiDelete => emojiDeleteAuditLogHandler(payload, ctx),

      // Role
      AuditLogType.roleCreate => roleCreateAuditLogHandler(payload, ctx),
      AuditLogType.roleUpdate => roleUpdateAuditLogHandler(payload, ctx),
      AuditLogType.roleDelete => roleDeleteAuditLogHandler(payload, ctx),

      // Server
      AuditLogType.guildUpdate => serverUpdateAuditLogHandler(payload, ctx),

      // Channel
      AuditLogType.channelCreate => channelCreateAuditLogHandler(payload, ctx),
      AuditLogType.channelUpdate => channelUpdateAuditLogHandler(payload, ctx),
      AuditLogType.channelDelete => channelDeleteAuditLogHandler(payload, ctx),

      // Channel Overwrite
      AuditLogType.channelOverwriteCreate =>
        channelOverwriteCreateAuditLogHandler(payload, ctx),
      AuditLogType.channelOverwriteUpdate =>
        channelOverwriteUpdateAuditLogHandler(payload, ctx),
      AuditLogType.channelOverwriteDelete =>
        channelOverwriteDeleteAuditLogHandler(payload, ctx),

      // Member
      AuditLogType.memberKick => memberKickAuditLogHandler(payload, ctx),
      AuditLogType.memberPrune => memberPruneAuditLogHandler(payload, ctx),
      AuditLogType.memberBanAdd => memberBanAddAuditLogHandler(payload, ctx),
      AuditLogType.memberBanRemove =>
        memberBanRemoveAuditLogHandler(payload, ctx),
      AuditLogType.memberUpdate => memberUpdateAuditLogHandler(payload, ctx),
      AuditLogType.memberRoleUpdate =>
        memberRoleUpdateAuditLogHandler(payload, ctx),
      AuditLogType.memberMove => memberMoveAuditLogHandler(payload, ctx),
      AuditLogType.memberDisconnect =>
        memberDisconnectAuditLogHandler(payload, ctx),
      AuditLogType.botAdd => botAddAuditLogHandler(payload, ctx),

      // Invite
      AuditLogType.inviteCreate => inviteCreateAuditLogHandler(payload, ctx),
      AuditLogType.inviteUpdate => inviteUpdateAuditLogHandler(payload, ctx),
      AuditLogType.inviteDelete => inviteDeleteAuditLogHandler(payload, ctx),

      // Webhook
      AuditLogType.webhookCreate => webhookCreateAuditLogHandler(payload, ctx),
      AuditLogType.webhookUpdate => webhookUpdateAuditLogHandler(payload, ctx),
      AuditLogType.webhookDelete => webhookDeleteAuditLogHandler(payload, ctx),

      // Message
      AuditLogType.messageDelete => messageDeleteAuditLogHandler(payload, ctx),
      AuditLogType.messageBulkDelete =>
        messageBulkDeleteAuditLogHandler(payload, ctx),
      AuditLogType.messagePin => messagePinAuditLogHandler(payload, ctx),
      AuditLogType.messageUnpin => messageUnpinAuditLogHandler(payload, ctx),

      // Integration
      AuditLogType.integrationCreate =>
        integrationCreateAuditLogHandler(payload, ctx),
      AuditLogType.integrationUpdate =>
        integrationUpdateAuditLogHandler(payload, ctx),
      AuditLogType.integrationDelete =>
        integrationDeleteAuditLogHandler(payload, ctx),

      // Stage Instance
      AuditLogType.stageInstanceCreate =>
        stageInstanceCreateAuditLogHandler(payload, ctx),
      AuditLogType.stageInstanceUpdate =>
        stageInstanceUpdateAuditLogHandler(payload, ctx),
      AuditLogType.stageInstanceDelete =>
        stageInstanceDeleteAuditLogHandler(payload, ctx),

      // Sticker
      AuditLogType.stickerCreate => stickerCreateAuditLogHandler(payload, ctx),
      AuditLogType.stickerUpdate => stickerUpdateAuditLogHandler(payload, ctx),
      AuditLogType.stickerDelete => stickerDeleteAuditLogHandler(payload, ctx),

      // Guild Scheduled Event
      AuditLogType.guildScheduledEventCreate =>
        guildScheduledEventCreateAuditLogHandler(payload, ctx),
      AuditLogType.guildScheduledEventUpdate =>
        guildScheduledEventUpdateAuditLogHandler(payload, ctx),
      AuditLogType.guildScheduledEventDelete =>
        guildScheduledEventDeleteAuditLogHandler(payload, ctx),

      // Thread
      AuditLogType.threadCreate => threadCreateAuditLogHandler(payload, ctx),
      AuditLogType.threadUpdate => threadUpdateAuditLogHandler(payload, ctx),
      AuditLogType.threadDelete => threadDeleteAuditLogHandler(payload, ctx),

      // Application Command Permission
      AuditLogType.applicationCommandPermissionUpdate =>
        applicationCommandPermissionUpdateAuditLogHandler(payload, ctx),

      // Auto Moderation
      AuditLogType.autoModerationRuleCreate =>
        autoModerationRuleCreateAuditLogHandler(payload, ctx),
      AuditLogType.autoModerationRuleUpdate =>
        autoModerationRuleUpdateAuditLogHandler(payload, ctx),
      AuditLogType.autoModerationRuleDelete =>
        autoModerationRuleDeleteAuditLogHandler(payload, ctx),
      AuditLogType.autoModerationBlockMessage =>
        autoModerationBlockMessageAuditLogHandler(payload, ctx),
      AuditLogType.autoModerationFlagToChannel =>
        autoModerationFlagToChannelAuditLogHandler(payload, ctx),
      AuditLogType.autoModerationUserCommunicationDisabled =>
        autoModerationUserCommunicationDisabledAuditLogHandler(payload, ctx),

      // Creator Monetization
      AuditLogType.creatorMonetizationRequestCreated =>
        creatorMonetizationRequestCreatedAuditLogHandler(payload, ctx),
      AuditLogType.creatorMonetizationTermsAccepted =>
        creatorMonetizationTermsAcceptedAuditLogHandler(payload, ctx),

      // Onboarding
      AuditLogType.onboardingPromptCreate =>
        onboardingPromptCreateAuditLogHandler(payload, ctx),
      AuditLogType.onboardingPromptUpdate =>
        onboardingPromptUpdateAuditLogHandler(payload, ctx),
      AuditLogType.onboardingPromptDelete =>
        onboardingPromptDeleteAuditLogHandler(payload, ctx),
      AuditLogType.onboardingCreate =>
        onboardingCreateAuditLogHandler(payload, ctx),
      AuditLogType.onboardingUpdate =>
        onboardingUpdateAuditLogHandler(payload, ctx),

      // Home Settings
      AuditLogType.homeSettingsCreate =>
        homeSettingsCreateAuditLogHandler(payload, ctx),
      AuditLogType.homeSettingsUpdate =>
        homeSettingsUpdateAuditLogHandler(payload, ctx),
      _ => unknownAuditLogHandler(payload, ctx),
    };

    if (auditLog case final UnknownAuditLogAction action) {
      logger.warn('Audit log action not found ${action.type}');
    }

    dispatch<ServerAuditLogArgs>(
      event: Event.serverAuditLog,
      payload: (audit: auditLog),
    );
  }
}
