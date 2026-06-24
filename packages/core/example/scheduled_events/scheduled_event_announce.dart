import 'package:mineral/api.dart';
import 'package:mineral/events.dart';

/// Reacts to the **GUILD_SCHEDULED_EVENT_CREATE** gateway event and announces
/// the new event in the system channel.
final class ScheduledEventAnnounce extends GuildScheduledEventCreateEvent {
  @override
  Future<void> handle(Guild guild, GuildScheduledEvent event) async {
    final systemChannel = await guild.channels.resolveSystemChannel();
    if (systemChannel == null) {
      return;
    }

    await systemChannel.send(
      MessageBuilder.text('📅 A new event was scheduled: **${event.name}**'),
    );
  }
}
