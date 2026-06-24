import 'package:mineral/src/api/common/color.dart';
import 'package:mineral/src/api/common/permissions.dart';
import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/api/guild/role.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/common/utils/utils.dart';
import 'package:mineral/src/domains/services/marshaller/marshaller.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/types/serializer.dart';

final class RoleSerializer implements SerializerContract<Role> {
  final MarshallerContract _marshaller;
  final EntityContext _ctx;

  RoleSerializer(this._marshaller, this._ctx);

  @override
  Future<Map<String, dynamic>> normalize(Map<String, dynamic> json) async {
    final payload = {
      'id': json['id'],
      'name': json['name'],
      'color': json['color'],
      'hoist': json['hoist'],
      'position': json['position'],
      'permissions': json['permissions'],
      'managed': json['managed'],
      'mentionable': json['mentionable'],
      'flags': json['flags'],
      'guild_id': json['guild_id'],
    };

    final cacheKey = _marshaller.cacheKey.guildRole(
      json['guild_id'] as String,
      json['id'] as String,
    );
    await _marshaller.cache?.put(cacheKey, payload);

    return payload;
  }

  @override
  Future<Role> serialize(Map<String, dynamic> json) async => Role(
    ctx: _ctx,
    id: Snowflake.parse(json['id']),
    name: json['name'] as String,
    color: Color.of(json['color'] as int? ?? 0),
    hoist: json['hoist'] as bool? ?? false,
    position: json['position'] as int? ?? 0,
    permissions: switch (json['permissions']) {
      int() => Permissions.fromInt(json['permissions'] as int),
      String() => Permissions.fromInt(int.parse(json['permissions'] as String)),
      _ => Permissions.fromInt(0),
    },
    managed: json['managed'] as bool,
    mentionable: json['mentionable'] as bool,
    flags: json['flags'] as int,
    icon: json['icon'] as String?,
    unicodeEmoji: json['unicode_emoji'] as String?,
    guildId: Snowflake.parse(json['guild_id']),
  );

  @override
  Map<String, dynamic> deserialize(Role object) {
    return {
      'id': object.id,
      'name': object.name,
      'color': object.color.toInt(),
      'hoist': object.hoist,
      'position': object.position,
      'permissions': listToBitfield(object.permissions.list),
      'managed': object.managed,
      'mentionable': object.mentionable,
      'flags': object.flags,
    };
  }
}
