import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/api/server/channels/private_thread_channel.dart';
import 'package:mineral/src/api/server/channels/public_thread_channel.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

abstract interface class ServerThreadManager {
  Future<ThreadResult> fetchActives();
}

abstract interface class ChannelThreadManager {
  Future<Map<Snowflake, PublicThreadChannel>> fetchPublicArchived();

  Future<Map<Snowflake, PrivateThreadChannel>> fetchPrivateArchived();

  Future<T> createWithoutMessage<T extends ThreadChannel>(
      ThreadChannelBuilder builder);
}

final class ThreadsManager
    implements ServerThreadManager, ChannelThreadManager {
  final EntityContext _ctx;
  DataStoreContract get _datastore => _ctx.datastore;

  final Snowflake? _serverId;
  final Snowflake? _channelId;

  ThreadsManager(this._serverId, this._channelId, {required EntityContext ctx})
      : _ctx = ctx;

  @override
  Future<ThreadResult> fetchActives() =>
      _datastore.thread.fetchActives(_serverId!.value);

  @override
  Future<Map<Snowflake, PublicThreadChannel>> fetchPublicArchived() =>
      _datastore.thread.fetchPublicArchived(_channelId!.value);

  @override
  Future<Map<Snowflake, PrivateThreadChannel>> fetchPrivateArchived() =>
      _datastore.thread.fetchPrivateArchived(_channelId!.value);

  @override
  Future<T> createWithoutMessage<T extends ThreadChannel>(
          ThreadChannelBuilder builder) =>
      _datastore.thread.createWithoutMessage<T>(
          _serverId!.value, _channelId!.value, builder);
}
