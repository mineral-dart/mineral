import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/base_part.dart';
import 'package:mineral/src/infrastructure/internals/http/discord_header.dart';

final class StageInstancePart extends BasePart
    implements StageInstancePartContract {
  StageInstancePart(super.marshaller, super.dataStore);

  @override
  Future<StageInstance> get(Object channelId) async {
    final id = Snowflake.parse(channelId);
    final req = Request.json(endpoint: '/stage-instances/$id');
    final result = await dataStore.requestBucket.get<Map<String, dynamic>>(req);
    return StageInstance.fromJson(result);
  }

  @override
  Future<StageInstance> create({
    required Object channelId,
    required String topic,
    StagePrivacyLevel? privacyLevel,
    bool? sendStartNotification,
    Object? guildScheduledEventId,
    String? reason,
  }) async {
    final body = <String, dynamic>{
      'channel_id': Snowflake.parse(channelId).value,
      'topic': topic,
      if (privacyLevel != null) 'privacy_level': privacyLevel.value,
      if (sendStartNotification != null)
        'send_start_notification': sendStartNotification,
      if (guildScheduledEventId != null)
        'guild_scheduled_event_id': Snowflake.parse(
          guildScheduledEventId,
        ).value,
    };

    final req = Request.json(
      endpoint: '/stage-instances',
      body: body,
      headers: {DiscordHeader.auditLogReason(reason)},
    );
    final result = await dataStore.requestBucket.post<Map<String, dynamic>>(
      req,
    );
    return StageInstance.fromJson(result);
  }

  @override
  Future<StageInstance> update({
    required Object channelId,
    String? topic,
    StagePrivacyLevel? privacyLevel,
    String? reason,
  }) async {
    final id = Snowflake.parse(channelId);

    final body = <String, dynamic>{
      if (topic != null) 'topic': topic,
      if (privacyLevel != null) 'privacy_level': privacyLevel.value,
    };

    final req = Request.json(
      endpoint: '/stage-instances/$id',
      body: body,
      headers: {DiscordHeader.auditLogReason(reason)},
    );
    final result = await dataStore.requestBucket.patch<Map<String, dynamic>>(
      req,
    );
    return StageInstance.fromJson(result);
  }

  @override
  Future<void> delete({required Object channelId, String? reason}) async {
    final id = Snowflake.parse(channelId);
    final req = Request.json(
      endpoint: '/stage-instances/$id',
      headers: {DiscordHeader.auditLogReason(reason)},
    );
    await dataStore.requestBucket.delete<void>(req);
  }
}
