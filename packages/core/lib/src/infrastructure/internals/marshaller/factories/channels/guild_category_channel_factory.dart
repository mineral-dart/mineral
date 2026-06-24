import 'package:mineral/src/api/common/channel_properties.dart';
import 'package:mineral/src/api/common/types/channel_type.dart';
import 'package:mineral/src/api/guild/channels/guild_category_channel.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/services/marshaller/marshaller.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/types/channel_factory.dart';

final class GuildCategoryChannelFactory
    implements ChannelFactoryContract<GuildCategoryChannel> {
  @override
  ChannelType get type => ChannelType.guildCategory;

  @override
  Future<Map<String, dynamic>> normalize(
    MarshallerContract marshaller,
    Map<String, dynamic> json,
  ) async {
    final payload = {
      'id': json['id'],
      'type': json['type'],
      'position': json['position'],
      'name': json['name'],
      'description': json['topic'],
      'nsfw': json['nsfw'],
      'guild_id': json['guild_id'],
      'permission_overwrites': json['permission_overwrites'],
    };

    final cacheKey = marshaller.cacheKey.channel(json['id'] as String);
    await marshaller.cache?.put(cacheKey, payload);

    return payload;
  }

  @override
  Future<GuildCategoryChannel> serialize(
    MarshallerContract marshaller,
    EntityContext ctx,
    Map<String, dynamic> json,
  ) async {
    final properties = await ChannelProperties.serializeCache(
      marshaller,
      ctx,
      json,
    );
    return GuildCategoryChannel(properties);
  }

  @override
  Future<Map<String, dynamic>> deserialize(
    MarshallerContract marshaller,
    GuildCategoryChannel channel,
  ) async {
    final permissions = await Future.wait(
      channel.permissions.map(
        (element) async => marshaller.serializers.channelPermissionOverwrite
            .deserialize(element),
      ),
    );

    return {
      'id': channel.id.value,
      'name': channel.name,
      'type': channel.type.value,
      'position': channel.position,
      'permission_overwrites': permissions,
      'guild_id': channel.guildId,
    };
  }
}
