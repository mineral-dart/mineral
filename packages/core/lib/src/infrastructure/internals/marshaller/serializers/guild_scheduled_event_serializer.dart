import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/api/guild/guild_scheduled_event.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/services/marshaller/marshaller.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/types/serializer.dart';

final class GuildScheduledEventSerializer
    implements SerializerContract<GuildScheduledEvent> {
  final MarshallerContract _marshaller;
  final EntityContext _ctx;

  GuildScheduledEventSerializer(this._marshaller, this._ctx);

  @override
  Future<Map<String, dynamic>> normalize(Map<String, dynamic> json) async {
    final creator = json['creator'] as Map<String, dynamic>?;
    final entityMetadata = json['entity_metadata'] as Map<String, dynamic>?;

    final payload = {
      'id': json['id'],
      'guild_id': json['guild_id'],
      'channel_id': json['channel_id'],
      'creator_id': json['creator_id'] ?? creator?['id'],
      'name': json['name'],
      'description': json['description'],
      'scheduled_start_time': json['scheduled_start_time'],
      'scheduled_end_time': json['scheduled_end_time'],
      'privacy_level': json['privacy_level'],
      'status': json['status'],
      'entity_type': json['entity_type'],
      'entity_id': json['entity_id'],
      'entity_metadata': entityMetadata != null
          ? {'location': entityMetadata['location']}
          : null,
      'user_count': json['user_count'],
      'image': json['image'],
    };

    final cacheKey = _marshaller.cacheKey
        .scheduledEvent(json['guild_id'] as String, json['id'] as String);
    await _marshaller.cache?.put(cacheKey, payload);

    return payload;
  }

  @override
  Future<GuildScheduledEvent> serialize(Map<String, dynamic> json) async {
    final entityMetadata = json['entity_metadata'] as Map<String, dynamic>?;

    return GuildScheduledEvent(
      ctx: _ctx,
      id: Snowflake.parse(json['id']),
      guildId: Snowflake.parse(json['guild_id']),
      channelId: json['channel_id'] != null
          ? Snowflake.parse(json['channel_id'])
          : null,
      creatorId: json['creator_id'] != null
          ? Snowflake.parse(json['creator_id'])
          : null,
      name: json['name'] as String,
      description: json['description'] as String?,
      scheduledStartTime: DateTime.parse(json['scheduled_start_time'] as String),
      scheduledEndTime: json['scheduled_end_time'] != null
          ? DateTime.parse(json['scheduled_end_time'] as String)
          : null,
      privacyLevel:
          GuildScheduledEventPrivacyLevel.of(json['privacy_level'] as int),
      status: GuildScheduledEventStatus.of(json['status'] as int),
      entityType:
          GuildScheduledEventEntityType.of(json['entity_type'] as int),
      entityId: json['entity_id'] != null
          ? Snowflake.parse(json['entity_id'])
          : null,
      entityMetadata: entityMetadata != null
          ? GuildScheduledEventEntityMetadata(
              location: entityMetadata['location'] as String?)
          : null,
      userCount: json['user_count'] as int?,
      image: json['image'] as String?,
    );
  }

  @override
  Map<String, dynamic> deserialize(GuildScheduledEvent event) {
    return {
      'id': event.id.value,
      'guild_id': event.guildId.value,
      'channel_id': event.channelId?.value,
      'creator_id': event.creatorId?.value,
      'name': event.name,
      'description': event.description,
      'scheduled_start_time': event.scheduledStartTime.toIso8601String(),
      'scheduled_end_time': event.scheduledEndTime?.toIso8601String(),
      'privacy_level': event.privacyLevel.value,
      'status': event.status.value,
      'entity_type': event.entityType.value,
      'entity_id': event.entityId?.value,
      'entity_metadata': event.entityMetadata != null
          ? {'location': event.entityMetadata!.location}
          : null,
      'user_count': event.userCount,
      'image': event.image,
    };
  }
}
