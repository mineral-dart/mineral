import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class ReactionManger {
  final EntityContext _ctx;
  DataStoreContract get _datastore => _ctx.datastore;

  final String _messageId;
  final String _channelId;

  ReactionManger(this._messageId, this._channelId, {required EntityContext ctx})
      : _ctx = ctx;

  Future<void> add(PartialEmoji emoji) =>
      _datastore.reaction.add(_channelId, _messageId, emoji);

  Future<void> remove(PartialEmoji emoji) =>
      _datastore.reaction.remove(_channelId, _messageId, emoji);

  Future<void> removeAll() =>
      _datastore.reaction.removeAll(_channelId, _messageId);

  Future<void> removeForEmoji(PartialEmoji emoji) =>
      _datastore.reaction.removeForEmoji(_channelId, _messageId, emoji);

  Future<void> removeForUser(String userId, PartialEmoji emoji) =>
      _datastore.reaction.removeForUser(userId, _channelId, _messageId, emoji);

  Future<Map<Snowflake, User>> getUsersForEmoji(PartialEmoji emoji) =>
      _datastore.reaction.getUsersForEmoji(_channelId, _messageId, emoji);
}
