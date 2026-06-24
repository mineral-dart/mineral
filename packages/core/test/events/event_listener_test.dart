import 'dart:async';

import 'package:mineral/src/domains/events/event.dart';
import 'package:mineral/src/domains/events/event_dispatcher.dart';
import 'package:mineral/src/domains/events/internal_event_params.dart';
import 'package:test/test.dart';

/// Tests the event listener mechanism using the underlying stream directly.
/// EventListener depends on Kernel (heavy), so we test the dispatch+listen
/// pattern through EventDispatcher which is the core mechanism.
void main() {
  group('Event listener mechanism', () {
    late EventDispatcher dispatcher;

    setUp(() {
      dispatcher = EventDispatcher();
    });

    tearDown(() {
      dispatcher.dispose();
    });

    test('filters events by type', () async {
      final received = <Event>[];

      dispatcher
          .controllerFor(Event.ready)
          .stream
          .listen((e) => received.add(e.event));

      dispatcher
        ..dispatch(event: Event.ready, payload: 'bot')
        ..dispatch(event: Event.guildMessageCreate, payload: 'msg')
        ..dispatch(event: Event.ready, payload: 'bot2');

      await Future.delayed(Duration(milliseconds: 50));

      expect(received, hasLength(2));
      expect(received.every((e) => e == Event.ready), isTrue);
    });

    test('dispatches payload to handler', () async {
      final receivedPayloads = <Object>[];

      dispatcher
          .controllerFor(Event.guildMemberAdd)
          .stream
          .listen((e) => receivedPayloads.add(e.payload));

      dispatcher.dispatch(
          event: Event.guildMemberAdd,
          payload: (guild: 'guild1', member: 'member1'));

      await Future.delayed(Duration(milliseconds: 50));

      expect(receivedPayloads, hasLength(1));
      final p = receivedPayloads.first as ({String guild, String member});
      expect(p.guild, 'guild1');
      expect(p.member, 'member1');
    });

    test('constraint filters on customId', () async {
      final received = <InternalEventParams>[];

      dispatcher.controllerFor(Event.guildButtonClick).stream.where((e) {
        return switch (e.constraint) {
          final bool Function(String?) constraint => constraint('btn-save'),
          _ => true
        };
      }).listen(received.add);

      // This one matches the constraint
      dispatcher
        ..dispatch(
          event: Event.guildButtonClick,
          payload: 'ctx1',
          constraint: (id) => id == 'btn-save',
        )
        // This one does NOT match
        ..dispatch(
          event: Event.guildButtonClick,
          payload: 'ctx2',
          constraint: (id) => id == 'btn-delete',
        )
        // This one has no constraint (should pass)
        ..dispatch(
          event: Event.guildButtonClick,
          payload: 'ctx3',
        );

      await Future.delayed(Duration(milliseconds: 50));

      expect(received, hasLength(2));
      expect(received[0].payload, 'ctx1');
      expect(received[1].payload, 'ctx3');
    });

    test('does not receive events after subscription cancel', () async {
      final received = <Event>[];

      final sub = dispatcher
          .controllerFor(Event.ready)
          .stream
          .listen((e) => received.add(e.event));

      dispatcher.dispatch(event: Event.ready, payload: 'bot');
      await Future.delayed(Duration(milliseconds: 50));

      await sub.cancel();

      dispatcher.dispatch(event: Event.ready, payload: 'bot2');
      await Future.delayed(Duration(milliseconds: 50));

      expect(received, hasLength(1));
    });

    test('multiple listeners receive same event', () async {
      final controller = dispatcher.controllerFor(Event.ready);

      final future1 = controller.stream.first;
      final future2 = controller.stream.first;

      dispatcher.dispatch(event: Event.ready, payload: 'bot');

      final results = await Future.wait([future1, future2]);
      expect(results[0].event, Event.ready);
      expect(results[1].event, Event.ready);
    });

    test('different listeners on different events receive only their events',
        () async {
      final readyFuture = dispatcher
          .controllerFor(Event.ready)
          .stream
          .take(2)
          .toList();

      final messageFuture = dispatcher
          .controllerFor(Event.guildMessageCreate)
          .stream
          .first;

      dispatcher
        ..dispatch(event: Event.ready, payload: 'bot')
        ..dispatch(event: Event.guildMessageCreate, payload: 'msg')
        ..dispatch(event: Event.ready, payload: 'bot');

      final readyEvents = await readyFuture;
      final messageEvent = await messageFuture;

      expect(readyEvents, hasLength(2));
      expect(readyEvents.every((e) => e.event == Event.ready), isTrue);
      expect(messageEvent.event, Event.guildMessageCreate);
    });
  });
}
