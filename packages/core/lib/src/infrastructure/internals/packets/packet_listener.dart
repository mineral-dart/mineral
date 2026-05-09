import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/kernel.dart';
import 'package:mineral/src/domains/services/packets/packet_dispatcher.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
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
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_member_add_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_member_chunk_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_member_remove_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_member_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_role_create_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_role_delete_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_role_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_stickers_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_update_packet.dart';
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
import 'package:mineral/src/infrastructure/internals/packets/listeners/message_reaction_remove_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/presence_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/ready_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/thread_create_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/thread_delete_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/thread_members_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/thread_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/typing_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/voice_connect_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/voice_disconnect_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/voice_join_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/voice_leave_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/voice_move_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_dispatcher.dart';

final class PacketListener implements PacketListenerContract {
  @override
  late final PacketDispatcherContract dispatcher;

  late final Kernel kernel;

  void subscribe(ListenablePacket Function() factory) {
    final packet = factory();
    dispatcher.listen(packet.packetType, packet.listen);
  }

  @override
  void dispose() {
    dispatcher.dispose();
  }

  void init() {
    dispatcher = PacketDispatcher(kernel);

    subscribe(ReadyPacket.new);
    subscribe(MessageCreatePacket.new);
    subscribe(GuildCreatePacket.new);
    subscribe(GuildUpdatePacket.new);
    subscribe(GuildDeletePacket.new);
    subscribe(ChannelCreatePacket.new);
    subscribe(ChannelUpdatePacket.new);
    subscribe(ChannelDeletePacket.new);
    subscribe(ChannelPinsUpdatePacket.new);
    subscribe(GuildMemberAddPacket.new);
    subscribe(GuildMemberRemovePacket.new);
    subscribe(GuildMemberUpdatePacket.new);
    subscribe(GuildRoleCreatePacket.new);
    subscribe(GuildRoleUpdatePacket.new);
    subscribe(GuildRoleDeletePacket.new);
    subscribe(GuildMemberChunkPacket.new);
    subscribe(PresenceUpdatePacket.new);
    subscribe(GuildBanAddPacket.new);
    subscribe(GuildBanRemovePacket.new);
    subscribe(GuildEmojisUpdatePacket.new);
    subscribe(GuildStickersUpdatePacket.new);
    subscribe(GuildAuditLogEntryCreatePacket.new);

    subscribe(MessageDeletePacket.new);
    subscribe(MessageDeleteBulkPacket.new);

    subscribe(MessageReactionAddPacket.new);
    subscribe(MessageReactionRemovePacket.new);
    subscribe(MessageReactionRemoveAllPacket.new);

    subscribe(ButtonInteractionCreatePacket.new);
    subscribe(CommandInteractionCreatePacket.new);
    subscribe(SelectInteractionCreatePacket.new);
    subscribe(ModalInteractionCreatePacket.new);

    subscribe(ThreadCreatePacket.new);
    subscribe(ThreadUpdatePacket.new);
    subscribe(ThreadDeletePacket.new);
    subscribe(ThreadMembersUpdatePacket.new);

    subscribe(VoiceConnectPacket.new);
    subscribe(VoiceDisconnectPacket.new);
    subscribe(VoiceJoinPacket.new);
    subscribe(VoiceMovePacket.new);
    subscribe(VoiceLeavePacket.new);

    subscribe(InviteCreatePacket.new);
    subscribe(InviteDeletePacket.new);
    subscribe(TypingPacket.new);

    subscribe(MessagePollVoteAddPacket.new);
    subscribe(MessagePollVoteRemovePacket.new);

    subscribe(AutomoderationRuleCreatePacket.new);
    subscribe(AutoModerationRuleUpdatePacket.new);
    subscribe(AutomoderationRuleDeletePacket.new);
    subscribe(AutomoderationActionExecutionPacket.new);
  }
}
