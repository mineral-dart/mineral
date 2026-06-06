import 'package:mineral/src/api/common/channel.dart';
import 'package:mineral/src/api/common/channel_permission_overwrite.dart';
import 'package:mineral/src/api/common/embed/message_embed.dart';
import 'package:mineral/src/api/common/emoji.dart';
import 'package:mineral/src/api/common/message.dart';
import 'package:mineral/src/api/common/message_reaction.dart';
import 'package:mineral/src/api/common/polls/poll.dart';
import 'package:mineral/src/api/common/polls/poll_answer_vote.dart';
import 'package:mineral/src/api/common/sticker.dart';
import 'package:mineral/src/api/private/user.dart';
import 'package:mineral/src/api/server/guild_scheduled_event.dart';
import 'package:mineral/src/api/server/invite.dart';
import 'package:mineral/src/api/server/member.dart';
import 'package:mineral/src/api/server/moderation/auto_moderation_rule.dart';
import 'package:mineral/src/api/server/role.dart';
import 'package:mineral/src/api/server/server.dart';
import 'package:mineral/src/api/server/voice_state.dart';
import 'package:mineral/src/api/server/webhook.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/services/marshaller/marshaller.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/channel_permission_overwrite_serializer.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/channel_serializer.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/embed_serializer.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/emoji_serializer.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/guild_scheduled_event_serializer.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/invite_serializer.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/member_serializer.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/message_reaction_serializer.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/message_serializer.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/poll_answer_vote_serializer.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/poll_serializer.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/role_serializer.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/rule_serializer.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/server_serializer.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/sticker_serializer.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/user_serializer.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/voice_state_serializer.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/webhook_serializer.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/types/serializer.dart';

final class SerializerBucket {
  final SerializerContract<Channel> channels;

  final SerializerContract<Server> server;

  final SerializerContract<Member> member;

  final SerializerContract<User> user;

  final SerializerContract<Role> role;

  final SerializerContract<Emoji> emojis;

  final SerializerContract<Sticker> sticker;

  final SerializerContract<Invite> invite;

  final SerializerContract<ChannelPermissionOverwrite>
      channelPermissionOverwrite;

  final SerializerContract<Message> message;

  final SerializerContract<MessageEmbed> embed;

  final SerializerContract<Poll> poll;

  final SerializerContract<VoiceState> voice;

  final SerializerContract<MessageReaction> reaction;

  final SerializerContract<PollAnswerVote> pollAnswerVote;

  final SerializerContract<AutoModerationRule> rules;

  final SerializerContract<Webhook> webhook;

  final SerializerContract<GuildScheduledEvent> scheduledEvent;

  SerializerBucket(MarshallerContract marshaller, EntityContext ctx)
      : channels = ChannelSerializer(marshaller, ctx),
        server = ServerSerializer(marshaller, ctx),
        member = MemberSerializer(marshaller, ctx),
        user = UserSerializer(marshaller, ctx),
        role = RoleSerializer(marshaller, ctx),
        emojis = EmojiSerializer(marshaller, ctx),
        sticker = StickerSerializer(marshaller),
        channelPermissionOverwrite = ChannelPermissionOverwriteSerializer(marshaller),
        message = MessageSerializer(marshaller, ctx),
        embed = EmbedSerializer(marshaller),
        poll = PollSerializer(marshaller),
        voice = VoiceStateSerializer(marshaller, ctx),
        reaction = MessageReactionSerializer(marshaller, ctx),
        pollAnswerVote = PollAnswerVoteSerializer(marshaller, ctx),
        rules = RuleSerializer(marshaller),
        invite = InviteSerializer(marshaller, ctx),
        webhook = WebhookSerializer(marshaller, ctx),
        scheduledEvent = GuildScheduledEventSerializer(marshaller, ctx);
}
