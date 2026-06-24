import 'package:mineral/src/domains/events/event.dart';
import 'package:mineral/src/domains/events/internal_event_params.dart';
import 'package:test/test.dart';

void main() {
  group('InternalEventParams', () {
    test('stores event, payload, and constraint', () {
      bool constraint(String? id) => id == 'btn-1';

      final params = InternalEventParams(Event.ready, (
        label: 'param1',
        value: 'param2',
      ), constraint);

      expect(params.event, Event.ready);
      final p = params.payload as ({String label, String value});
      expect(p.label, 'param1');
      expect(p.value, 'param2');
      expect(params.constraint, isNotNull);
      expect(params.constraint!('btn-1'), isTrue);
      expect(params.constraint!('btn-2'), isFalse);
    });

    test('constraint can be null', () {
      final params = InternalEventParams(
        Event.guildMessageCreate,
        'message',
        null,
      );

      expect(params.constraint, isNull);
    });

    test('payload can be a simple value', () {
      final params = InternalEventParams(Event.ready, 'bot', null);
      expect(params.payload, 'bot');
    });

    test('works with different event types', () {
      final readyParams = InternalEventParams(Event.ready, (bot: 'bot'), null);
      final msgParams = InternalEventParams(Event.guildMessageCreate, (
        message: 'msg',
      ), null);
      final voiceParams = InternalEventParams(Event.voiceStateUpdate, (
        before: 'before',
        after: 'after',
      ), null);

      expect(readyParams.event, Event.ready);
      expect(msgParams.event, Event.guildMessageCreate);
      expect(voiceParams.event, Event.voiceStateUpdate);
      final vp = voiceParams.payload as ({String before, String after});
      expect(vp.before, 'before');
      expect(vp.after, 'after');
    });
  });
}
