import 'package:mineral/src/api/common/channel_methods.dart';
import 'package:mineral/src/api/common/channel_properties.dart';
import 'package:mineral/src/api/guild/channels/guild_channel.dart';
import 'package:mineral/src/api/guild/managers/threads_manager.dart';

final class GuildCategoryChannel extends GuildChannel {
  @override
  final ChannelProperties properties;

  @override
  late final ChannelMethods methods;

  ThreadsManager get threads => properties.threads;

  GuildCategoryChannel(this.properties) {
    methods = ChannelMethods(
      properties.guildId!,
      properties.id,
      ctx: properties.ctx,
    );
  }
}
