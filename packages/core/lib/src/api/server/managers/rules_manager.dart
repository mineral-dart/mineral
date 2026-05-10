import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/api/server/moderation/enums/auto_moderation_event_type.dart';
import 'package:mineral/src/api/server/moderation/enums/trigger_type.dart';
import 'package:mineral/src/api/server/moderation/trigger_metadata.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class RulesManager {
  final EntityContext _ctx;
  DataStoreContract get _datastore => _ctx.datastore;

  final Snowflake _serverId;

  RulesManager(this._serverId, {required EntityContext ctx}) : _ctx = ctx;

  /// Fetch the server's channels.
  /// ```dart
  /// final channels = await server.channels.fetch();
  /// ```
  Future<Map<Snowflake, AutoModerationRule>> fetch({bool force = false}) =>
      _datastore.rules.fetch(_serverId.value, force);

  /// Get a channel by its id.
  /// ```dart
  /// final channel = await server.channels.get('1091121140090535956');
  /// ```
  Future<AutoModerationRule?> get(String id, {bool force = false}) =>
      _datastore.rules.get(_serverId.value, id, force);

  /// Create a new emoji.
  /// ```dart
  /// final emoji = await server.emojis.create(name: 'New Emoji', );
  /// ```
  Future<AutoModerationRule> create({
    required Object serverId,
    required String name,
    required AutoModerationEventType eventType,
    required TriggerType triggerType,
    required List<Action> actions,
    TriggerMetadata? triggerMetadata,
    List<Snowflake> exemptRoles = const [],
    List<Snowflake> exemptChannels = const [],
    bool enabled = true,
    String? reason,
  }) =>
      _datastore.rules.create(
        serverId: serverId,
        name: name,
        eventType: eventType,
        triggerType: triggerType,
        actions: actions,
        triggerMetadata: triggerMetadata,
        exemptRoles: exemptRoles,
        exemptChannels: exemptChannels,
        enabled: enabled,
        reason: reason,
      );
}
