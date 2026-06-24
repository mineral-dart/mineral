import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/base_part.dart';
import 'package:mineral/src/infrastructure/internals/http/discord_header.dart';

final class OnboardingPart extends BasePart
    implements OnboardingPartContract {
  OnboardingPart(super.marshaller, super.dataStore);

  @override
  Future<Onboarding> fetch(Object guildId) async {
    final parsedGuildId = Snowflake.parse(guildId);
    final req =
        Request.json(endpoint: '/guilds/$parsedGuildId/onboarding');
    final result =
        await dataStore.requestBucket.get<Map<String, dynamic>>(req);
    return Onboarding.fromJson(result);
  }

  @override
  Future<Onboarding> update(
    Object guildId, {
    List<OnboardingPrompt>? prompts,
    List<Object>? defaultChannelIds,
    bool? enabled,
    OnboardingMode? mode,
    String? reason,
  }) async {
    final parsedGuildId = Snowflake.parse(guildId);

    final body = <String, dynamic>{
      if (prompts != null)
        'prompts': prompts.map((p) => p.toJson()).toList(),
      if (defaultChannelIds != null)
        'default_channel_ids':
            defaultChannelIds.map((id) => id.toString()).toList(),
      if (enabled != null) 'enabled': enabled,
      if (mode != null) 'mode': mode.value,
    };

    final req = Request.json(
      endpoint: '/guilds/$parsedGuildId/onboarding',
      body: body,
      headers: {DiscordHeader.auditLogReason(reason)},
    );
    final result =
        await dataStore.requestBucket.put<Map<String, dynamic>>(req);
    return Onboarding.fromJson(result);
  }
}
