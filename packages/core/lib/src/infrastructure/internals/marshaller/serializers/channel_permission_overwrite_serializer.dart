import 'package:mineral/api.dart';
import 'package:mineral/src/domains/common/utils/utils.dart';
import 'package:mineral/src/domains/services/marshaller/marshaller.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/types/serializer.dart';

final class ChannelPermissionOverwriteSerializer
    implements SerializerContract<ChannelPermissionOverwrite> {
  final MarshallerContract _marshaller;

  ChannelPermissionOverwriteSerializer(this._marshaller);

  @override
  Future<Map<String, dynamic>> normalize(Map<String, dynamic> json) async {
    final payload = {
      'id': json['id'],
      'type': json['type'],
      'allow': json['allow'],
      'deny': json['deny'],
    };

    final cacheKey = _marshaller.cacheKey
        .channelPermission(payload['id'] as Object, serverId: json['server_id'] as Object?);
    await _marshaller.cache?.put(cacheKey, payload);

    return payload;
  }

  @override
  ChannelPermissionOverwrite serialize(Map<String, dynamic> json) {
    return ChannelPermissionOverwrite(
      id: json['id'].toString(),
      type: findInEnum(ChannelPermissionOverwriteType.values, json['type'],
          orElse: ChannelPermissionOverwriteType.unknown),
      allow: bitfieldToList(Permission.values, int.parse(json['allow'] as String)),
      deny: bitfieldToList(Permission.values, int.parse(json['deny'] as String)),
    );
  }

  @override
  Map<String, dynamic> deserialize(ChannelPermissionOverwrite permission) {
    return {
      'id': permission.id,
      'type': permission.type.value,
      'allow': permission.allow,
      'deny': permission.deny,
    };
  }
}
