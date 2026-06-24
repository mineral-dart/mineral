import 'package:mineral/src/api/common/channel_methods.dart';
import 'package:mineral/src/api/common/channel_properties.dart';
import 'package:mineral/src/api/guild/channels/guild_category_channel.dart';
import 'package:mineral/src/api/guild/channels/guild_channel.dart';
import 'package:mineral/src/api/guild/enums/forum_layout_types.dart';
import 'package:mineral/src/api/guild/enums/sort_order_forum.dart';
import 'package:mineral/src/api/guild/managers/threads_manager.dart';

final class GuildForumChannel extends GuildChannel {
  @override
  final ChannelProperties properties;

  @override
  late final ChannelMethods methods;

  String? get description => properties.description;

  ThreadsManager get threads => properties.threads;

  final SortOrderType? sortOrder;

  final ForumLayoutType? layoutType;

  late final GuildCategoryChannel? category;

  GuildForumChannel(
    this.properties, {
    required this.sortOrder,
    required this.layoutType,
  }) {
    methods = ChannelMethods(
      properties.guildId!,
      properties.id,
      ctx: properties.ctx,
    );
  }
}
