import 'package:mineral/api.dart';

import 'events_command.dart';
import 'scheduled_event_announce.dart';

final class ScheduledEventsProvider extends Provider {
  final Client _client;

  ScheduledEventsProvider(this._client) {
    _client
      ..register<EventsCommand>(EventsCommand.new)
      ..register<ScheduledEventAnnounce>(ScheduledEventAnnounce.new);
  }
}
