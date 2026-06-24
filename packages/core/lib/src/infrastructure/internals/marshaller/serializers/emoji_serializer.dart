import 'dart:async';

import 'package:mineral/src/api/common/emoji.dart';
import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/services/marshaller/marshaller.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/types/serializer.dart';

final class EmojiSerializer implements SerializerContract<Emoji> {
  final MarshallerContract _marshaller;
  final EntityContext _ctx;

  EmojiSerializer(this._marshaller, this._ctx);

  @override
  Future<Map<String, dynamic>> normalize(Map<String, dynamic> json) async {
    final payload = {
      'id': json['id'],
      'name': json['name'],
      'managed': json['managed'] ?? false,
      'available': json['available'] ?? false,
      'animated': json['animated'] ?? false,
      'roles': json['roles'] != null
          ? List.from(json['roles'] as Iterable<dynamic>)
              .map((element) => _marshaller.cacheKey
                  .guildEmoji(json['guild_id'] as String, (element as Map<String, dynamic>)['id'] as String))
              .toList()
          : <String>[],
      'guild_id': json['guild_id'],
    };

    final cacheKey =
        _marshaller.cacheKey.guildEmoji(json['guild_id'] as String, json['id'] as String);
    await _marshaller.cache?.put(cacheKey, payload);

    return payload;
  }

  @override
  Future<Emoji> serialize(Map<String, dynamic> json) async {
    final rawRoles = await _marshaller.cache?.getMany(json['roles'] as List<String>);
    final roles = await rawRoles?.nonNulls.map((element) async {
      return _marshaller.serializers.role.serialize(element);
    }).wait;

    return Emoji(
      Snowflake.parse(json['guild_id']),
      ctx: _ctx,
      id: Snowflake.parse(json['id']),
      name: json['name'] as String,
      roles: roles?.fold(
              {}, (value, element) => {...?value, element.id: element}) ??
          {},
      managed: json['managed'] as bool,
      animated: json['animated'] as bool,
      available: json['available'] as bool,
    );
  }

  @override
  Map<String, dynamic> deserialize(Emoji emoji) {
    return {
      'id': emoji.id?.value,
      'name': emoji.name,
      'roles': emoji.roles.keys.toList(),
      'managed': emoji.managed,
      'animated': emoji.animated,
      'available': emoji.available,
      'guild_id': emoji.guildId.value,
    };
  }
}
