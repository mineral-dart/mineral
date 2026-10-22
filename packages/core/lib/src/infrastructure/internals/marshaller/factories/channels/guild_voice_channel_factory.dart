import 'package:mineral/api.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/services/marshaller/marshaller.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/types/channel_factory.dart';

final class GuildVoiceChannelFactory
    implements ChannelFactoryContract<GuildVoiceChannel> {
  @override
  ChannelType get type => ChannelType.guildVoice;

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
      'guild_id': json['guild_id'],
      'parent_id': json['parent_id'],
      'permission_overwrites': json['permission_overwrites'],
    };

    final cacheKey = marshaller.cacheKey.channel(json['id'] as String);
    await marshaller.cache?.put(cacheKey, payload);

    return payload;
  }

  @override
  Future<GuildVoiceChannel> serialize(
    MarshallerContract marshaller,
    EntityContext ctx,
    Map<String, dynamic> json,
  ) async {
    final properties = await ChannelProperties.serializeCache(
      marshaller,
      ctx,
      json,
    );
    final keys = await marshaller.serializers.voiceStateIndex.keysFor(
      properties.guildId!.value,
    );
    final voices = keys.isEmpty
        ? const <Map<String, dynamic>?>[]
        : await marshaller.cache!.getMany(keys);
    final List<VoiceState> members = [];

    for (final voice in voices) {
      if (voice != null &&
          voice['channel_id'].toString() == properties.id.value) {
        final voiceState = await marshaller.serializers.voice.serialize(voice);
        members.add(voiceState);
      }
    }

    return GuildVoiceChannel(properties)..members = members;
  }

  @override
  Future<Map<String, dynamic>> deserialize(
    MarshallerContract marshaller,
    GuildVoiceChannel channel,
  ) async {
    final permissions = await Future.wait(
      channel.permissions.map(
        (element) async => marshaller.serializers.channelPermissionOverwrite
            .deserialize(element),
      ),
    );

    return {
      'id': channel.id.value,
      'type': channel.type.value,
      'name': channel.name,
      'position': channel.position,
      'guild_id': channel.guildId,
      'permission_overwrites': permissions,
      'parent_id': channel.categoryId,
    };
  }
}
