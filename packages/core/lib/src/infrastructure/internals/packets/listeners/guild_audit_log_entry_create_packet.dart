import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/api/server/audit_log/audit_log.dart';
import 'package:mineral/src/api/server/audit_log/audit_log_action.dart';
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
  final DataStoreContract _dataStore;

  GuildAuditLogEntryCreatePacket({
    required this.logger,
    required DataStoreContract dataStore,
  }) : _dataStore = dataStore;

  @override
  PacketType get packetType => PacketType.guildAuditLogEntryCreate;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final payload = message.payload as Map<String, dynamic>;
    final auditLogType = AuditLogType.values.firstWhere(
        (element) => element.value == payload['action_type'],
        orElse: () => AuditLogType.unknown);

    final auditLog = await switch (auditLogType) {
      // Emoji
      AuditLogType.emojiCreate => emojiCreateAuditLogHandler(payload),
      AuditLogType.emojiUpdate => emojiUpdateAuditLogHandler(payload),
      AuditLogType.emojiDelete => emojiDeleteAuditLogHandler(payload),

      // Role
      AuditLogType.roleCreate => roleCreateAuditLogHandler(payload),
      AuditLogType.roleUpdate => roleUpdateAuditLogHandler(payload),
      AuditLogType.roleDelete => roleDeleteAuditLogHandler(payload),

      // Server
      AuditLogType.guildUpdate => serverUpdateAuditLogHandler(payload, _dataStore),

      // Channel
      AuditLogType.channelCreate =>
        channelCreateAuditLogHandler(payload, _dataStore),
      AuditLogType.channelUpdate =>
        channelUpdateAuditLogHandler(payload, _dataStore),
      AuditLogType.channelDelete =>
        channelDeleteAuditLogHandler(payload),

      // Channel Overwrite
      AuditLogType.channelOverwriteCreate =>
        channelOverwriteCreateAuditLogHandler(payload),
      AuditLogType.channelOverwriteUpdate =>
        channelOverwriteUpdateAuditLogHandler(payload),
      AuditLogType.channelOverwriteDelete =>
        channelOverwriteDeleteAuditLogHandler(payload),

      // Member
      AuditLogType.memberKick => memberKickAuditLogHandler(payload),
      AuditLogType.memberPrune => memberPruneAuditLogHandler(payload),
      AuditLogType.memberBanAdd => memberBanAddAuditLogHandler(payload),
      AuditLogType.memberBanRemove =>
        memberBanRemoveAuditLogHandler(payload),
      AuditLogType.memberUpdate => memberUpdateAuditLogHandler(payload),
      AuditLogType.memberRoleUpdate =>
        memberRoleUpdateAuditLogHandler(payload),
      AuditLogType.memberMove => memberMoveAuditLogHandler(payload),
      AuditLogType.memberDisconnect =>
        memberDisconnectAuditLogHandler(payload),
      AuditLogType.botAdd => botAddAuditLogHandler(payload),

      // Invite
      AuditLogType.inviteCreate => inviteCreateAuditLogHandler(payload),
      AuditLogType.inviteUpdate => inviteUpdateAuditLogHandler(payload),
      AuditLogType.inviteDelete => inviteDeleteAuditLogHandler(payload),

      // Webhook
      AuditLogType.webhookCreate =>
        webhookCreateAuditLogHandler(payload),
      AuditLogType.webhookUpdate =>
        webhookUpdateAuditLogHandler(payload),
      AuditLogType.webhookDelete =>
        webhookDeleteAuditLogHandler(payload),

      // Message
      AuditLogType.messageDelete =>
        messageDeleteAuditLogHandler(payload),
      AuditLogType.messageBulkDelete =>
        messageBulkDeleteAuditLogHandler(payload),
      AuditLogType.messagePin => messagePinAuditLogHandler(payload),
      AuditLogType.messageUnpin => messageUnpinAuditLogHandler(payload),

      // Integration
      AuditLogType.integrationCreate =>
        integrationCreateAuditLogHandler(payload),
      AuditLogType.integrationUpdate =>
        integrationUpdateAuditLogHandler(payload),
      AuditLogType.integrationDelete =>
        integrationDeleteAuditLogHandler(payload),

      // Stage Instance
      AuditLogType.stageInstanceCreate =>
        stageInstanceCreateAuditLogHandler(payload),
      AuditLogType.stageInstanceUpdate =>
        stageInstanceUpdateAuditLogHandler(payload),
      AuditLogType.stageInstanceDelete =>
        stageInstanceDeleteAuditLogHandler(payload),

      // Sticker
      AuditLogType.stickerCreate =>
        stickerCreateAuditLogHandler(payload, _dataStore),
      AuditLogType.stickerUpdate =>
        stickerUpdateAuditLogHandler(payload, _dataStore),
      AuditLogType.stickerDelete =>
        stickerDeleteAuditLogHandler(payload),

      // Guild Scheduled Event
      AuditLogType.guildScheduledEventCreate =>
        guildScheduledEventCreateAuditLogHandler(payload),
      AuditLogType.guildScheduledEventUpdate =>
        guildScheduledEventUpdateAuditLogHandler(payload),
      AuditLogType.guildScheduledEventDelete =>
        guildScheduledEventDeleteAuditLogHandler(payload),

      // Thread
      AuditLogType.threadCreate => threadCreateAuditLogHandler(payload),
      AuditLogType.threadUpdate => threadUpdateAuditLogHandler(payload),
      AuditLogType.threadDelete => threadDeleteAuditLogHandler(payload),

      // Application Command Permission
      AuditLogType.applicationCommandPermissionUpdate =>
        applicationCommandPermissionUpdateAuditLogHandler(payload),

      // Auto Moderation
      AuditLogType.autoModerationRuleCreate =>
        autoModerationRuleCreateAuditLogHandler(payload),
      AuditLogType.autoModerationRuleUpdate =>
        autoModerationRuleUpdateAuditLogHandler(payload),
      AuditLogType.autoModerationRuleDelete =>
        autoModerationRuleDeleteAuditLogHandler(payload),
      AuditLogType.autoModerationBlockMessage =>
        autoModerationBlockMessageAuditLogHandler(payload),
      AuditLogType.autoModerationFlagToChannel =>
        autoModerationFlagToChannelAuditLogHandler(payload),
      AuditLogType.autoModerationUserCommunicationDisabled =>
        autoModerationUserCommunicationDisabledAuditLogHandler(payload),

      // Creator Monetization
      AuditLogType.creatorMonetizationRequestCreated =>
        creatorMonetizationRequestCreatedAuditLogHandler(payload),
      AuditLogType.creatorMonetizationTermsAccepted =>
        creatorMonetizationTermsAcceptedAuditLogHandler(payload),

      // Onboarding
      AuditLogType.onboardingPromptCreate =>
        onboardingPromptCreateAuditLogHandler(payload),
      AuditLogType.onboardingPromptUpdate =>
        onboardingPromptUpdateAuditLogHandler(payload),
      AuditLogType.onboardingPromptDelete =>
        onboardingPromptDeleteAuditLogHandler(payload),
      AuditLogType.onboardingCreate =>
        onboardingCreateAuditLogHandler(payload),
      AuditLogType.onboardingUpdate =>
        onboardingUpdateAuditLogHandler(payload),

      // Home Settings
      AuditLogType.homeSettingsCreate =>
        homeSettingsCreateAuditLogHandler(payload),
      AuditLogType.homeSettingsUpdate =>
        homeSettingsUpdateAuditLogHandler(payload),
      _ => unknownAuditLogHandler(payload),
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
