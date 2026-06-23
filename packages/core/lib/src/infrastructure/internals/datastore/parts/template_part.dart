import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/base_part.dart';

final class TemplatePart extends BasePart implements TemplatePartContract {
  TemplatePart(super.marshaller, super.dataStore);

  @override
  Future<Map<String, GuildTemplate>> fetchForServer(Object serverId) async {
    final guildId = Snowflake.parse(serverId);
    final req =
        Request.json(endpoint: '/guilds/$guildId/templates');
    final result =
        await dataStore.requestBucket.get<List<Map<String, dynamic>>>(req);
    final templates = result.map(GuildTemplate.fromJson).toList();
    return {for (final t in templates) t.code: t};
  }

  @override
  Future<GuildTemplate> getByCode(String code) async {
    final req = Request.json(endpoint: '/guilds/templates/$code');
    final result =
        await dataStore.requestBucket.get<Map<String, dynamic>>(req);
    return GuildTemplate.fromJson(result);
  }

  @override
  Future<GuildTemplate> create(
    Object serverId, {
    required String name,
    String? description,
  }) async {
    final guildId = Snowflake.parse(serverId);
    final body = <String, dynamic>{
      'name': name,
      if (description != null) 'description': description,
    };
    final req = Request.json(endpoint: '/guilds/$guildId/templates', body: body);
    final result =
        await dataStore.requestBucket.post<Map<String, dynamic>>(req);
    return GuildTemplate.fromJson(result);
  }

  @override
  Future<GuildTemplate> sync(Object serverId, String code) async {
    final guildId = Snowflake.parse(serverId);
    final req =
        Request.json(endpoint: '/guilds/$guildId/templates/$code');
    final result =
        await dataStore.requestBucket.put<Map<String, dynamic>>(req);
    return GuildTemplate.fromJson(result);
  }

  @override
  Future<GuildTemplate> update(
    Object serverId,
    String code, {
    String? name,
    String? description,
  }) async {
    final guildId = Snowflake.parse(serverId);
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (description != null) 'description': description,
    };
    final req = Request.json(
        endpoint: '/guilds/$guildId/templates/$code', body: body);
    final result =
        await dataStore.requestBucket.patch<Map<String, dynamic>>(req);
    return GuildTemplate.fromJson(result);
  }

  @override
  Future<GuildTemplate> delete(Object serverId, String code) async {
    final guildId = Snowflake.parse(serverId);
    final req =
        Request.json(endpoint: '/guilds/$guildId/templates/$code');
    final result =
        await dataStore.requestBucket.delete<Map<String, dynamic>>(req);
    return GuildTemplate.fromJson(result);
  }
}
