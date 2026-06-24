import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class TemplateManager {
  final EntityContext _ctx;
  DataStoreContract get _datastore => _ctx.datastore;

  final Snowflake _guildId;

  TemplateManager(this._guildId, {required EntityContext ctx}) : _ctx = ctx;

  /// Fetch all templates for the guild, keyed by template code.
  /// ```dart
  /// final templates = await guild.templates.fetch();
  /// ```
  Future<Map<String, GuildTemplate>> fetch() =>
      _datastore.template.fetchForServer(_guildId.value);

  /// Get a template by its code (not guild-scoped).
  /// ```dart
  /// final template = await guild.templates.getByCode('AbCdEfGhIj');
  /// ```
  Future<GuildTemplate> getByCode(String code) =>
      _datastore.template.getByCode(code);

  /// Create a new template from the current guild state.
  /// ```dart
  /// final template = await guild.templates.create(name: 'My Template');
  /// ```
  Future<GuildTemplate> create({required String name, String? description}) =>
      _datastore.template.create(
        _guildId.value,
        name: name,
        description: description,
      );

  /// Sync a template to the guild's current state.
  /// ```dart
  /// await guild.templates.sync('AbCdEfGhIj');
  /// ```
  Future<GuildTemplate> sync(String code) =>
      _datastore.template.sync(_guildId.value, code);

  /// Update a template's name or description.
  /// ```dart
  /// await guild.templates.update('AbCdEfGhIj', name: 'New Name');
  /// ```
  Future<GuildTemplate> update(
    String code, {
    String? name,
    String? description,
  }) => _datastore.template.update(
    _guildId.value,
    code,
    name: name,
    description: description,
  );

  /// Delete a template. Returns the deleted template.
  /// ```dart
  /// final deleted = await guild.templates.delete('AbCdEfGhIj');
  /// ```
  Future<GuildTemplate> delete(String code) =>
      _datastore.template.delete(_guildId.value, code);
}
