import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class RoleManager {
  final EntityContext _ctx;
  DataStoreContract get _datastore => _ctx.datastore;

  final Snowflake _serverId;

  RoleManager(this._serverId, {required EntityContext ctx}) : _ctx = ctx;

  /// Fetch the server's channels.
  /// ```dart
  /// final channels = await server.channels.fetch();
  /// ```
  Future<Map<Snowflake, Role>> fetch({bool force = false}) =>
      _datastore.role.fetch(_serverId.value, force);

  /// Get a channel by its id.
  /// ```dart
  /// final channel = await server.channels.get('1091121140090535956');
  /// ```
  Future<Role?> get(String id, {bool force = false}) =>
      _datastore.role.get(_serverId.value, id, force);

  /// Create a new role.
  /// ```dart
  /// final role = await server.roles.create('New Role');
  /// ```
  Future<Role> create(
          {required String name,
          required List<Permission> permissions,
          required Color color,
          bool hoist = false,
          bool mentionable = false,
          String? reason}) =>
      _datastore.role.create(_serverId.value, name, permissions, color, hoist,
          mentionable, reason);
}
