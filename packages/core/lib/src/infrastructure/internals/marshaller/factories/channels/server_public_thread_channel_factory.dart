import 'package:mineral/src/api/common/channel_properties.dart';
import 'package:mineral/src/api/common/types/channel_type.dart';
import 'package:mineral/src/api/server/channels/public_thread_channel.dart';
import 'package:mineral/src/api/server/threads/thread_metadata.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/services/marshaller/marshaller.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/types/channel_factory.dart';

final class ServerPublicThreadChannelFactory
    implements ChannelFactoryContract<PublicThreadChannel> {
  @override
  ChannelType get type => ChannelType.guildPublicThread;

  @override
  Future<Map<String, dynamic>> normalize(
      MarshallerContract marshaller, Map<String, dynamic> json) async {
    final payload = {
      'id': json['id'],
      'type': json['type'],
      'last_message_id': json['last_message_id'],
      'flags': json['flags'],
      'server_id': json['guild_id'],
      'name': json['name'],
      'parent_id': json['parent_id'],
      'rate_limit_per_user': json['rate_limit_per_user'],
      'bitrate': json['bitrate'],
      'user_limit': json['user_limit'],
      'rtc_region': json['rtc_region'],
      'owner_id': json['owner_id'],
      'thread_metadata': {
        'archived': json['thread_metadata']['archived'],
        'archive_timestamp': json['thread_metadata']['archive_timestamp'],
        'auto_archive_duration': json['thread_metadata']
            ['auto_archive_duration'],
        'locked': json['thread_metadata']['locked'],
      },
      'message_count': json['message_count'],
      'member_count': json['member_count'],
      'total_message_sent': json['total_message_sent'],
    };

    final cacheKey = marshaller.cacheKey.channel(json['id'] as String);
    await marshaller.cache?.put(cacheKey, payload);

    return payload;
  }

  @override
  Future<PublicThreadChannel> serialize(MarshallerContract marshaller,
      EntityContext ctx, Map<String, dynamic> json) async {
    final properties =
        await ChannelProperties.serializeCache(marshaller, ctx, json);
    final metadata = ThreadMetadata.fromMap(json);

    return PublicThreadChannel(properties, metadata);
  }

  @override
  Future<Map<String, dynamic>> deserialize(
      MarshallerContract marshaller, PublicThreadChannel channel) async {
    return {
      'id': channel.id.value,
      'type': channel.type.value,
      'last_message_id': channel.lastMessageId?.value,
      'flags': channel.flags,
      'server_id': channel.serverId?.value,
      'name': channel.name,
      'parent_id': channel.parentId?.value,
      'rate_limit_per_user': channel.rateLimitPerUser,
      'bitrate': channel.bitrate,
      'user_limit': channel.userLimit,
      'rtc_region': channel.rtcRegion,
      'owner_id': channel.ownerId.value,
      'thread_metadata': {
        'archived': channel.metadata.archived,
        'archive_timestamp':
            channel.metadata.archiveTimestamp?.toIso8601String(),
        'auto_archive_duration': channel.metadata.autoArchiveDuration,
        'locked': channel.metadata.locked,
      },
      'message_count': channel.messageCount,
      'member_count': channel.memberCount,
      'total_message_sent': channel.totalMessageSent,
    };
  }
}
