import 'dart:async';

import 'package:mineral/src/domains/common/kernel.dart';
import 'package:mineral/src/domains/events/event.dart';
import 'package:mineral/src/domains/events/event_dispatcher.dart';

abstract interface class EventListenerContract {
  Kernel get kernel;

  EventDispatcherContract get dispatcher;

  void Function(Event event, Object error, StackTrace stackTrace)? onEventError;

  StreamSubscription listen<T extends Function>(
      {required Event event, required T handle, required String? customId});

  void unsubscribe(StreamSubscription subscription);

  void dispose();
}

final class EventListener implements EventListenerContract {
  final List<StreamSubscription> _subscriptions = [];

  @override
  late final Kernel kernel;

  @override
  late final EventDispatcher dispatcher;

  @override
  void Function(Event event, Object error, StackTrace stackTrace)? onEventError;

  EventListener() {
    dispatcher = EventDispatcher();
  }

  @override
  StreamSubscription listen<T extends Function>(
      {required Event event, required T handle, required String? customId}) {
    final controller = dispatcher.controllerFor(event);

    final subscription = controller.stream.where((element) {
      return switch (element.constraint) {
        final bool Function(String?) constraint => constraint(customId),
        _ => true
      };
    }).listen((element) async {
      try {
        await (handle as Function)(element.payload);
      } on Exception catch (e, stackTrace) {
        kernel.logger.error('Failed to dispatch event "${event.name}": $e');
        kernel.logger.trace('$stackTrace');
        onEventError?.call(event, e, stackTrace);
        // ignore: avoid_catching_errors, crash-safety boundary for event handlers
      } on Error catch (e, stackTrace) {
        kernel.logger.error('Failed to dispatch event "${event.name}": $e');
        kernel.logger.trace('$stackTrace');
        onEventError?.call(event, e, stackTrace);
      }
    });

    _subscriptions.add(subscription);
    return subscription;
  }

  @override
  void unsubscribe(StreamSubscription subscription) {
    subscription.cancel();
    _subscriptions.remove(subscription);
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    dispatcher.dispose();
  }
}
