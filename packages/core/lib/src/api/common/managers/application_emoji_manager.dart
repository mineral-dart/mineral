import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class ApplicationEmojiManager {
  final EntityContext _ctx;
  DataStoreContract get _datastore => _ctx.datastore;

  final Snowflake _applicationId;

  ApplicationEmojiManager(this._applicationId, {required EntityContext ctx})
    : _ctx = ctx;

  /// Fetch all application-owned emojis.
  /// ```dart
  /// final emojis = await bot.emojis.fetch();
  /// ```
  Future<Map<Snowflake, Emoji>> fetch() =>
      _datastore.applicationEmoji.fetch(_applicationId.value);

  /// Get a single application emoji by its id.
  /// ```dart
  /// final emoji = await bot.emojis.get('1234567890');
  /// ```
  Future<Emoji?> get(String id) =>
      _datastore.applicationEmoji.get(_applicationId.value, id);

  /// Create a new application emoji.
  /// ```dart
  /// final emoji = await bot.emojis.create(name: 'my_emoji', image: Image.fromFile('path/to/file.png'));
  /// ```
  Future<Emoji> create({required String name, required Image image}) =>
      _datastore.applicationEmoji.create(_applicationId.value, name, image);

  /// Update the name of an application emoji.
  /// ```dart
  /// await bot.emojis.update('1234567890', name: 'new_name');
  /// ```
  Future<Emoji?> update(String id, {required String name}) =>
      _datastore.applicationEmoji.update(_applicationId.value, id, name);

  /// Delete an application emoji.
  /// ```dart
  /// await bot.emojis.delete('1234567890');
  /// ```
  Future<void> delete(String id) =>
      _datastore.applicationEmoji.delete(_applicationId.value, id);
}
