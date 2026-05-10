import 'package:mineral/src/api/common/channel_methods.dart';
import 'package:mineral/src/api/common/channel_properties.dart';
import 'package:mineral/src/api/server/channels/server_category_channel.dart';
import 'package:mineral/src/api/server/channels/server_channel.dart';
import 'package:mineral/src/api/server/enums/forum_layout_types.dart';
import 'package:mineral/src/api/server/enums/sort_order_forum.dart';
import 'package:mineral/src/api/server/managers/threads_manager.dart';

final class ServerForumChannel extends ServerChannel {
  @override
  final ChannelProperties properties;

  @override
  late final ChannelMethods methods;

  String? get description => properties.description;

  ThreadsManager get threads => properties.threads;

  final SortOrderType? sortOrder;

  final ForumLayoutType? layoutType;

  late final ServerCategoryChannel? category;

  ServerForumChannel(this.properties,
      {required this.sortOrder, required this.layoutType}) {
    methods = ChannelMethods(properties.serverId!, properties.id,
        ctx: properties.ctx);
  }
}
