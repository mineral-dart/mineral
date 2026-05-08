import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/api/server/moderation/enums/auto_moderation_event_type.dart';
import 'package:mineral/src/api/server/moderation/enums/trigger_type.dart';
import 'package:mineral/src/api/server/moderation/trigger_metadata.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/base_part.dart';
import 'package:mineral/src/infrastructure/internals/http/discord_header.dart';

final class RulesPart extends BasePart implements RulesPartContract {
  RulesPart(super.marshaller, super.dataStore);

  @override
  Future<Map<Snowflake, AutoModerationRule>> fetch(
      Object serverId, bool force) async {
    final guildId = Snowflake.parse(serverId);
    final req =
        Request.json(endpoint: '/guilds/$guildId/auto-moderation/rules');
    final result = await dataStore.requestBucket
        .query<List<dynamic>>(req)
        .run(dataStore.client.get);

    final rules = await result.map((element) async {
      final raw = await marshaller.serializers.rules
          .normalize(element as Map<String, dynamic>);
      return marshaller.serializers.rules.serialize(raw);
    }).wait;

    return rules.asMap().map((_, value) => MapEntry(value.id!, value));
  }

  @override
  Future<AutoModerationRule?> get(
      Object serverId, Object rulesId, bool force) async {
    final guildId = Snowflake.parse(serverId);
    final String key = marshaller.cacheKey.serverRules(guildId.value, rulesId);

    final cachedEmoji = await marshaller.cache?.get(key);
    if (!force && cachedEmoji != null) {
      final rule = await marshaller.serializers.rules.serialize(cachedEmoji);
      return rule;
    }

    final req = Request.json(
        endpoint: '/guilds/$guildId/auto-moderation/rules/$rulesId');
    final result = await dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(dataStore.client.get);

    final raw = await marshaller.serializers.rules.normalize(result);
    final rule = await marshaller.serializers.rules.serialize(raw);

    return rule;
  }

  @override
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
  }) async {
    final guildId = Snowflake.parse(serverId);
    final req = Request.json(
        endpoint: '/guilds/$guildId/auto-moderation/rules',
        body: {
          'name': name,
          'event_type': eventType.value,
          'trigger_type': triggerType.value,
          'trigger_metadata': triggerMetadata != null
              ? {
                  'keyword_filter': triggerMetadata.keywordFilter,
                  'regex_patterns': triggerMetadata.regexPatterns,
                  'presets':
                      triggerMetadata.presets.map((e) => e.value).toList(),
                  'allow_list': triggerMetadata.allowList,
                  'mention_total_limit': triggerMetadata.mentionTotalLimit,
                  'mention_raid_protection_enabled':
                      triggerMetadata.mentionRaidProtectionEnabled,
                }
              : null,
          'actions': actions
              .map((action) => {
                    'type': action.type.value,
                    if (action.metadata != null) 'metadata': action.metadata,
                  })
              .toList(),
          'exempt_roles': exemptRoles.map((e) => e.toString()).toList(),
          'exempt_channels': exemptChannels.map((e) => e.toString()).toList(),
          'enabled': enabled,
        },
        headers: {
          DiscordHeader.auditLogReason(reason)
        });
    final result = await dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(dataStore.client.post);

    final raw = await marshaller.serializers.rules.normalize({
      ...result,
      'guild_id': guildId,
    });
    final rule = await marshaller.serializers.rules.serialize(raw);

    return rule;
  }

  @override
  Future<AutoModerationRule?> update(
      {required Object id,
      required Object serverId,
      required Map<String, dynamic> payload,
      required String? reason}) async {
    final ruleId = Snowflake.parse(id);
    final guildId = Snowflake.parse(serverId);
    final req = Request.json(
        endpoint: '/guilds/$guildId/auto-moderation/rules/$ruleId',
        body: payload,
        headers: {DiscordHeader.auditLogReason(reason)});

    final result = await dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(dataStore.client.patch);

    final raw = await marshaller.serializers.rules.normalize({
      ...result,
      'guild_id': guildId,
    });
    final rule = await marshaller.serializers.rules.serialize(raw);

    return rule;
  }

  @override
  Future<void> delete(Object serverId, Object ruleId, {String? reason}) async {
    final guildId = Snowflake.parse(serverId);
    final req = Request.json(
        endpoint: '/guilds/$guildId/auto-moderation/rules/$ruleId',
        headers: {DiscordHeader.auditLogReason(reason)});

    await dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(dataStore.client.delete);
  }
}
