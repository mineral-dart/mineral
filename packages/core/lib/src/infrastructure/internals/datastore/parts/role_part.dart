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
    final req = Request.json(endpoint: '/guilds/$serverId/roles');
    final result = await dataStore.requestBucket
        .query<List<Map<String, dynamic>>>(req)
        .run(dataStore.client.get);

    final roles = await result.map((element) async {
      final raw = await marshaller.serializers.role.normalize({
        ...element,
        'guild_id': serverId,
      });

      return marshaller.serializers.role.serialize(raw);
    }).wait;

    return roles.asMap().map((_, value) => MapEntry(value.id, value));
  }

  @override
  Future<Role?> get(Object serverId, Object id, bool force) async {
    final String key = marshaller.cacheKey.serverRole(serverId, id);

    final cachedRole = await marshaller.cache?.get(key);
    if (!force && cachedRole != null) {
      final role = await marshaller.serializers.role.serialize(cachedRole);

      return role;
    }

    final req = Request.json(endpoint: '/guilds/$serverId/roles/$id');
    final result = await dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(dataStore.client.get);

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
    final req = Request.json(endpoint: '/guilds/$serverId/roles', body: {
      'name': name,
      'permissions': listToBitfield(permissions),
      'color': color.toInt(),
      'hoist': hoist,
      'mentionable': mentionable,
    }, headers: {
      DiscordHeader.auditLogReason(reason)
    });

    final result = await dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(dataStore.client.post);

    final raw = await marshaller.serializers.role.normalize(result);
    final role = await marshaller.serializers.role.serialize({
      ...raw,
      'guild_id': serverId,
    });

    return role;
  }

  @override
  Future<void> add(
      {required Object memberId,
      required Object serverId,
      required Object roleId,
      required String? reason}) async {
    final req = Request.json(
        endpoint: '/guilds/$serverId/members/$memberId/roles/$roleId',
        headers: {DiscordHeader.auditLogReason(reason)});

    await dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(dataStore.client.put);
  }

  @override
  Future<void> remove(
      {required Object memberId,
      required Object serverId,
      required Object roleId,
      required String? reason}) async {
    final req = Request.json(
        endpoint: '/guilds/$serverId/members/$memberId/roles/$roleId',
        headers: {DiscordHeader.auditLogReason(reason)});

    await dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(dataStore.client.delete);
  }

  @override
  Future<void> sync(
      {required Object memberId,
      required Object serverId,
      required List<Object> roleIds,
      required String? reason}) async {
    final req = Request.json(
        endpoint: '/guilds/$serverId/members/$memberId',
        body: {'roles': roleIds},
        headers: {DiscordHeader.auditLogReason(reason)});

    await dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(dataStore.client.patch);
  }

  @override
  Future<Role?> update(
      {required Object id,
      required Object serverId,
      required Map<String, dynamic> payload,
      required String? reason}) async {
    final req = Request.json(
        endpoint: '/guilds/$serverId/roles/$id',
        body: payload,
        headers: {DiscordHeader.auditLogReason(reason)});

    final result = await dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(dataStore.client.patch);

    final raw = await marshaller.serializers.role.normalize(result);
    final role = await marshaller.serializers.role.serialize({
      ...raw,
      'guild_id': serverId,
    });

    return role;
  }

  @override
  Future<void> delete(
      {required Object id,
      required Object serverId,
      required String? reason}) async {
    final req = Request.json(
        endpoint: '/guilds/$serverId/roles/$id',
        headers: {DiscordHeader.auditLogReason(reason)});

    await dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(dataStore.client.delete);
  }
}
