import 'package:mineral/contracts.dart';
import 'package:mineral/src/api/common/channel_permission_overwrite.dart';
import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/api/common/types/channel_type.dart';
import 'package:mineral/src/api/guild/managers/threads_manager.dart';
import 'package:mineral/src/api/private/user.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/common/utils/helper.dart';
import 'package:mineral/src/domains/common/utils/utils.dart';

final class ChannelProperties {
  final EntityContext _ctx;

  /// Exposed so channel subclasses can construct sub-managers
  /// ([ChannelMethods], [MessageManager]) without re-injecting the context.
  EntityContext get ctx => _ctx;

  ChannelPartContract get dataStoreChannel => _ctx.datastore.channel;

  final Snowflake id;
  final ChannelType type;
  final String? name;
  final String? description;
  final Snowflake? guildId;
  final Snowflake? categoryId;
  final int? position;
  final bool nsfw;
  final Snowflake? lastMessageId;
  final int? bitrate;
  final int? userLimit;
  final int? rateLimitPerUser;
  final List<User> recipients;
  final String? icon;
  final String? ownerId;
  final String? applicationId;
  final String? lastPinTimestamp;
  final String? rtcRegion;
  final int? videoQualityMode;
  final int? messageCount;
  final int? memberCount;
  final int? defaultAutoArchiveDuration;
  final List<ChannelPermissionOverwrite> permissions;
  final int? flags;
  final int? totalMessageSent;
  final dynamic available;
  final List<Snowflake> appliedTags;
  final dynamic defaultReactions;
  final int? defaultSortOrder;
  final int? defaultForumLayout;
  final ThreadsManager threads;

  ChannelProperties({
    required EntityContext ctx,
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.guildId,
    required this.categoryId,
    required this.position,
    required this.nsfw,
    required this.lastMessageId,
    required this.bitrate,
    required this.userLimit,
    required this.rateLimitPerUser,
    required this.recipients,
    required this.icon,
    required this.ownerId,
    required this.applicationId,
    required this.lastPinTimestamp,
    required this.rtcRegion,
    required this.videoQualityMode,
    required this.messageCount,
    required this.memberCount,
    required this.defaultAutoArchiveDuration,
    required this.permissions,
    required this.flags,
    required this.totalMessageSent,
    required this.available,
    required this.appliedTags,
    required this.defaultReactions,
    required this.defaultSortOrder,
    required this.defaultForumLayout,
    required this.threads,
  }) : _ctx = ctx;

  static Future<ChannelProperties> serializeCache(
    MarshallerContract marshaller,
    EntityContext ctx,
    Map<String, dynamic> element,
  ) async {
    final permissionOverwrites = await Helper.createOrNullAsync(
      field: element['permission_overwrites'],
      fn: () async => Future.wait(
        List.from(element['permission_overwrites'] as Iterable<dynamic>)
            .map(
              (json) async => marshaller.serializers.channelPermissionOverwrite
                  .serialize(json as Map<String, dynamic>),
            )
            .toList(),
      ),
    );

    final recipients = await Helper.createOrNullAsync(
      field: element['recipients'],
      fn: () async => Future.wait(
        List.from(element['recipients'] as Iterable<dynamic>).map((json) async {
          final raw = await marshaller.serializers.user.normalize(
            json as Map<String, dynamic>,
          );
          return marshaller.serializers.user.serialize(raw);
        }).toList(),
      ),
    );

    return ChannelProperties(
      ctx: ctx,
      id: Snowflake.parse(element['id'] as String),
      type: findInEnum(
        ChannelType.values,
        element['type'],
        orElse: ChannelType.unknown,
      ),
      name: element['name'] as String?,
      description: element['description'] as String?,
      guildId: Snowflake.nullable(element['guild_id'] as String?),
      categoryId: Snowflake.nullable(element['parent_id'] as String?),
      position: element['position'] as int?,
      nsfw: element['nsfw'] as bool? ?? false,
      lastMessageId: Snowflake.nullable(element['last_message_id'] as String?),
      bitrate: element['bitrate'] as int?,
      userLimit: element['user_limit'] as int?,
      rateLimitPerUser: element['rate_limit_per_user'] as int?,
      recipients: List.unmodifiable(recipients ?? []),
      icon: element['icon'] as String?,
      ownerId: element['owner_id'] as String?,
      applicationId: element['application_id'] as String?,
      lastPinTimestamp: element['last_pin_timestamp'] as String?,
      rtcRegion: element['rtc_region'] as String?,
      videoQualityMode: element['video_quality_mode'] as int?,
      messageCount: element['message_count'] as int?,
      memberCount: element['member_count'] as int?,
      defaultAutoArchiveDuration:
          element['default_auto_archive_duration'] as int?,
      permissions: List.unmodifiable(permissionOverwrites ?? []),
      flags: element['flags'] as int?,
      totalMessageSent: element['total_message_sent'] as int?,
      available: element['available'],
      appliedTags: List.unmodifiable(
        element['applied_tags'] as List<Snowflake>? ?? [],
      ),
      defaultReactions: element['default_reactions'],
      defaultSortOrder: element['default_sort_order'] as int?,
      defaultForumLayout: element['default_forum_layout'] as int?,
      threads: ThreadsManager(
        Snowflake.nullable(element['guild_id'] as String?),
        Snowflake.nullable(element['id'] as String?),
        ctx: ctx,
      ),
    );
  }
}
