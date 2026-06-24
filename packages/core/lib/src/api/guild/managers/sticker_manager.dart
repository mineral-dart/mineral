import 'package:mineral/contracts.dart';
import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/api/common/sticker.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class StickerManager {
  final EntityContext _ctx;
  DataStoreContract get _datastore => _ctx.datastore;

  final Snowflake _guildId;

  StickerManager(this._guildId, {required EntityContext ctx}) : _ctx = ctx;

  /// Fetch the guild's stickers.
  /// ```dart
  /// final channels = await guild.assets.stickers.fetch();
  /// ```
  Future<Map<Snowflake, Sticker>> fetch({bool force = false}) =>
      _datastore.sticker.fetch(_guildId.value, force);

  /// Get a channel by its id.
  /// ```dart
  /// final channel = await guild.assets.stickers.get('1091121140090535956');
  /// ```
  Future<Sticker?> get(String id, {bool force = false}) =>
      _datastore.sticker.get(_guildId.value, id, force);
}
