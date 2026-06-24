import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/base_part.dart';
import 'package:mineral/src/infrastructure/internals/http/discord_header.dart';

final class WelcomeScreenPart extends BasePart
    implements WelcomeScreenPartContract {
  WelcomeScreenPart(super.marshaller, super.dataStore);

  @override
  Future<WelcomeScreen> fetch(Object guildId) async {
    final parsedGuildId = Snowflake.parse(guildId);
    final req =
        Request.json(endpoint: '/guilds/$parsedGuildId/welcome-screen');
    final result =
        await dataStore.requestBucket.get<Map<String, dynamic>>(req);
    return WelcomeScreen.fromJson(result);
  }

  @override
  Future<WelcomeScreen> update(
    Object guildId, {
    bool? enabled,
    List<Map<String, dynamic>>? welcomeChannels,
    String? description,
    String? reason,
  }) async {
    final parsedGuildId = Snowflake.parse(guildId);

    final body = <String, dynamic>{
      if (enabled != null) 'enabled': enabled,
      if (welcomeChannels != null) 'welcome_channels': welcomeChannels,
      if (description != null) 'description': description,
    };

    final req = Request.json(
      endpoint: '/guilds/$parsedGuildId/welcome-screen',
      body: body,
      headers: {DiscordHeader.auditLogReason(reason)},
    );
    final result =
        await dataStore.requestBucket.patch<Map<String, dynamic>>(req);
    return WelcomeScreen.fromJson(result);
  }
}
