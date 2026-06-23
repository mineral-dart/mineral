import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class TemplateManager {
  final EntityContext _ctx;
  DataStoreContract get _datastore => _ctx.datastore;

  final Snowflake _serverId;

  TemplateManager(this._serverId, {required EntityContext ctx}) : _ctx = ctx;

  /// Fetch all templates for the server, keyed by template code.
  /// ```dart
  /// final templates = await server.templates.fetch();
  /// ```
  Future<Map<String, GuildTemplate>> fetch() =>
      _datastore.template.fetchForServer(_serverId.value);

  /// Get a template by its code (not guild-scoped).
  /// ```dart
  /// final template = await server.templates.getByCode('AbCdEfGhIj');
  /// ```
  Future<GuildTemplate> getByCode(String code) =>
      _datastore.template.getByCode(code);

  /// Create a new template from the current server state.
  /// ```dart
  /// final template = await server.templates.create(name: 'My Template');
  /// ```
  Future<GuildTemplate> create({
    required String name,
    String? description,
  }) =>
      _datastore.template.create(
        _serverId.value,
        name: name,
        description: description,
      );

  /// Sync a template to the server's current state.
  /// ```dart
  /// await server.templates.sync('AbCdEfGhIj');
  /// ```
  Future<GuildTemplate> sync(String code) =>
      _datastore.template.sync(_serverId.value, code);

  /// Update a template's name or description.
  /// ```dart
  /// await server.templates.update('AbCdEfGhIj', name: 'New Name');
  /// ```
  Future<GuildTemplate> update(
    String code, {
    String? name,
    String? description,
  }) =>
      _datastore.template.update(
        _serverId.value,
        code,
        name: name,
        description: description,
      );

  /// Delete a template. Returns the deleted template.
  /// ```dart
  /// final deleted = await server.templates.delete('AbCdEfGhIj');
  /// ```
  Future<GuildTemplate> delete(String code) =>
      _datastore.template.delete(_serverId.value, code);
}
