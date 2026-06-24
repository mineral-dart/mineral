import 'dart:async';

import 'package:mineral/src/domains/events/event.dart';
import 'package:mineral/src/domains/events/internal_event_params.dart';

abstract interface class EventDispatcherContract {
  void dispatch<T extends Object>({
    required Event event,
    required T payload,
    bool Function(String?)? constraint,
  });

  void dispose();
}

final class EventDispatcher implements EventDispatcherContract {
  final Map<Event, StreamController<InternalEventParams>> _controllers = {};

  StreamController<InternalEventParams> controllerFor(Event event) {
    return _controllers.putIfAbsent(
      event,
      StreamController<InternalEventParams>.broadcast,
    );
  }

  @override
  void dispatch<T extends Object>({
    required Event event,
    required T payload,
    bool Function(String?)? constraint,
  }) {
    final controller = _controllers[event];
    if (controller != null && controller.hasListener) {
      controller.add(InternalEventParams(event, payload, constraint));
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }
}
