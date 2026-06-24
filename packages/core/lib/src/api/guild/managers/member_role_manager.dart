import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class MemberRoleManager {
  final EntityContext _ctx;
  DataStoreContract get _datastore => _ctx.datastore;

  final List<Snowflake> currentIds;
  final Snowflake _guildId;
  final Snowflake _memberId;

  MemberRoleManager(this.currentIds, this._guildId, this._memberId,
      {required EntityContext ctx})
      : _ctx = ctx;

  Future<Map<Snowflake, Role>> fetch({bool force = false}) async {
    final roles = await _datastore.role.fetch(_guildId.value, force);
    return Map.fromEntries(roles.entries
        .where((element) => currentIds.contains(element.key))
        .map((e) => MapEntry(e.key, e.value)));
  }

  Future<void> add(String roleId, {String? reason}) async {
    return _datastore.role.add(
        memberId: _memberId.value,
        guildId: _guildId.value,
        roleId: roleId,
        reason: reason);
  }

  Future<void> remove(String roleId, {String? reason}) async {
    return _datastore.role.remove(
        memberId: _memberId.value,
        guildId: _guildId.value,
        roleId: roleId,
        reason: reason);
  }

  Future<void> sync(List<String> roleIds, {String? reason}) async {
    return _datastore.role.sync(
        memberId: _memberId.value,
        guildId: _guildId.value,
        roleIds: roleIds,
        reason: reason);
  }

  Future<void> clear({String? reason}) async {
    return _datastore.role.sync(
        memberId: _memberId.value,
        guildId: _guildId.value,
        roleIds: [],
        reason: reason);
  }
}
