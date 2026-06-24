import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/base_part.dart';
import 'package:mineral/src/infrastructure/internals/http/discord_header.dart';

final class GuildPart extends BasePart implements GuildPartContract {
  GuildPart(super.marshaller, super.dataStore);

  @override
  Future<Guild> get(Object id, bool force) async {
    final guildId = Snowflake.parse(id);
    final String key = marshaller.cacheKey.guild(guildId.value);

    final cachedServer = await marshaller.cache?.get(key);
    if (!force && cachedServer != null) {
      final guild = await marshaller.serializers.guild.serialize(cachedServer);

      return guild;
    }

    final req = Request.json(endpoint: '/guilds/$guildId');
    final result = await dataStore.requestBucket.get<Map<String, dynamic>>(req);

    final raw = await marshaller.serializers.guild.normalize(result);
    final guild = await marshaller.serializers.guild.serialize(raw);

    return guild;
  }

  @override
  Future<Guild> update(
    Object id,
    Map<String, dynamic> payload,
    String? reason,
  ) async {
    final guildId = Snowflake.parse(id);
    final req = Request.json(
      endpoint: '/guilds/$guildId',
      body: payload,
      headers: {DiscordHeader.auditLogReason(reason)},
    );

    final response = await dataStore.client.patch(req);

    final rawServer = await marshaller.serializers.guild.normalize(
      response.body as Map<String, dynamic>,
    );
    return marshaller.serializers.guild.serialize(rawServer);
  }

  @override
  Future<void> delete(Object id, String? reason) async {
    final guildId = Snowflake.parse(id);
    final req = Request.json(
      endpoint: '/guilds/$guildId',
      headers: {DiscordHeader.auditLogReason(reason)},
    );

    await dataStore.client.delete(req);
  }
}
