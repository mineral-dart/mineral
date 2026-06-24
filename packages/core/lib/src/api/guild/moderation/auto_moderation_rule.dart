import 'package:mineral/api.dart';
import 'package:mineral/src/api/guild/moderation/enums/auto_moderation_event_type.dart';
import 'package:mineral/src/api/guild/moderation/enums/trigger_type.dart';
import 'package:mineral/src/api/guild/moderation/trigger_metadata.dart';

final class AutoModerationRule {
  final Snowflake id;
  final Snowflake guildId;
  final String name;
  final Snowflake creatorId;
  final AutoModerationEventType eventTypes;
  final TriggerType triggerTypes;
  final TriggerMetadata triggerMetadata;
  final List<Action> action;
  final bool enabled;
  final List<Snowflake> exemptRoles;
  final List<Snowflake> exemptChannels;

  AutoModerationRule({
    required this.id,
    required this.guildId,
    required this.name,
    required this.creatorId,
    required this.eventTypes,
    required this.triggerTypes,
    required this.triggerMetadata,
    required this.action,
    required this.enabled,
    required this.exemptRoles,
    required this.exemptChannels,
  });
}
