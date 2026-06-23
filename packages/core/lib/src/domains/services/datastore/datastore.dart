import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/services/http/http.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/thread_part.dart';
import 'package:mineral/src/infrastructure/internals/datastore/request_bucket.dart';

abstract class DataStoreContract {
  RequestBucket get requestBucket;

  HttpClientContract get client;

  ChannelPartContract get channel;

  ServerPartContract get server;

  MemberPartContract get member;

  UserPartContract get user;

  RolePartContract get role;

  MessagePartContract get message;

  InteractionPartContract get interaction;

  StickerPartContract get sticker;

  EmojiPartContract get emoji;

  RulesPartContract get rules;

  ReactionPartContract get reaction;

  ThreadPart get thread;

  InvitePartContract get invite;

  WebhookPartContract get webhook;

  GuildScheduledEventPartContract get scheduledEvent;

  ApplicationEmojiPartContract get applicationEmoji;

  WelcomeScreenPartContract get welcomeScreen;

  OnboardingPartContract get onboarding;

  TemplatePartContract get template;

  StageInstancePartContract get stageInstance;
}
