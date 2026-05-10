import 'package:mineral/contracts.dart';
import 'package:mineral/src/api/common/message.dart';
import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class MessageManager<T extends BaseMessage> {
  final EntityContext _ctx;
  DataStoreContract get _datastore => _ctx.datastore;

  final Snowflake _channelId;

  MessageManager(this._channelId, {required EntityContext ctx}) : _ctx = ctx;

  Future<T?> get(Snowflake id, {bool force = false}) =>
      _datastore.message.get<T>(_channelId.value, id.value, force);

  Future<T> getOrFail(Snowflake id, {bool force = false}) =>
      _datastore.message.get<T>(_channelId.value, id.value, force) as Future<T>;

  Future<Map<Snowflake, T>> fetch(
          {Snowflake? around,
          Snowflake? before,
          Snowflake? after,
          int? limit}) =>
      _datastore.message.fetch<T>(_channelId.value);
}
