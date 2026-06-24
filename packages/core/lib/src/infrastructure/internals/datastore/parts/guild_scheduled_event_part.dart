import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/base_part.dart';
import 'package:mineral/src/infrastructure/internals/http/discord_header.dart';

final class GuildScheduledEventPart extends BasePart
    implements GuildScheduledEventPartContract {
  GuildScheduledEventPart(super.marshaller, super.dataStore);

  @override
  Future<Map<Snowflake, GuildScheduledEvent>> fetchForServer(
    Object guildId, {
    bool? withUserCount,
  }) async {
    final req = Request.json(
      endpoint: '/guilds/$guildId/scheduled-events',
      queryParameters: {
        if (withUserCount != null) 'with_user_count': withUserCount.toString(),
      },
    );

    final result =
        await dataStore.requestBucket.get<List<Map<String, dynamic>>>(req);

    final events = await result.map((json) async {
      final raw = await marshaller.serializers.scheduledEvent.normalize(json);
      return marshaller.serializers.scheduledEvent.serialize(raw);
    }).wait;

    return {for (final e in events) e.id: e};
  }

  @override
  Future<GuildScheduledEvent?> get(
    Object guildId,
    Object id,
    bool force, {
    bool? withUserCount,
  }) async {
    final cacheKey = marshaller.cacheKey.scheduledEvent(guildId, id);

    final cached = await marshaller.cache?.get(cacheKey);
    if (!force && cached != null) {
      return marshaller.serializers.scheduledEvent.serialize(cached);
    }

    final req = Request.json(
      endpoint: '/guilds/$guildId/scheduled-events/$id',
      queryParameters: {
        if (withUserCount != null) 'with_user_count': withUserCount.toString(),
      },
    );

    final result = await dataStore.requestBucket.get<Map<String, dynamic>>(req);

    final raw = await marshaller.serializers.scheduledEvent.normalize(result);
    return marshaller.serializers.scheduledEvent.serialize(raw);
  }

  @override
  Future<GuildScheduledEvent> create({
    required Object guildId,
    required String name,
    required GuildScheduledEventPrivacyLevel privacyLevel,
    required DateTime scheduledStartTime,
    required GuildScheduledEventEntityType entityType,
    Object? channelId,
    GuildScheduledEventEntityMetadata? entityMetadata,
    DateTime? scheduledEndTime,
    String? description,
    String? image,
    String? reason,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'privacy_level': privacyLevel.value,
      'scheduled_start_time': scheduledStartTime.toIso8601String(),
      'entity_type': entityType.value,
      if (channelId != null) 'channel_id': channelId.toString(),
      if (entityMetadata != null) 'entity_metadata': entityMetadata.toJson(),
      if (scheduledEndTime != null)
        'scheduled_end_time': scheduledEndTime.toIso8601String(),
      if (description != null) 'description': description,
      if (image != null) 'image': image,
    };

    final req = Request.json(
      endpoint: '/guilds/$guildId/scheduled-events',
      body: body,
      headers: {DiscordHeader.auditLogReason(reason)},
    );

    final result =
        await dataStore.requestBucket.post<Map<String, dynamic>>(req);

    final raw = await marshaller.serializers.scheduledEvent.normalize(result);
    return marshaller.serializers.scheduledEvent.serialize(raw);
  }

  @override
  Future<GuildScheduledEvent?> update({
    required Object guildId,
    required Object id,
    Object? channelId,
    GuildScheduledEventEntityMetadata? entityMetadata,
    String? name,
    GuildScheduledEventPrivacyLevel? privacyLevel,
    DateTime? scheduledStartTime,
    DateTime? scheduledEndTime,
    String? description,
    GuildScheduledEventEntityType? entityType,
    GuildScheduledEventStatus? status,
    String? image,
    String? reason,
  }) async {
    final body = <String, dynamic>{
      if (channelId != null) 'channel_id': channelId.toString(),
      if (entityMetadata != null) 'entity_metadata': entityMetadata.toJson(),
      if (name != null) 'name': name,
      if (privacyLevel != null) 'privacy_level': privacyLevel.value,
      if (scheduledStartTime != null)
        'scheduled_start_time': scheduledStartTime.toIso8601String(),
      if (scheduledEndTime != null)
        'scheduled_end_time': scheduledEndTime.toIso8601String(),
      if (description != null) 'description': description,
      if (entityType != null) 'entity_type': entityType.value,
      if (status != null) 'status': status.value,
      if (image != null) 'image': image,
    };

    final req = Request.json(
      endpoint: '/guilds/$guildId/scheduled-events/$id',
      body: body,
      headers: {DiscordHeader.auditLogReason(reason)},
    );

    final result =
        await dataStore.requestBucket.patch<Map<String, dynamic>>(req);

    final raw = await marshaller.serializers.scheduledEvent.normalize(result);
    return marshaller.serializers.scheduledEvent.serialize(raw);
  }

  @override
  Future<void> delete({
    required Object guildId,
    required Object id,
    String? reason,
  }) async {
    final req = Request.json(
      endpoint: '/guilds/$guildId/scheduled-events/$id',
      headers: {DiscordHeader.auditLogReason(reason)},
    );
    await dataStore.requestBucket.delete<Map<String, dynamic>>(req);
  }

  @override
  Future<List<GuildScheduledEventUser>> fetchUsers({
    required Object guildId,
    required Object id,
    int? limit,
    bool? withMember,
    Object? before,
    Object? after,
  }) async {
    final req = Request.json(
      endpoint: '/guilds/$guildId/scheduled-events/$id/users',
      queryParameters: {
        if (limit != null) 'limit': limit.toString(),
        if (withMember != null) 'with_member': withMember.toString(),
        if (before != null) 'before': before.toString(),
        if (after != null) 'after': after.toString(),
      },
    );

    final result =
        await dataStore.requestBucket.get<List<Map<String, dynamic>>>(req);

    return result
        .map((json) => GuildScheduledEventUser(
              eventId: Snowflake.parse(json['guild_scheduled_event_id']),
              userId: Snowflake.parse(
                  (json['user'] as Map<String, dynamic>)['id']),
              memberId: json['member'] != null
                  ? Snowflake.parse(
                      ((json['member'] as Map<String, dynamic>)['user']
                              as Map<String, dynamic>)['id'])
                  : null,
            ))
        .toList();
  }
}
