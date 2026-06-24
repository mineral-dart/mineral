import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/services/datastore/parts.dart';
import 'package:mineral/src/domains/services/datastore/request_bucket_contract.dart';
import 'package:mineral/src/domains/services/http/http.dart';

abstract class DataStoreContract {
  RequestBucketContract get requestBucket;

  HttpClientContract get client;

  ChannelPartContract get channel;

  GuildPartContract get guild;

  MemberPartContract get member;

  UserPartContract get user;

  RolePartContract get role;

  MessagePartContract get message;

  InteractionPartContract get interaction;

  StickerPartContract get sticker;

  EmojiPartContract get emoji;

  RulesPartContract get rules;

  ReactionPartContract get reaction;

  ThreadPartContract get thread;

  InvitePartContract get invite;

  WebhookPartContract get webhook;

  GuildScheduledEventPartContract get scheduledEvent;

  ApplicationEmojiPartContract get applicationEmoji;

  WelcomeScreenPartContract get welcomeScreen;

  OnboardingPartContract get onboarding;

  TemplatePartContract get template;

  StageInstancePartContract get stageInstance;

  MonetizationPartContract get monetization;

  SoundboardPartContract get soundboard;
}
