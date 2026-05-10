import 'package:mineral/src/api/common/channel_methods.dart';
import 'package:mineral/src/api/common/channel_properties.dart';
import 'package:mineral/src/api/server/channels/server_channel.dart';
import 'package:mineral/src/api/server/managers/threads_manager.dart';

final class ServerCategoryChannel extends ServerChannel {
  @override
  final ChannelProperties properties;

  @override
  late final ChannelMethods methods;

  ThreadsManager get threads => properties.threads;

  ServerCategoryChannel(this.properties) {
    methods = ChannelMethods(properties.serverId!, properties.id,
        ctx: properties.ctx);
  }
}
