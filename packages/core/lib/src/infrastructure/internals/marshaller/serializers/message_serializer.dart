import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/types/serializer.dart';

final class MessageSerializer<T extends Message>
    implements SerializerContract<T> {
  final MarshallerContract _marshaller;
  final EntityContext _ctx;

  MessageSerializer(this._marshaller, this._ctx);

  @override
  Future<Map<String, dynamic>> normalize(Map<String, dynamic> json) async {
    final author = json['author'] as Map<String, dynamic>?;

    final payload = {
      'id': json['id'],
      'author_id': author?['id'],
      'content': json['content'],
      'embeds': json['embeds'] ?? [],
      'channel_id': json['channel_id'],
      'server_id': json['guild_id'],
      'author_is_bot': author?['bot'],
      'timestamp': json['timestamp'],
      'edited_timestamp': json['edited_timestamp'],
    };

    final cacheKey =
        _marshaller.cacheKey.message(json['channel_id'] as Object, json['id'] as Object);
    await _marshaller.cache?.put(cacheKey, payload);

    return payload;
  }

  @override
  Future<T> serialize(Map<String, dynamic> json) async {
    final messageProperties = MessageProperties.fromJson(
      json,
      embedSerializer: _marshaller.serializers.embed,
    );
    return Message(messageProperties) as T;
  }

  @override
  Future<Map<String, dynamic>> deserialize(T object) async {
    final embeds = object.embeds.map((message) {
      return _marshaller.serializers.embed.deserialize(message);
    });

    return {
      'id': object.id.value,
      'content': object.content,
      'embeds': embeds.toList(),
      'author_id': object.authorId?.value,
      'channel_id': object.channelId.value,
      'server_id': object.serverId?.value,
      'author_is_bot': object.authorIsBot,
      'timestamp': object.createdAt.toIso8601String(),
      'edited_timestamp': object.updatedAt?.toIso8601String(),
    };
  }
}
