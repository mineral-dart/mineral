import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class ScheduledEventManager {
  final EntityContext _ctx;
  DataStoreContract get _datastore => _ctx.datastore;

  final Snowflake _serverId;

  ScheduledEventManager(this._serverId, {required EntityContext ctx})
      : _ctx = ctx;

  /// Fetch all scheduled events for the server, keyed by event id.
  /// ```dart
  /// final events = await server.scheduledEvents.fetch();
  /// ```
  Future<Map<Snowflake, GuildScheduledEvent>> fetch({bool? withUserCount}) =>
      _datastore.scheduledEvent.fetchForServer(
        _serverId.value,
        withUserCount: withUserCount,
      );

  /// Get a scheduled event by its id.
  /// ```dart
  /// final event = await server.scheduledEvents.get('1234567890');
  /// ```
  Future<GuildScheduledEvent?> get(
    Object id, {
    bool force = false,
    bool? withUserCount,
  }) =>
      _datastore.scheduledEvent.get(
        _serverId.value,
        id,
        force,
        withUserCount: withUserCount,
      );

  /// Create a new scheduled event.
  /// ```dart
  /// final event = await server.scheduledEvents.create(
  ///   name: 'My Event',
  ///   privacyLevel: GuildScheduledEventPrivacyLevel.guildOnly,
  ///   scheduledStartTime: DateTime.now().add(Duration(hours: 1)),
  ///   entityType: GuildScheduledEventEntityType.external,
  ///   entityMetadata: GuildScheduledEventEntityMetadata(location: 'Online'),
  ///   scheduledEndTime: DateTime.now().add(Duration(hours: 2)),
  /// );
  /// ```
  Future<GuildScheduledEvent> create({
    required String name,
    required GuildScheduledEventPrivacyLevel privacyLevel,
    required DateTime scheduledStartTime,
    required GuildScheduledEventEntityType entityType,
    Object? channelId,
    GuildScheduledEventEntityMetadata? entityMetadata,
    DateTime? scheduledEndTime,
    String? description,
    String? image,
    String? reason,
  }) =>
      _datastore.scheduledEvent.create(
        serverId: _serverId.value,
        name: name,
        privacyLevel: privacyLevel,
        scheduledStartTime: scheduledStartTime,
        entityType: entityType,
        channelId: channelId,
        entityMetadata: entityMetadata,
        scheduledEndTime: scheduledEndTime,
        description: description,
        image: image,
        reason: reason,
      );

  /// Update an existing scheduled event.
  /// ```dart
  /// await server.scheduledEvents.update('1234567890', name: 'New Name');
  /// ```
  Future<GuildScheduledEvent?> update(
    Object id, {
    Object? channelId,
    GuildScheduledEventEntityMetadata? entityMetadata,
    String? name,
    GuildScheduledEventPrivacyLevel? privacyLevel,
    DateTime? scheduledStartTime,
    DateTime? scheduledEndTime,
    String? description,
    GuildScheduledEventEntityType? entityType,
    GuildScheduledEventStatus? status,
    String? image,
    String? reason,
  }) =>
      _datastore.scheduledEvent.update(
        serverId: _serverId.value,
        id: id,
        channelId: channelId,
        entityMetadata: entityMetadata,
        name: name,
        privacyLevel: privacyLevel,
        scheduledStartTime: scheduledStartTime,
        scheduledEndTime: scheduledEndTime,
        description: description,
        entityType: entityType,
        status: status,
        image: image,
        reason: reason,
      );

  /// Delete a scheduled event.
  /// ```dart
  /// await server.scheduledEvents.delete('1234567890');
  /// ```
  Future<void> delete(Object id, {String? reason}) =>
      _datastore.scheduledEvent.delete(
        serverId: _serverId.value,
        id: id,
        reason: reason,
      );

  /// Fetch users subscribed to a scheduled event.
  /// ```dart
  /// final users = await server.scheduledEvents.fetchUsers('1234567890');
  /// ```
  Future<List<GuildScheduledEventUser>> fetchUsers(
    Object id, {
    int? limit,
    bool? withMember,
    Object? before,
    Object? after,
  }) =>
      _datastore.scheduledEvent.fetchUsers(
        serverId: _serverId.value,
        id: id,
        limit: limit,
        withMember: withMember,
        before: before,
        after: after,
      );
}
