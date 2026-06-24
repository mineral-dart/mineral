import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/api/guild/moderation/enums/auto_moderation_event_type.dart';
import 'package:mineral/src/api/guild/moderation/enums/trigger_type.dart';
import 'package:mineral/src/api/guild/moderation/trigger_metadata.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class RulesManager {
  final EntityContext _ctx;
  DataStoreContract get _datastore => _ctx.datastore;

  final Snowflake _guildId;

  RulesManager(this._guildId, {required EntityContext ctx}) : _ctx = ctx;

  /// Fetch the guild's channels.
  /// ```dart
  /// final channels = await guild.channels.fetch();
  /// ```
  Future<Map<Snowflake, AutoModerationRule>> fetch({bool force = false}) =>
      _datastore.rules.fetch(_guildId.value, force);

  /// Get a channel by its id.
  /// ```dart
  /// final channel = await guild.channels.get('1091121140090535956');
  /// ```
  Future<AutoModerationRule?> get(String id, {bool force = false}) =>
      _datastore.rules.get(_guildId.value, id, force);

  /// Create a new emoji.
  /// ```dart
  /// final emoji = await guild.emojis.create(name: 'New Emoji', );
  /// ```
  Future<AutoModerationRule> create({
    required Object guildId,
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
        guildId: guildId,
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
