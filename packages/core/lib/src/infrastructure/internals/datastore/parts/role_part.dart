import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/domains/common/utils/utils.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/base_part.dart';
import 'package:mineral/src/infrastructure/internals/http/discord_header.dart';

final class RolePart extends BasePart implements RolePartContract {
  RolePart(super.marshaller, super.dataStore);

  @override
  Future<Map<Snowflake, Role>> fetch(Object serverId, bool force) async {
    final guildId = Snowflake.parse(serverId);
    final req = Request.json(endpoint: '/guilds/$guildId/roles');
    final result = await dataStore.requestBucket.get<List<Map<String, dynamic>>>(req);

    final roles = await result.map((element) async {
      final raw = await marshaller.serializers.role.normalize({
        ...element,
        'guild_id': guildId,
      });

      return marshaller.serializers.role.serialize(raw);
    }).wait;

    return roles.asMap().map((_, value) => MapEntry(value.id, value));
  }

  @override
  Future<Role?> get(Object serverId, Object id, bool force) async {
    final guildId = Snowflake.parse(serverId);
    final roleId = Snowflake.parse(id);
    final String key = marshaller.cacheKey.serverRole(guildId.value, roleId.value);

    final cachedRole = await marshaller.cache?.get(key);
    if (!force && cachedRole != null) {
      final role = await marshaller.serializers.role.serialize(cachedRole);

      return role;
    }

    final req = Request.json(endpoint: '/guilds/$guildId/roles/$roleId');
    final result = await dataStore.requestBucket.get<Map<String, dynamic>>(req);

    final raw = await marshaller.serializers.role.normalize(result);
    final channel = await marshaller.serializers.role.serialize(raw);

    return channel;
  }

  @override
  Future<Role> create(
      Object serverId,
      String name,
      List<Permission> permissions,
      Color color,
      bool hoist,
      bool mentionable,
      String? reason) async {
    final guildId = Snowflake.parse(serverId);
    final req = Request.json(endpoint: '/guilds/$guildId/roles', body: {
      'name': name,
      'permissions': listToBitfield(permissions),
      'color': color.toInt(),
      'hoist': hoist,
      'mentionable': mentionable,
    }, headers: {
      DiscordHeader.auditLogReason(reason)
    });

    final result = await dataStore.requestBucket.post<Map<String, dynamic>>(req);

    final raw = await marshaller.serializers.role.normalize(result);
    final role = await marshaller.serializers.role.serialize({
      ...raw,
      'guild_id': guildId,
    });

    return role;
  }

  @override
  Future<void> add(
      {required Object memberId,
      required Object serverId,
      required Object roleId,
      required String? reason}) async {
    final userId = Snowflake.parse(memberId);
    final guildId = Snowflake.parse(serverId);
    final req = Request.json(
        endpoint: '/guilds/$guildId/members/$userId/roles/$roleId',
        headers: {DiscordHeader.auditLogReason(reason)});

    await dataStore.requestBucket.put<Map<String, dynamic>>(req);
  }

  @override
  Future<void> remove(
      {required Object memberId,
      required Object serverId,
      required Object roleId,
      required String? reason}) async {
    final userId = Snowflake.parse(memberId);
    final guildId = Snowflake.parse(serverId);
    final req = Request.json(
        endpoint: '/guilds/$guildId/members/$userId/roles/$roleId',
        headers: {DiscordHeader.auditLogReason(reason)});

    await dataStore.requestBucket.delete<Map<String, dynamic>>(req);
  }

  @override
  Future<void> sync(
      {required Object memberId,
      required Object serverId,
      required List<Object> roleIds,
      required String? reason}) async {
    final userId = Snowflake.parse(memberId);
    final guildId = Snowflake.parse(serverId);
    final req = Request.json(
        endpoint: '/guilds/$guildId/members/$userId',
        body: {'roles': roleIds},
        headers: {DiscordHeader.auditLogReason(reason)});

    await dataStore.requestBucket.patch<Map<String, dynamic>>(req);
  }

  @override
  Future<Role?> update(
      {required Object id,
      required Object serverId,
      required Map<String, dynamic> payload,
      required String? reason}) async {
    final roleId = Snowflake.parse(id);
    final guildId = Snowflake.parse(serverId);
    final req = Request.json(
        endpoint: '/guilds/$guildId/roles/$roleId',
        body: payload,
        headers: {DiscordHeader.auditLogReason(reason)});

    final result = await dataStore.requestBucket.patch<Map<String, dynamic>>(req);

    final raw = await marshaller.serializers.role.normalize(result);
    final role = await marshaller.serializers.role.serialize({
      ...raw,
      'guild_id': guildId,
    });

    return role;
  }

  @override
  Future<void> delete(
      {required Object id,
      required Object serverId,
      required String? reason}) async {
    final roleId = Snowflake.parse(id);
    final guildId = Snowflake.parse(serverId);
    final req = Request.json(
        endpoint: '/guilds/$guildId/roles/$roleId',
        headers: {DiscordHeader.auditLogReason(reason)});

    await dataStore.requestBucket.delete<Map<String, dynamic>>(req);
  }
}
