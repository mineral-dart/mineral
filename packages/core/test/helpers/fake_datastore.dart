import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/thread_part.dart';
import 'package:mineral/src/infrastructure/internals/datastore/request_bucket.dart';

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

  FakeDataStore(this.client) {
    requestBucket = RequestBucket(client);
  }

  @override
  ChannelPartContract get channel => throw UnimplementedError('channel');

  @override
  ServerPartContract get server => throw UnimplementedError('server');

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
}
