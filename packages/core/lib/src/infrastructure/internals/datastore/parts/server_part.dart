import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/base_part.dart';
import 'package:mineral/src/infrastructure/internals/http/discord_header.dart';

final class ServerPart extends BasePart implements ServerPartContract {
  ServerPart(super.marshaller, super.dataStore);

  @override
  Future<Server> get(Object id, bool force) async {
    final guildId = Snowflake.parse(id);
    final String key = marshaller.cacheKey.server(guildId.value);

    final cachedServer = await marshaller.cache?.get(key);
    if (!force && cachedServer != null) {
      final server =
          await marshaller.serializers.server.serialize(cachedServer);

      return server;
    }

    final req = Request.json(endpoint: '/guilds/$guildId');
    final result = await dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(dataStore.client.get);

    final raw = await marshaller.serializers.server.normalize(result);
    final server = await marshaller.serializers.server.serialize(raw);

    return server;
  }

  @override
  Future<Server> update(
      Object id, Map<String, dynamic> payload, String? reason) async {
    final guildId = Snowflake.parse(id);
    final req = Request.json(
        endpoint: '/guilds/$guildId',
        body: payload,
        headers: {DiscordHeader.auditLogReason(reason)});

    final response = await dataStore.client.patch(req);

    final rawServer = await marshaller.serializers.server
        .normalize(response.body as Map<String, dynamic>);
    return marshaller.serializers.server.serialize(rawServer);
  }

  @override
  Future<void> delete(Object id, String? reason) async {
    final guildId = Snowflake.parse(id);
    final req = Request.json(
        endpoint: '/guilds/$guildId',
        headers: {DiscordHeader.auditLogReason(reason)});

    await dataStore.client.delete(req);
  }
}
