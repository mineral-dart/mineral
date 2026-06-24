import 'package:mineral/src/domains/events/event.dart';
import 'package:mineral/src/domains/events/event_dispatcher.dart';
import 'package:mineral/src/domains/events/internal_event_params.dart';
import 'package:test/test.dart';

void main() {
  group('EventDispatcher', () {
    late EventDispatcher dispatcher;

    setUp(() {
      dispatcher = EventDispatcher();
    });

    tearDown(() {
      dispatcher.dispose();
    });

    test('dispatch adds event to the stream', () async {
      final received = <InternalEventParams>[];

      dispatcher.controllerFor(Event.ready).stream.listen(received.add);

      dispatcher.dispatch(event: Event.ready, payload: 'bot');

      await Future.delayed(Duration(milliseconds: 50));

      expect(received, hasLength(1));
      expect(received.first.event, Event.ready);
      expect(received.first.payload, 'bot');
      expect(received.first.constraint, isNull);
    });

    test('dispatch propagates constraint', () async {
      bool myConstraint(String? id) => id == 'test';

      final received = <InternalEventParams>[];

      dispatcher
          .controllerFor(Event.guildButtonClick)
          .stream
          .listen(received.add);

      dispatcher.dispatch(
        event: Event.guildButtonClick,
        payload: 'ctx',
        constraint: myConstraint,
      );

      await Future.delayed(Duration(milliseconds: 50));

      expect(received, hasLength(1));
      expect(received.first.constraint, isNotNull);
      expect(received.first.constraint!('test'), isTrue);
      expect(received.first.constraint!('other'), isFalse);
    });

    test('dispatch emits multiple events in order', () async {
      final events = <Event>[];

      dispatcher
          .controllerFor(Event.ready)
          .stream
          .listen((e) => events.add(e.event));
      dispatcher
          .controllerFor(Event.guildMessageCreate)
          .stream
          .listen((e) => events.add(e.event));
      dispatcher
          .controllerFor(Event.guildMemberAdd)
          .stream
          .listen((e) => events.add(e.event));

      dispatcher
        ..dispatch(event: Event.ready, payload: 'bot')
        ..dispatch(event: Event.guildMessageCreate, payload: 'msg')
        ..dispatch(event: Event.guildMemberAdd, payload: 'member');

      await Future.delayed(Duration(milliseconds: 50));

      expect(events, hasLength(3));
      expect(events[0], Event.ready);
      expect(events[1], Event.guildMessageCreate);
      expect(events[2], Event.guildMemberAdd);
    });

    test('dispose closes all streams', () {
      final controller = dispatcher.controllerFor(Event.ready);
      dispatcher.dispose();
      expect(controller.isClosed, isTrue);
    });

    test('dispatch with typed record payload', () async {
      final received = <InternalEventParams>[];

      dispatcher.controllerFor(Event.ready).stream.listen(received.add);

      dispatcher.dispatch(event: Event.ready, payload: (label: 'bot'));

      await Future.delayed(Duration(milliseconds: 50));

      expect(received, hasLength(1));
      expect((received.first.payload as ({String label})).label, 'bot');
    });
  });
}
