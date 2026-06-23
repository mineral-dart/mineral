import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/common/kernel.dart';
import 'package:mineral/src/domains/common/runtime_state.dart';
import 'package:mineral/src/domains/services/packets/packet_dispatcher.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/application_command_permissions_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/automoderation_action_execution_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/automoderation_rule_create_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/automoderation_rule_delete_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/automoderation_rule_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/channel_create_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/channel_delete_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/channel_pins_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/channel_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_audit_log_entry_create_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_ban_add_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_ban_remove_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_create_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_delete_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_emojis_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_integrations_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_member_add_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_member_chunk_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_member_remove_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_member_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_role_create_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_role_delete_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_role_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_stickers_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/integration_create_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/integration_delete_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/integration_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/interactions/button_interaction_create_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/interactions/command_interaction_create_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/interactions/modal_interaction_create_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/interactions/select_interaction_create_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/invite_create_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/invite_delete_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/message_create_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/message_delete_bulk_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/message_delete_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/message_poll_vote_add_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/message_poll_vote_remove_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/message_reaction_add_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/message_reaction_remove_all_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/message_reaction_remove_emoji_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/message_reaction_remove_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/message_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/presence_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/ready_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/thread_create_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/thread_delete_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/thread_members_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/thread_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/typing_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/user_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/voice_channel_effect_send_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/voice_connect_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/voice_disconnect_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/voice_join_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/voice_leave_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/voice_move_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/webhooks_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_dispatcher.dart';

final class PacketListener implements PacketListenerContract {
  @override
  late final PacketDispatcherContract dispatcher;

  late final Kernel kernel;
  late final MarshallerContract marshaller;
  late final DataStoreContract dataStore;
  late final InteractiveComponentManagerContract interactiveComponent;
  late final CommandInteractionManagerContract commandManager;
  late final EntityContext entityContext;
  late final RuntimeState runtimeState;
  CacheConfig? cacheConfig;

  void subscribe(ListenablePacket packet) {
    dispatcher.listen(packet.packetType, packet.listen);
  }

  @override
  void dispose() {
    dispatcher.dispose();
  }

  void init() {
    dispatcher = PacketDispatcher(kernel);
    final logger = kernel.logger;
    final wss = kernel.wss;
    final m = marshaller;
    final ds = dataStore;
    final ic = interactiveComponent;
    final cm = commandManager;

    subscribe(ReadyPacket(
        marshaller: m,
        commandManager: cm,
        wss: wss,
        runtimeState: runtimeState,
        cacheConfig: cacheConfig));
    subscribe(MessageCreatePacket(marshaller: m));
    subscribe(MessageUpdatePacket(marshaller: m));
    subscribe(GuildCreatePacket(
        marshaller: m, commandManager: cm, runtimeState: runtimeState));
    subscribe(GuildUpdatePacket(marshaller: m));
    subscribe(GuildDeletePacket(marshaller: m));
    subscribe(UserUpdatePacket(marshaller: m));
    subscribe(ChannelCreatePacket(logger: logger, marshaller: m));
    subscribe(ChannelUpdatePacket(logger: logger, marshaller: m));
    subscribe(ChannelDeletePacket(marshaller: m));
    subscribe(ChannelPinsUpdatePacket(logger: logger, dataStore: ds));
    subscribe(WebhooksUpdatePacket(dataStore: ds));
    subscribe(GuildMemberAddPacket(marshaller: m, dataStore: ds));
    subscribe(GuildMemberRemovePacket(marshaller: m, dataStore: ds));
    subscribe(GuildMemberUpdatePacket(marshaller: m, dataStore: ds));
    subscribe(GuildRoleCreatePacket(marshaller: m, dataStore: ds));
    subscribe(GuildRoleUpdatePacket(marshaller: m, dataStore: ds));
    subscribe(GuildRoleDeletePacket(marshaller: m, dataStore: ds));
    subscribe(GuildMemberChunkPacket(marshaller: m, dataStore: ds, wss: wss));
    subscribe(PresenceUpdatePacket(dataStore: ds));
    subscribe(GuildBanAddPacket(marshaller: m, dataStore: ds));
    subscribe(GuildBanRemovePacket(marshaller: m, dataStore: ds));
    subscribe(GuildEmojisUpdatePacket(marshaller: m, dataStore: ds));
    subscribe(GuildStickersUpdatePacket(marshaller: m, dataStore: ds));
    subscribe(GuildAuditLogEntryCreatePacket(logger: logger, ctx: entityContext));

    subscribe(MessageDeletePacket(marshaller: m, dataStore: ds));
    subscribe(MessageDeleteBulkPacket(marshaller: m, dataStore: ds));

    subscribe(MessageReactionAddPacket(marshaller: m));
    subscribe(MessageReactionRemovePacket(marshaller: m));
    subscribe(MessageReactionRemoveAllPacket(dataStore: ds));
    subscribe(MessageReactionRemoveEmojiPacket(dataStore: ds));

    subscribe(ButtonInteractionCreatePacket(
        logger: logger, interactiveComponent: ic, ctx: entityContext));
    subscribe(CommandInteractionCreatePacket(commandManager: cm));
    subscribe(SelectInteractionCreatePacket(
        logger: logger,
        marshaller: m,
        dataStore: ds,
        interactiveComponent: ic,
        entityContext: entityContext));
    subscribe(ModalInteractionCreatePacket(
        logger: logger,
        marshaller: m,
        dataStore: ds,
        interactiveComponent: ic,
        entityContext: entityContext));

    subscribe(ThreadCreatePacket(marshaller: m, dataStore: ds));
    subscribe(ThreadUpdatePacket(marshaller: m, dataStore: ds));
    subscribe(ThreadDeletePacket(marshaller: m, dataStore: ds));
    subscribe(ThreadMembersUpdatePacket(marshaller: m, dataStore: ds));

    subscribe(VoiceConnectPacket(marshaller: m));
    subscribe(VoiceDisconnectPacket(marshaller: m));
    subscribe(VoiceJoinPacket(marshaller: m));
    subscribe(VoiceMovePacket(marshaller: m));
    subscribe(VoiceLeavePacket(marshaller: m));
    subscribe(VoiceChannelEffectSendPacket(dataStore: ds));

    subscribe(InviteCreatePacket(marshaller: m));
    subscribe(InviteDeletePacket(dataStore: ds));
    subscribe(TypingPacket(ctx: entityContext));

    subscribe(MessagePollVoteAddPacket(dataStore: ds));
    subscribe(MessagePollVoteRemovePacket(dataStore: ds));

    subscribe(
        ApplicationCommandPermissionsUpdatePacket(dataStore: ds));

    subscribe(GuildIntegrationsUpdatePacket(dataStore: ds));
    subscribe(IntegrationCreatePacket(dataStore: ds));
    subscribe(IntegrationUpdatePacket(dataStore: ds));
    subscribe(IntegrationDeletePacket(dataStore: ds));

    subscribe(AutomoderationRuleCreatePacket(marshaller: m));
    subscribe(AutoModerationRuleUpdatePacket(marshaller: m));
    subscribe(AutomoderationRuleDeletePacket(marshaller: m));
    subscribe(AutomoderationActionExecutionPacket(dataStore: ds));
  }
}
