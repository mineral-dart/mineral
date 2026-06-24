import 'package:mineral/api.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/services/marshaller/marshaller.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/types/channel_factory.dart';

final class UnknownChannelFactory
    implements ChannelFactoryContract<UnknownChannel> {
  @override
  ChannelType get type => ChannelType.unknown;

  @override
  Future<Map<String, dynamic>> normalize(
    MarshallerContract marshaller,
    Map<String, dynamic> json,
  ) async {
    final payload = {
      'id': json['id'],
      'type': json['type'],
      'name': json['name'],
    };

    final cacheKey = marshaller.cacheKey.channel(json['id'] as String);
    await marshaller.cache?.put(cacheKey, payload);

    return payload;
  }

  @override
  Future<UnknownChannel> serialize(
    MarshallerContract marshaller,
    EntityContext ctx,
    Map<String, dynamic> json,
  ) async {
    return UnknownChannel(
      id: Snowflake.parse(json['id']),
      name: json['name'] as String,
    );
  }

  @override
  Future<Map<String, dynamic>> deserialize(
    MarshallerContract marshaller,
    UnknownChannel channel,
  ) async {
    return {
      'id': channel.id.value,
      'type': channel.type.value,
      'name': channel.name,
    };
  }
}
