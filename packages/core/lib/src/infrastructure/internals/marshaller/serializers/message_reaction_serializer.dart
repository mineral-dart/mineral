import 'package:mineral/api.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/services/marshaller/marshaller.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/types/serializer.dart';

final class MessageReactionSerializer<T extends Message>
    implements SerializerContract<MessageReaction> {
  // ignore: unused_field
  final MarshallerContract _marshaller;
  final EntityContext _ctx;

  MessageReactionSerializer(this._marshaller, this._ctx);

  @override
  Future<Map<String, dynamic>> normalize(Map<String, dynamic> json) async {
    return {
      'id': json['id'],
      'author_id': json['user_id'],
      'content': json['content'],
      'embeds': json['embeds'],
      'channel_id': json['channel_id'],
      'guild_id': json['guild_id'],
      'emoji': json['emoji'],
      'message_id': json['message_id'],
      'timestamp': json['timestamp'],
      'edited_timestamp': json['edited_timestamp'],
      'is_burst': json['burst'],
      'type': json['type'],
    };
  }

  @override
  Future<MessageReaction> serialize(Map<String, dynamic> json) async {
    return MessageReaction(
      ctx: _ctx,
      guildId: Snowflake.nullable(json['guild_id']),
      channelId: Snowflake.parse(json['channel_id']),
      userId: Snowflake.parse(json['author_id']),
      messageId: Snowflake.parse(json['message_id']),
      emoji: PartialEmoji(
        (json['emoji'] as Map<String, dynamic>?)?['id'] as Snowflake?,
        ((json['emoji'] as Map<String, dynamic>?)?['name'] as String?) ?? '',
        (json['emoji'] as Map<String, dynamic>?)?['animated'] as bool? ?? false,
      ),
      isBurst: json['is_burst'] as bool? ?? false,
      type: MessageReactionType.values[json['type'] as int],
    );
  }

  @override
  Future<Map<String, dynamic>> deserialize(MessageReaction object) async {
    return {
      'id': object.guildId?.value,
      'author_id': object.channelId.value,
      'content': object.userId.value,
      'embeds': object.messageId.value,
      'channel_id': object.channelId?.value,
      'guild_id': object.emoji.id,
      'emoji': {
        'id': object.emoji.id,
        'name': object.emoji.name,
        'animated': object.emoji.animated,
      },
      'message_id': object.messageId.value,
      'timestamp': object.isBurst,
      'edited_timestamp': object.type.value,
    };
  }
}
