import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/base_part.dart';
import 'package:mineral/src/infrastructure/internals/http/discord_header.dart';

final class SoundboardPart extends BasePart implements SoundboardPartContract {
  SoundboardPart(super.marshaller, super.dataStore);

  @override
  Future<List<SoundboardSound>> fetchDefault() async {
    final req = Request.json(endpoint: '/soundboard-default-sounds');
    final result =
        await dataStore.requestBucket.get<List<Map<String, dynamic>>>(req);
    return result.map(SoundboardSound.fromJson).toList();
  }

  @override
  Future<Map<Snowflake, SoundboardSound>> fetchForServer(
      Object serverId) async {
    final guildId = Snowflake.parse(serverId);
    final req =
        Request.json(endpoint: '/guilds/$guildId/soundboard-sounds');
    final result =
        await dataStore.requestBucket.get<Map<String, dynamic>>(req);

    final items =
        (result['items'] as List<dynamic>).cast<Map<String, dynamic>>();
    final sounds = items.map(SoundboardSound.fromJson).toList();
    return {for (final s in sounds) s.soundId: s};
  }

  @override
  Future<SoundboardSound> get(Object serverId, Object soundId) async {
    final guildId = Snowflake.parse(serverId);
    final id = Snowflake.parse(soundId);
    final req =
        Request.json(endpoint: '/guilds/$guildId/soundboard-sounds/$id');
    final result =
        await dataStore.requestBucket.get<Map<String, dynamic>>(req);
    return SoundboardSound.fromJson(result);
  }

  @override
  Future<SoundboardSound> create(
    Object serverId, {
    required String name,
    required String sound,
    double? volume,
    Object? emojiId,
    String? emojiName,
    String? reason,
  }) async {
    final guildId = Snowflake.parse(serverId);
    final body = <String, dynamic>{
      'name': name,
      'sound': sound,
      if (volume != null) 'volume': volume,
      if (emojiId != null) 'emoji_id': Snowflake.parse(emojiId).value,
      if (emojiName != null) 'emoji_name': emojiName,
    };

    final req = Request.json(
      endpoint: '/guilds/$guildId/soundboard-sounds',
      body: body,
      headers: {DiscordHeader.auditLogReason(reason)},
    );
    final result =
        await dataStore.requestBucket.post<Map<String, dynamic>>(req);
    return SoundboardSound.fromJson(result);
  }

  @override
  Future<SoundboardSound> update(
    Object serverId,
    Object soundId, {
    String? name,
    double? volume,
    Object? emojiId,
    String? emojiName,
    String? reason,
  }) async {
    final guildId = Snowflake.parse(serverId);
    final id = Snowflake.parse(soundId);
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (volume != null) 'volume': volume,
      if (emojiId != null) 'emoji_id': Snowflake.parse(emojiId).value,
      if (emojiName != null) 'emoji_name': emojiName,
    };

    final req = Request.json(
      endpoint: '/guilds/$guildId/soundboard-sounds/$id',
      body: body,
      headers: {DiscordHeader.auditLogReason(reason)},
    );
    final result =
        await dataStore.requestBucket.patch<Map<String, dynamic>>(req);
    return SoundboardSound.fromJson(result);
  }

  @override
  Future<void> delete(
    Object serverId,
    Object soundId, {
    String? reason,
  }) async {
    final guildId = Snowflake.parse(serverId);
    final id = Snowflake.parse(soundId);
    final req = Request.json(
      endpoint: '/guilds/$guildId/soundboard-sounds/$id',
      headers: {DiscordHeader.auditLogReason(reason)},
    );
    await dataStore.requestBucket.delete<void>(req);
  }

  @override
  Future<void> sendToChannel(
    Object channelId, {
    required Object soundId,
    Object? sourceGuildId,
  }) async {
    final id = Snowflake.parse(channelId);
    final body = <String, dynamic>{
      'sound_id': Snowflake.parse(soundId).value,
      if (sourceGuildId != null)
        'source_guild_id': Snowflake.parse(sourceGuildId).value,
    };

    final req = Request.json(
      endpoint: '/channels/$id/send-soundboard-sound',
      body: body,
    );
    await dataStore.requestBucket.post<void>(req);
  }
}
