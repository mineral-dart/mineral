import 'package:uuid/uuid.dart';

final class CacheKey {
  String guild(Object id) => 'guild/$id';

  String guildAssets(Object guildId, {bool ref = false}) {
    final key = '${guild(guildId)}/assets';
    return ref ? 'ref:$key' : key;
  }

  String guildSettings(String guildId, {bool ref = false}) {
    final key = '${guild(guildId)}/settings';
    return ref ? 'ref:$key' : key;
  }

  String guildRules(Object guildId, Object ruleId, {bool ref = false}) {
    final key = '${guild(guildId)}/rules/$ruleId';
    return ref ? 'ref:$key' : key;
  }

  String guildSubscription(String guildId, {bool ref = false}) {
    final key = '${guild(guildId)}/subscriptions';
    return ref ? 'ref:$key' : key;
  }

  String channel(Object channelId) => 'channels/$channelId';

  String channelPermission(Object channelId, {Object? guildId}) =>
      '${channel(channelId)}/permissions';

  String guildRole(Object guildId, Object roleId) =>
      '${guild(guildId)}/roles/$roleId';

  String member(Object guildId, Object memberId, {bool ref = false}) {
    final key = '${guild(guildId)}/members/$memberId';
    return ref ? 'ref:$key' : key;
  }

  String memberAssets(Object guildId, Object memberId, {bool ref = false}) {
    final key = '${member(guildId, memberId)}/assets';
    return ref ? 'ref:$key' : key;
  }

  String user(Object userId, {bool ref = false}) {
    final key = 'users/$userId';
    return ref ? 'ref:$key' : key;
  }

  String voiceState(Object guildId, Object userId) =>
      'voice_states/${member(guildId, userId)}';

  String invite(String code) => 'invites/$code';

  String userAssets(Object userId, {bool ref = false}) {
    final key = '${user(userId)}/assets';
    return ref ? 'ref:$key' : key;
  }

  String guildEmoji(Object guildId, Object emojiId) =>
      '${guild(guildId)}/emojis/$emojiId';

  String message(Object channelId, Object messageId) =>
      '${channel(channelId)}/messages/$messageId';

  String embed(Object messageId, {Object? uid}) =>
      'messages/$messageId/embeds/${uid ?? Uuid().v4()}';

  String poll(Object messageId, {Object? uid}) =>
      'messages/$messageId/polls/${uid ?? Uuid().v4()}';

  String sticker(Object guildId, Object stickerId) =>
      '${guild(guildId)}/stickers/$stickerId';

  String thread(Object threadId) => 'threads/$threadId';

  String webhook(Object webhookId) => 'webhooks/$webhookId';

  String scheduledEvent(Object guildId, Object eventId) =>
      '${guild(guildId)}/scheduled-events/$eventId';
}
