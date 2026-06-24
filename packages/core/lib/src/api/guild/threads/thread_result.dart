import 'package:mineral/api.dart';
import 'package:mineral/src/api/guild/channels/private_thread_channel.dart';
import 'package:mineral/src/api/guild/channels/public_thread_channel.dart';

final class ThreadResult {
  final Map<Snowflake, GuildChannel> _channels;

  Map<Snowflake, PublicThreadChannel> get publicChannels {
    return _channels.values
        .whereType<PublicThreadChannel>()
        .fold<Map<Snowflake, PublicThreadChannel>>({}, (acc, channel) {
          acc[channel.id] = channel;
          return acc;
        });
  }

  Map<Snowflake, PrivateThreadChannel> get privateChannels {
    return _channels.values
        .whereType<PrivateThreadChannel>()
        .fold<Map<Snowflake, PrivateThreadChannel>>({}, (acc, channel) {
          acc[channel.id] = channel;
          return acc;
        });
  }

  ThreadResult(this._channels);
}
