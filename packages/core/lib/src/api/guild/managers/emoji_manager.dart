import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class EmojiManager {
  final EntityContext _ctx;
  DataStoreContract get _datastore => _ctx.datastore;

  final Snowflake _guildId;

  EmojiManager(this._guildId, {required EntityContext ctx}) : _ctx = ctx;

  /// Fetch the guild's channels.
  /// ```dart
  /// final channels = await guild.channels.fetch();
  /// ```
  Future<Map<Snowflake, Emoji>> fetch({bool force = false}) =>
      _datastore.emoji.fetch(_guildId.value, force);

  /// Get a channel by its id.
  /// ```dart
  /// final channel = await guild.channels.get('1091121140090535956');
  /// ```
  Future<Emoji?> get(String id, {bool force = false}) =>
      _datastore.emoji.get(_guildId.value, id, force);

  /// Create a new emoji.
  /// ```dart
  /// final emoji = await guild.emojis.create(name: 'New Emoji', );
  /// ```
  Future<Emoji> create(
          {required String name,
          required Image image,
          List<Snowflake> roles = const [],
          String? reason}) =>
      _datastore.emoji.create(_guildId.value, name, image,
          roles.map((element) => element.value).toList(),
          reason: reason);
}
