import 'package:mineral/api.dart';
import 'package:mineral/src/domains/services/marshaller/marshaller.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/types/message_factory.dart';

final class PrivateMessageFactory implements MessageFactory<PrivateMessage> {
  final MarshallerContract _marshaller;

  PrivateMessageFactory(this._marshaller);

  @override
  Future<PrivateMessage> serialize(Map<String, dynamic> json) async {
    final messageProperties = MessageProperties<PrivateChannel>.fromJson(
      json,
      embedSerializer: _marshaller.serializers.embed,
    );
    return Message(messageProperties);
  }

  @override
  Map<String, dynamic> deserialize(PrivateMessage message) {
    return {
      'id': message.id,
      'content': message.content,
      'embeds': message.embeds
          .map(_marshaller.serializers.embed.deserialize)
          .toList(),
      'channel_id': message.channelId,
      'created_at': message.createdAt.toIso8601String(),
      'updated_at': message.updatedAt?.toIso8601String(),
    };
  }
}
