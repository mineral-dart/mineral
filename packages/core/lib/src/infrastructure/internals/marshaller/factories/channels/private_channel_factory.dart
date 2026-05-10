import 'package:mineral/src/api/common/channel_properties.dart';
import 'package:mineral/src/api/common/types/channel_type.dart';
import 'package:mineral/src/api/private/channels/private_channel.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/services/marshaller/marshaller.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/types/channel_factory.dart';

final class PrivateChannelFactory
    implements ChannelFactoryContract<PrivateChannel> {
  @override
  ChannelType get type => ChannelType.dm;

  @override
  Future<PrivateChannel> serialize(MarshallerContract marshaller,
      EntityContext ctx, Map<String, dynamic> json) async {
    final properties =
        await ChannelProperties.serializeCache(marshaller, ctx, json);
    return PrivateChannel(properties);
  }

  @override
  Future<Map<String, dynamic>> normalize(
      MarshallerContract marshaller, Map<String, dynamic> json) async {
    final payload = {
      'id': json['id'],
      'type': json['type'],
      'recipients': json['recipients'],
      'name': json['name'] ?? json['recipients'].join(', '),
      'description': json['description'],
      'message_count': json['message_count'],
      'user_count': json['user_count'],
    };

    final cacheKey = marshaller.cacheKey.channel(json['id'] as String);
    await marshaller.cache?.put(cacheKey, payload);

    return payload;
  }

  @override
  Map<String, dynamic> deserialize(
      MarshallerContract marshaller, PrivateChannel channel) {
    return {
      'id': channel.id.value,
      'type': channel.type.value,
      'recipients': channel.recipients.map((user) => user.id.value).toList(),
      'name': channel.name,
      'description': channel.description,
      'message_count': channel.messageCount,
      'user_count': channel.userCount,
    };
  }
}
