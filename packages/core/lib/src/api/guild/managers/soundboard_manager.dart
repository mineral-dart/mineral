import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class SoundboardManager {
  final EntityContext _ctx;
  DataStoreContract get _datastore => _ctx.datastore;

  final Snowflake _guildId;

  SoundboardManager(this._guildId, {required EntityContext ctx}) : _ctx = ctx;

  /// Fetch all soundboard sounds for this guild, keyed by soundId.
  /// ```dart
  /// final sounds = await guild.soundboardSounds.fetch();
  /// ```
  Future<Map<Snowflake, SoundboardSound>> fetch() =>
      _datastore.soundboard.fetchForServer(_guildId.value);

  /// Fetch the list of default Discord soundboard sounds.
  /// ```dart
  /// final defaults = await guild.soundboardSounds.fetchDefault();
  /// ```
  Future<List<SoundboardSound>> fetchDefault() =>
      _datastore.soundboard.fetchDefault();

  /// Get a single soundboard sound by its id.
  /// ```dart
  /// final sound = await guild.soundboardSounds.get(soundId);
  /// ```
  Future<SoundboardSound> get(Object soundId) =>
      _datastore.soundboard.get(_guildId.value, soundId);

  /// Create a new soundboard sound.
  /// [sound] must be a data URI (e.g. `data:audio/mp3;base64,...`).
  /// ```dart
  /// final sound = await guild.soundboardSounds.create(
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
        _guildId.value,
        name: name,
        sound: sound,
        volume: volume,
        emojiId: emojiId,
        emojiName: emojiName,
        reason: reason,
      );

  /// Update an existing soundboard sound.
  /// ```dart
  /// await guild.soundboardSounds.update(soundId, name: 'New Name');
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
        _guildId.value,
        soundId,
        name: name,
        volume: volume,
        emojiId: emojiId,
        emojiName: emojiName,
        reason: reason,
      );

  /// Delete a soundboard sound.
  /// ```dart
  /// await guild.soundboardSounds.delete(soundId);
  /// ```
  Future<void> delete(Object soundId, {String? reason}) =>
      _datastore.soundboard.delete(_guildId.value, soundId, reason: reason);
}
