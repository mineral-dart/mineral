import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/base_part.dart';

final class ApplicationEmojiPart extends BasePart
    implements ApplicationEmojiPartContract {
  ApplicationEmojiPart(super.marshaller, super.dataStore);

  /// Builds a normalized payload suitable for [EmojiSerializer.serialize]
  /// from a raw Discord application-emoji payload (which has no [guild_id]).
  ///
  /// We use [applicationId] as the [server_id] so the resulting [Emoji] has a
  /// non-null [serverId] field, and we skip the cache-write path that
  /// [EmojiSerializer.normalize] would do (no caching for app emojis).
  Map<String, dynamic> _normalizePayload(
      Map<String, dynamic> raw, String applicationId) {
    return {
      'id': raw['id'],
      'name': raw['name'],
      'managed': raw['managed'] ?? false,
      'available': raw['available'] ?? true,
      'animated': raw['animated'] ?? false,
      'roles': <String>[],
      'server_id': applicationId,
    };
  }

  Future<Emoji> _buildEmoji(
      Map<String, dynamic> raw, String applicationId) async {
    final normalized = _normalizePayload(raw, applicationId);
    return marshaller.serializers.emojis.serialize(normalized);
  }

  @override
  Future<Map<Snowflake, Emoji>> fetch(Object applicationId) async {
    final appId = Snowflake.parse(applicationId);
    final req =
        Request.json(endpoint: '/applications/$appId/emojis');
    final result =
        await dataStore.requestBucket.get<Map<String, dynamic>>(req);

    // Discord wraps application emojis in { "items": [...] }
    final items =
        (result['items'] as List<dynamic>).cast<Map<String, dynamic>>();

    final emojis = await items.map((element) async {
      return _buildEmoji(element, appId.value);
    }).wait;

    return emojis.asMap().map((_, value) => MapEntry(value.id!, value));
  }

  @override
  Future<Emoji?> get(Object applicationId, Object emojiId) async {
    final appId = Snowflake.parse(applicationId);
    final req =
        Request.json(endpoint: '/applications/$appId/emojis/$emojiId');
    final result =
        await dataStore.requestBucket.get<Map<String, dynamic>>(req);

    return _buildEmoji(result, appId.value);
  }

  @override
  Future<Emoji> create(
      Object applicationId, String name, Image image) async {
    final appId = Snowflake.parse(applicationId);
    final req = Request.json(
      endpoint: '/applications/$appId/emojis',
      body: {
        'name': name.replaceAll(' ', '_'),
        'image': image.base64,
      },
    );
    final result =
        await dataStore.requestBucket.post<Map<String, dynamic>>(req);

    return _buildEmoji(result, appId.value);
  }

  @override
  Future<Emoji?> update(
      Object applicationId, Object emojiId, String name) async {
    final appId = Snowflake.parse(applicationId);
    final req = Request.json(
      endpoint: '/applications/$appId/emojis/$emojiId',
      body: {'name': name.replaceAll(' ', '_')},
    );
    final result =
        await dataStore.requestBucket.patch<Map<String, dynamic>>(req);

    return _buildEmoji(result, appId.value);
  }

  @override
  Future<void> delete(Object applicationId, Object emojiId) async {
    final appId = Snowflake.parse(applicationId);
    final req = Request.json(
        endpoint: '/applications/$appId/emojis/$emojiId');
    await dataStore.requestBucket.delete<Map<String, dynamic>>(req);
  }
}
