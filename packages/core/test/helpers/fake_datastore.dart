import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/thread_part.dart';
import 'package:mineral/src/infrastructure/internals/datastore/request_bucket.dart';
import 'package:mineral/src/testing/fake_logger.dart';

/// A minimal [DataStoreContract] for use in tests.
///
/// Only [client] and [requestBucket] are functional.
/// All Part getters throw [UnimplementedError] — override them in a subclass
/// or use a real Part instance passed directly to the system under test.
final class FakeDataStore implements DataStoreContract {
  @override
  late final RequestBucket requestBucket;

  @override
  final HttpClientContract client;

  FakeDataStore(this.client, {LoggerContract? logger}) {
    requestBucket = RequestBucket(client, logger: logger ?? FakeLogger());
  }

  @override
  ChannelPartContract get channel => throw UnimplementedError('channel');

  @override
  GuildPartContract get guild => throw UnimplementedError('guild');

  @override
  MemberPartContract get member => throw UnimplementedError('member');

  @override
  UserPartContract get user => throw UnimplementedError('user');

  @override
  RolePartContract get role => throw UnimplementedError('role');

  @override
  MessagePartContract get message => throw UnimplementedError('message');

  @override
  InteractionPartContract get interaction =>
      throw UnimplementedError('interaction');

  @override
  StickerPartContract get sticker => throw UnimplementedError('sticker');

  @override
  EmojiPartContract get emoji => throw UnimplementedError('emoji');

  @override
  RulesPartContract get rules => throw UnimplementedError('rules');

  @override
  ReactionPartContract get reaction => throw UnimplementedError('reaction');

  @override
  ThreadPart get thread => throw UnimplementedError('thread');

  @override
  InvitePartContract get invite => throw UnimplementedError('invite');

  @override
  WebhookPartContract get webhook => throw UnimplementedError('webhook');

  @override
  GuildScheduledEventPartContract get scheduledEvent =>
      throw UnimplementedError('scheduledEvent');

  @override
  ApplicationEmojiPartContract get applicationEmoji =>
      throw UnimplementedError('applicationEmoji');

  @override
  WelcomeScreenPartContract get welcomeScreen =>
      throw UnimplementedError('welcomeScreen');

  @override
  OnboardingPartContract get onboarding =>
      throw UnimplementedError('onboarding');

  @override
  TemplatePartContract get template => throw UnimplementedError('template');

  @override
  StageInstancePartContract get stageInstance =>
      throw UnimplementedError('stageInstance');

  @override
  MonetizationPartContract get monetization =>
      throw UnimplementedError('monetization');

  @override
  SoundboardPartContract get soundboard =>
      throw UnimplementedError('soundboard');
}
