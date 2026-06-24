import 'package:mineral/api.dart';
import 'package:mineral/src/domains/common/utils/utils.dart';

abstract class ChannelBuilderContract {
  void setName(String value);

  void setPosition(int value);

  void setPermissionOverwrite(List<ChannelPermissionOverwrite> value);

  void addPermissionOverwrite(ChannelPermissionOverwrite value);

  Map<String, dynamic> build();
}

abstract interface class TextChannelBuilder extends ChannelBuilderContract {
  void setTopic(String value);

  void setRateLimitPerUser(Duration value);

  void setParentId(String value);

  void setNsfw(bool value);

  void setDefaultAutoArchiveDuration(Duration value);

  void setDefaultThreadRateLimitPerUser(Duration value);
}

abstract interface class ForumChannelBuilder extends ChannelBuilderContract {
  void setTopic(String value);

  void setRateLimitPerUser(Duration value);

  void setParentId(String value);

  void setNsfw(bool value);

  void setDefaultAutoArchiveDuration(Duration value);

  void setDefaultReactionEmoji(PartialEmoji value);

  void setDefaultSortOrder(int value);

  void setDefaultForumLayout(int value);

  void setDefaultThreadRateLimitPerUser(Duration value);
}

abstract interface class AnnouncementChannelBuilder
    extends ChannelBuilderContract {
  void setTopic(String value);

  void setParentId(String value);

  void setNsfw(bool value);

  void setDefaultAutoArchiveDuration(Duration value);

  void setDefaultThreadRateLimitPerUser(Duration value);
}

abstract interface class VoiceChannelBuilder extends ChannelBuilderContract {
  void setBitrate(int value);

  void setUserLimit(int value);

  void setParentId(String value);

  void setNsfw(bool value);

  void setRtcRegion(String value);

  void setVideoQualityMode(VideoQuality value);
}

abstract interface class ThreadChannelBuilder extends ChannelBuilderContract {
  void setDefaultAutoArchiveDuration(Duration value);

  void setDefaultThreadRateLimitPerUser(Duration value);
}

abstract interface class CategoryChannelBuilder
    extends ChannelBuilderContract {}

final class ChannelBuilder
    implements
        TextChannelBuilder,
        AnnouncementChannelBuilder,
        VoiceChannelBuilder,
        ForumChannelBuilder,
        CategoryChannelBuilder,
        ThreadChannelBuilder {
  final ChannelType? _type;
  String? _name;
  String? _topic;
  int? _position;
  int? _bitrate;
  int? _userLimit;
  Duration? _rateLimitPerUser;
  final List<ChannelPermissionOverwrite> _permissionOverwrites = [];
  String? _parentId;
  bool? _nsfw;
  String? _rtcRegion;
  VideoQuality? _videoQualityMode;
  Duration? _defaultAutoArchiveDuration;
  int? _defaultForumLayout;
  PartialEmoji? _defaultReactionEmoji;
  int? _defaultSortOrder;
  Duration? _defaultThreadRateLimitPerUser;

  ChannelBuilder(this._type);

  @override
  void setName(String value) => _name = value;

  @override
  void setTopic(String value) => _topic = value;

  @override
  void setPosition(int value) => _position = value;

  @override
  void setBitrate(int value) => _bitrate = value;

  @override
  void setUserLimit(int value) => _userLimit = value;

  @override
  void setRateLimitPerUser(Duration value) => _rateLimitPerUser = value;

  @override
  void addPermissionOverwrite(ChannelPermissionOverwrite value) =>
      _permissionOverwrites.add(value);

  @override
  void setPermissionOverwrite(List<ChannelPermissionOverwrite> value) =>
      _permissionOverwrites.addAll(value);

  @override
  void setParentId(String value) => _parentId = value;

  @override
  void setNsfw(bool value) => _nsfw = value;

  @override
  void setRtcRegion(String value) => _rtcRegion = value;

  @override
  void setVideoQualityMode(VideoQuality value) => _videoQualityMode = value;

  @override
  void setDefaultAutoArchiveDuration(Duration value) =>
      _defaultAutoArchiveDuration = value;

  @override
  void setDefaultReactionEmoji(PartialEmoji value) =>
      _defaultReactionEmoji = value;

  @override
  void setDefaultSortOrder(int value) => _defaultSortOrder = value;

  @override
  void setDefaultForumLayout(int value) => _defaultForumLayout = value;

  @override
  void setDefaultThreadRateLimitPerUser(Duration value) =>
      _defaultThreadRateLimitPerUser = value;

  /// Build text channel.
  /// ```dart
  /// final builder = ChannelBuilder.text()
  ///   ..setName('general')
  ///   ..setTopic('General discussion channel')
  ///   ..setRateLimitPerUser(Duration(seconds: 5));
  ///  ```
  static TextChannelBuilder text() => ChannelBuilder(ChannelType.guildText);

  /// Build announcement channel.
  /// ```dart
  /// final builder = ChannelBuilder.announcement()
  ///   ..setName('announcements')
  ///   ..setTopic('Announcement channel');
  /// ```
  static AnnouncementChannelBuilder announcement() =>
      ChannelBuilder(ChannelType.guildAnnouncement);

  /// Build voice channel.
  /// ```dart
  /// final builder = ChannelBuilder.voice()
  ///   ..setName('voice')
  ///   ..setBitrate(64000)
  ///   ..setUserLimit(10);
  /// ```
  static VoiceChannelBuilder voice() => ChannelBuilder(ChannelType.guildVoice);

  /// Build forum channel.
  /// ```dart
  /// final builder = ChannelBuilder.forum()
  ///   ..setName('forum')
  ///   ..setTopic('Forum channel')
  ///   ..setDefaultAutoArchiveDuration(Duration(minutes: 60));
  ///  ```
  static ForumChannelBuilder forum() => ChannelBuilder(ChannelType.guildForum);

  /// Build category channel.
  /// ```dart
  /// final builder = ChannelBuilder.category()
  ///   ..setName('category');
  ///  ```
  static CategoryChannelBuilder category() =>
      ChannelBuilder(ChannelType.guildCategory);

  /// Build category channel.
  /// ```dart
  /// final builder = ChannelBuilder.category()
  ///   ..setName('category');
  /// ```
  static ThreadChannelBuilder thread(ChannelType type) => ChannelBuilder(type);

  @override
  Map<String, dynamic> build() {
    return {
      if (_type != null) 'type': _type.value,
      if (_name != null) 'name': _name,
      if (_topic != null) 'topic': _topic,
      if (_position != null) 'position': _position,
      if (_bitrate != null) 'bitrate': _bitrate,
      if (_userLimit != null) 'user_limit': _userLimit,
      if (_rateLimitPerUser != null)
        'rate_limit_per_user': _rateLimitPerUser!.inSeconds,
      if (_permissionOverwrites.isNotEmpty)
        'permission_overwrites': _permissionOverwrites
            .map(
              (element) => {
                'id': element.id,
                'type': element.type.value,
                'allow': listToBitfield(element.allow),
                'deny': listToBitfield(element.deny),
              },
            )
            .toList(),
      if (_parentId != null) 'parent_id': _parentId,
      if (_nsfw != null) 'nsfw': _nsfw,
      if (_rtcRegion != null) 'rtc_region': _rtcRegion,
      if (_videoQualityMode != null)
        'video_quality_mode': _videoQualityMode?.value,
      if (_defaultAutoArchiveDuration != null)
        'default_auto_archive_duration': _defaultAutoArchiveDuration!.inMinutes,
      if (_defaultForumLayout != null)
        'default_forum_layout': _defaultForumLayout,
      if (_defaultReactionEmoji != null)
        'default_reaction_emoji': {
          'emoji_id': _defaultReactionEmoji?.id,
          'emoji_name': _defaultReactionEmoji?.name,
        },
      if (_defaultSortOrder != null) 'default_sort_order': _defaultSortOrder,
      if (_defaultThreadRateLimitPerUser != null)
        'default_thread_rate_limit_per_user':
            _defaultThreadRateLimitPerUser!.inSeconds,
    };
  }
}
