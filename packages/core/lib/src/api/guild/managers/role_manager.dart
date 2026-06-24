import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class RoleManager {
  final EntityContext _ctx;
  DataStoreContract get _datastore => _ctx.datastore;

  final Snowflake _guildId;

  RoleManager(this._guildId, {required EntityContext ctx}) : _ctx = ctx;

  /// Fetch the guild's channels.
  /// ```dart
  /// final channels = await guild.channels.fetch();
  /// ```
  Future<Map<Snowflake, Role>> fetch({bool force = false}) =>
      _datastore.role.fetch(_guildId.value, force);

  /// Get a channel by its id.
  /// ```dart
  /// final channel = await guild.channels.get('1091121140090535956');
  /// ```
  Future<Role?> get(String id, {bool force = false}) =>
      _datastore.role.get(_guildId.value, id, force);

  /// Create a new role.
  /// ```dart
  /// final role = await guild.roles.create('New Role');
  /// ```
  Future<Role> create(
          {required String name,
          required List<Permission> permissions,
          required Color color,
          bool hoist = false,
          bool mentionable = false,
          String? reason}) =>
      _datastore.role.create(_guildId.value, name, permissions, color, hoist,
          mentionable, reason);
}
