import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class SoundboardManager {
  final EntityContext _ctx;
  DataStoreContract get _datastore => _ctx.datastore;

  final Snowflake _serverId;

  SoundboardManager(this._serverId, {required EntityContext ctx}) : _ctx = ctx;

  /// Fetch all soundboard sounds for this server, keyed by soundId.
  /// ```dart
  /// final sounds = await server.soundboardSounds.fetch();
  /// ```
  Future<Map<Snowflake, SoundboardSound>> fetch() =>
      _datastore.soundboard.fetchForServer(_serverId.value);

  /// Fetch the list of default Discord soundboard sounds.
  /// ```dart
  /// final defaults = await server.soundboardSounds.fetchDefault();
  /// ```
  Future<List<SoundboardSound>> fetchDefault() =>
      _datastore.soundboard.fetchDefault();

  /// Get a single soundboard sound by its id.
  /// ```dart
  /// final sound = await server.soundboardSounds.get(soundId);
  /// ```
  Future<SoundboardSound> get(Object soundId) =>
      _datastore.soundboard.get(_serverId.value, soundId);

  /// Create a new soundboard sound.
  /// [sound] must be a data URI (e.g. `data:audio/mp3;base64,...`).
  /// ```dart
  /// final sound = await server.soundboardSounds.create(
  ///   name: 'My Sound',
  ///   sound: 'data:audio/mp3;base64,...',
  /// );
  /// ```
  Future<SoundboardSound> create({
    required String name,
    required String sound,
    double? volume,
    Object? emojiId,
    String? emojiName,
    String? reason,
  }) =>
      _datastore.soundboard.create(
        _serverId.value,
        name: name,
        sound: sound,
        volume: volume,
        emojiId: emojiId,
        emojiName: emojiName,
        reason: reason,
      );

  /// Update an existing soundboard sound.
  /// ```dart
  /// await server.soundboardSounds.update(soundId, name: 'New Name');
  /// ```
  Future<SoundboardSound> update(
    Object soundId, {
    String? name,
    double? volume,
    Object? emojiId,
    String? emojiName,
    String? reason,
  }) =>
      _datastore.soundboard.update(
        _serverId.value,
        soundId,
        name: name,
        volume: volume,
        emojiId: emojiId,
        emojiName: emojiName,
        reason: reason,
      );

  /// Delete a soundboard sound.
  /// ```dart
  /// await server.soundboardSounds.delete(soundId);
  /// ```
  Future<void> delete(Object soundId, {String? reason}) =>
      _datastore.soundboard.delete(_serverId.value, soundId, reason: reason);
}
