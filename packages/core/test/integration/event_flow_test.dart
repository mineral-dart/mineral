import 'dart:async';

import 'package:mineral/src/domains/events/event.dart';
import 'package:mineral/src/domains/events/event_dispatcher.dart';
import 'package:mineral/src/domains/events/internal_event_params.dart';
import 'package:test/test.dart';

/// Integration tests for the event dispatch flow.
///
/// Verifies the end-to-end behavior of [EventDispatcher] when multiple
/// listeners subscribe to different events, constraints are applied,
/// and the dispatcher lifecycle (dispatch, unsubscribe, dispose) is exercised.
void main() {
  group('Event dispatch flow', () {
    late EventDispatcher dispatcher;

    setUp(() {
      dispatcher = EventDispatcher();
    });

    tearDown(() {
      dispatcher.dispose();
    });

    test('delivers events to correct listeners across multiple event types',
        () async {
      final readyPayloads = <Object>[];
      final memberAddPayloads = <Object>[];
      final messagePayloads = <Object>[];

      dispatcher
          .controllerFor(Event.ready)
          .stream
          .listen((e) => readyPayloads.add(e.payload));

      dispatcher
          .controllerFor(Event.serverMemberAdd)
          .stream
          .listen((e) => memberAddPayloads.add(e.payload));

      dispatcher
          .controllerFor(Event.serverMessageCreate)
          .stream
          .listen((e) => messagePayloads.add(e.payload));

      dispatcher
        ..dispatch(event: Event.ready, payload: (bot: 'bot-instance'))
        ..dispatch(
            event: Event.serverMemberAdd,
            payload: (server: 'guild-1', member: 'user-42'))
        ..dispatch(
            event: Event.serverMessageCreate,
            payload: (channel: 'channel-5', text: 'hello'))
        ..dispatch(event: Event.ready, payload: (bot: 'bot-reconnect'))
        ..dispatch(
            event: Event.serverMessageCreate,
            payload: (channel: 'channel-5', text: 'world'));

      await Future.delayed(Duration(milliseconds: 50));

      expect(readyPayloads, hasLength(2));
      expect((readyPayloads[0] as ({String bot})).bot, 'bot-instance');
      expect((readyPayloads[1] as ({String bot})).bot, 'bot-reconnect');

      expect(memberAddPayloads, hasLength(1));
      final ma = memberAddPayloads[0] as ({String server, String member});
      expect(ma.server, 'guild-1');
      expect(ma.member, 'user-42');

      expect(messagePayloads, hasLength(2));
    });

    test('passes payload accurately through the dispatch chain', () async {
      final captured = <InternalEventParams>[];

      dispatcher.controllerFor(Event.serverUpdate).stream.listen(captured.add);

      final complexPayload = (before: 'before-state', after: {'name': 'My Server', 'id': 123});
      dispatcher.dispatch(event: Event.serverUpdate, payload: complexPayload);

      await Future.delayed(Duration(milliseconds: 50));

      expect(captured, hasLength(1));
      expect(captured.first.event, Event.serverUpdate);
      final p = captured.first.payload as ({String before, Map after});
      expect(p.before, 'before-state');
      expect(p.after['id'], 123);
    });

    test('customId constraints work independently across event types',
        () async {
      final buttonClicks = <String>[];
      final modalSubmits = <String>[];

      // Button listener filtered to 'btn-confirm'
      dispatcher.controllerFor(Event.serverButtonClick).stream.where((e) {
        return switch (e.constraint) {
          final bool Function(String?) constraint => constraint('btn-confirm'),
          _ => true
        };
      }).listen((e) => buttonClicks.add(e.payload as String));

      // Modal listener filtered to 'modal-settings'
      dispatcher.controllerFor(Event.serverModalSubmit).stream.where((e) {
        return switch (e.constraint) {
          final bool Function(String?) constraint =>
            constraint('modal-settings'),
          _ => true
        };
      }).listen((e) => modalSubmits.add(e.payload as String));

      // Dispatch button and modal events with various constraints
      dispatcher
        ..dispatch(
          event: Event.serverButtonClick,
          payload: 'click-1',
          constraint: (id) => id == 'btn-confirm',
        )
        ..dispatch(
          event: Event.serverButtonClick,
          payload: 'click-2',
          constraint: (id) => id == 'btn-cancel',
        )
        ..dispatch(
          event: Event.serverButtonClick,
          payload: 'click-3',
        )
        ..dispatch(
          event: Event.serverModalSubmit,
          payload: 'submit-1',
          constraint: (id) => id == 'modal-settings',
        )
        ..dispatch(
          event: Event.serverModalSubmit,
          payload: 'submit-2',
          constraint: (id) => id == 'modal-profile',
        );

      await Future.delayed(Duration(milliseconds: 50));

      // Button: click-1 (matched) and click-3 (no constraint = pass-through)
      expect(buttonClicks, ['click-1', 'click-3']);

      // Modal: only submit-1 matched
      expect(modalSubmits, ['submit-1']);
    });

    test('multiple dispatch cycles deliver events correctly', () async {
      final allReceived = <String>[];

      dispatcher
          .controllerFor(Event.serverMemberAdd)
          .stream
          .listen((e) => allReceived.add(e.payload as String));

      // First cycle
      dispatcher
        ..dispatch(event: Event.serverMemberAdd, payload: 'user-1')
        ..dispatch(event: Event.serverMemberAdd, payload: 'user-2');

      await Future.delayed(Duration(milliseconds: 50));
      expect(allReceived, ['user-1', 'user-2']);

      // Second cycle
      dispatcher
        ..dispatch(event: Event.serverMemberAdd, payload: 'user-3')
        ..dispatch(event: Event.serverMemberAdd, payload: 'user-4');

      await Future.delayed(Duration(milliseconds: 50));
      expect(allReceived, ['user-1', 'user-2', 'user-3', 'user-4']);

      // Third cycle with a different event interleaved
      dispatcher
          .controllerFor(Event.serverMemberRemove)
          .stream
          .listen((e) => allReceived.add('removed:${e.payload}'));

      dispatcher
        ..dispatch(event: Event.serverMemberAdd, payload: 'user-5')
        ..dispatch(event: Event.serverMemberRemove, payload: 'user-1');

      await Future.delayed(Duration(milliseconds: 50));
      expect(allReceived,
          ['user-1', 'user-2', 'user-3', 'user-4', 'user-5', 'removed:user-1']);
    });

    test('disposing the dispatcher stops all event delivery', () async {
      final readyEvents = <String>[];
      final messageEvents = <String>[];

      dispatcher
          .controllerFor(Event.ready)
          .stream
          .listen((e) => readyEvents.add(e.payload as String));

      dispatcher
          .controllerFor(Event.serverMessageCreate)
          .stream
          .listen((e) => messageEvents.add(e.payload as String));

      // Dispatch before dispose
      dispatcher
        ..dispatch(event: Event.ready, payload: 'bot-1')
        ..dispatch(event: Event.serverMessageCreate, payload: 'msg-1');

      await Future.delayed(Duration(milliseconds: 50));
      expect(readyEvents, ['bot-1']);
      expect(messageEvents, ['msg-1']);

      // Dispose
      dispatcher
        ..dispose()
        // Dispatch after dispose -- controllers are closed and cleared,
        // so dispatch should be a no-op (no controller found).
        ..dispatch(event: Event.ready, payload: 'bot-2')
        ..dispatch(event: Event.serverMessageCreate, payload: 'msg-2');

      await Future.delayed(Duration(milliseconds: 50));

      // No new events delivered
      expect(readyEvents, ['bot-1']);
      expect(messageEvents, ['msg-1']);
    });

    test('unsubscribe stops delivery for that listener only', () async {
      final listener1 = <String>[];
      final listener2 = <String>[];

      final controller = dispatcher.controllerFor(Event.serverMessageCreate);

      final sub1 =
          controller.stream.listen((e) => listener1.add(e.payload as String));
      controller.stream.listen((e) => listener2.add(e.payload as String));

      // Both receive first dispatch
      dispatcher.dispatch(event: Event.serverMessageCreate, payload: 'msg-1');

      await Future.delayed(Duration(milliseconds: 50));
      expect(listener1, ['msg-1']);
      expect(listener2, ['msg-1']);

      // Unsubscribe listener1
      await sub1.cancel();

      // Only listener2 receives second dispatch
      dispatcher.dispatch(event: Event.serverMessageCreate, payload: 'msg-2');

      await Future.delayed(Duration(milliseconds: 50));
      expect(listener1, ['msg-1']);
      expect(listener2, ['msg-1', 'msg-2']);
    });

    test('subscribe, receive, unsubscribe, dispatch again verifies no delivery',
        () async {
      final received = <String>[];

      final sub = dispatcher
          .controllerFor(Event.serverBanAdd)
          .stream
          .listen((e) => received.add(e.payload as String));

      // Step 1: dispatch and confirm receipt
      dispatcher.dispatch(event: Event.serverBanAdd, payload: 'ban-user-1');
      await Future.delayed(Duration(milliseconds: 50));
      expect(received, ['ban-user-1']);

      // Step 2: unsubscribe
      await sub.cancel();

      // Step 3: dispatch again
      dispatcher.dispatch(event: Event.serverBanAdd, payload: 'ban-user-2');
      await Future.delayed(Duration(milliseconds: 50));

      // Step 4: verify no new delivery
      expect(received, hasLength(1));
      expect(received, ['ban-user-1']);
    });

    test('dispatch to event with no listeners is a silent no-op', () async {
      // No listener registered for serverDelete
      // This should not throw or cause any side effects
      dispatcher.dispatch(event: Event.serverDelete, payload: 'guild-99');
      await Future.delayed(Duration(milliseconds: 50));

      // Verify other events still work after dispatching to empty event
      final received = <String>[];
      dispatcher
          .controllerFor(Event.ready)
          .stream
          .listen((e) => received.add(e.payload as String));

      dispatcher.dispatch(event: Event.ready, payload: 'bot');
      await Future.delayed(Duration(milliseconds: 50));
      expect(received, ['bot']);
    });
  });
}
