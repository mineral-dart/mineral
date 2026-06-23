import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/services/http/http.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/application_emoji_part.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/channel_part.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/emoji_part.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/guild_scheduled_event_part.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/interaction_part.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/invite_part.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/member_part.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/message_part.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/onboarding_part.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/reaction_part.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/role_part.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/rules_part.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/server_part.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/stage_instance_part.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/sticker_part.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/template_part.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/thread_part.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/user_part.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/webhook_part.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/welcome_screen_part.dart';
import 'package:mineral/src/infrastructure/internals/datastore/request_bucket.dart';

final class DataStore implements DataStoreContract {
  @override
  late final RequestBucket requestBucket;

  @override
  final HttpClientContract client;

  @override
  late final ChannelPart channel;

  @override
  late final ServerPart server;

  @override
  late final MemberPart member;

  @override
  late final UserPart user;

  @override
  late final RolePart role;

  @override
  late final MessagePart message;

  @override
  late final InteractionPart interaction;

  @override
  late final StickerPart sticker;

  @override
  late final EmojiPart emoji;

  @override
  late final ReactionPart reaction;

  @override
  late final ThreadPart thread;

  @override
  late final RulesPart rules;

  @override
  late final InvitePart invite;

  @override
  late final WebhookPart webhook;

  @override
  late final GuildScheduledEventPart scheduledEvent;

  @override
  late final ApplicationEmojiPart applicationEmoji;

  @override
  late final WelcomeScreenPart welcomeScreen;

  @override
  late final OnboardingPart onboarding;

  @override
  late final TemplatePart template;

  @override
  late final StageInstancePart stageInstance;

  DataStore({
    required this.client,
    required MarshallerContract marshaller,
    required LoggerContract logger,
    required LoggerContract httpLogger,
  }) {
    requestBucket = RequestBucket(client, logger: httpLogger);
    channel = ChannelPart(marshaller, this);
    server = ServerPart(marshaller, this);
    member = MemberPart(marshaller, this);
    user = UserPart(marshaller, this);
    role = RolePart(marshaller, this);
    message = MessagePart(marshaller, this);
    interaction = InteractionPart(marshaller, this);
    sticker = StickerPart(marshaller, this);
    emoji = EmojiPart(marshaller, this);
    reaction = ReactionPart(marshaller, this);
    thread = ThreadPart(marshaller, this);
    rules = RulesPart(marshaller, this);
    invite = InvitePart(marshaller, this);
    webhook = WebhookPart(marshaller, this);
    scheduledEvent = GuildScheduledEventPart(marshaller, this);
    applicationEmoji = ApplicationEmojiPart(marshaller, this);
    welcomeScreen = WelcomeScreenPart(marshaller, this);
    onboarding = OnboardingPart(marshaller, this);
    template = TemplatePart(marshaller, this);
    stageInstance = StageInstancePart(marshaller, this);
  }
}
