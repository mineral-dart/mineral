import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/api/server/member.dart';
import 'package:mineral/src/api/server/voice_state.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/base_part.dart';
import 'package:mineral/src/infrastructure/internals/http/discord_header.dart';

final class MemberPart extends BasePart implements MemberPartContract {
  MemberPart(super.marshaller, super.dataStore);

  @override
  Future<Map<Snowflake, Member>> fetch(Object serverId, bool force) async {
    final guildId = Snowflake.parse(serverId);
    final req = Request.json(endpoint: '/guilds/$guildId/members');
    final result = await dataStore.requestBucket.get<List<Map<String, dynamic>>>(req);

    final members = await result.map((element) async {
      final raw = await marshaller.serializers.member
          .normalize({...element, 'guild_id': guildId});
      return marshaller.serializers.member.serialize(raw);
    }).wait;

    return members.asMap().map((_, value) => MapEntry(value.id, value));
  }

  @override
  Future<Member?> get(Object serverId, Object id, bool force) async {
    final guildId = Snowflake.parse(serverId);
    final memberId = Snowflake.parse(id);
    final String key = marshaller.cacheKey.member(guildId.value, memberId.value);

    final cachedMember = await marshaller.cache?.get(key);
    if (!force && cachedMember != null) {
      final member =
          await marshaller.serializers.member.serialize(cachedMember);

      return member;
    }

    final req = Request.json(endpoint: '/guilds/$guildId/members/$memberId');
    final result = await dataStore.requestBucket.get<Map<String, dynamic>>(req);

    final raw = await marshaller.serializers.member
        .normalize({...result, 'guild_id': guildId});
    final member = await marshaller.serializers.member.serialize(raw);

    return member;
  }

  @override
  Future<Member> update(
      {required Object serverId,
      required Object memberId,
      required Map<String, dynamic> payload,
      String? reason}) async {
    final guildId = Snowflake.parse(serverId);
    final userId = Snowflake.parse(memberId);
    final req = Request.json(
        endpoint: '/guilds/$guildId/members/$userId',
        body: payload,
        headers: {DiscordHeader.auditLogReason(reason)});
    final result = await dataStore.requestBucket.patch<Map<String, dynamic>>(req);

    final raw = await marshaller.serializers.member.normalize({
      ...result,
      'guild_id': guildId,
    });
    final member = await marshaller.serializers.member.serialize(raw);

    return member;
  }

  @override
  Future<void> ban(
      {required Object serverId,
      required Duration? deleteSince,
      required Object memberId,
      String? reason}) async {
    final guildId = Snowflake.parse(serverId);
    final userId = Snowflake.parse(memberId);
    final req = Request.json(
        endpoint: '/guilds/$guildId/bans/$userId',
        body: {'delete_message_seconds': deleteSince?.inSeconds},
        headers: {DiscordHeader.auditLogReason(reason)});

    await dataStore.requestBucket.put<Map<String, dynamic>>(req);
  }

  @override
  Future<void> kick(
      {required Object serverId,
      required Object memberId,
      String? reason}) async {
    final guildId = Snowflake.parse(serverId);
    final userId = Snowflake.parse(memberId);
    final req = Request.json(
        endpoint: '/guilds/$guildId/members/$userId',
        headers: {DiscordHeader.auditLogReason(reason)});

    await dataStore.requestBucket.delete<Map<String, dynamic>>(req);
  }

  @override
  Future<VoiceState?> getVoiceState(
      Object serverId, Object userId, bool force) async {
    final guildId = Snowflake.parse(serverId);
    final String key = marshaller.cacheKey.voiceState(guildId.value, userId);

    final cachedMember = await marshaller.cache?.get(key);
    if (!force && cachedMember != null) {
      final voiceState =
          await marshaller.serializers.voice.serialize(cachedMember);

      return voiceState;
    }

    final req =
        Request.json(endpoint: '/guilds/$guildId/voice-states/$userId');
    final result = await dataStore.requestBucket.get<Map<String, dynamic>>(req);

    final raw = await marshaller.serializers.voice.normalize(result);
    final voice = await marshaller.serializers.voice.serialize(raw);

    return voice;
  }
}
