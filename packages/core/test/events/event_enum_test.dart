import 'package:mineral/src/domains/events/event.dart';
import 'package:test/test.dart';

void main() {
  group('Event enum', () {
    test('has at least 60 event types', () {
      expect(Event.values.length, greaterThanOrEqualTo(60));
    });

    test('every event has a non-null value type', () {
      for (final event in Event.values) {
        expect(event.value, isNotNull,
            reason: '${event.name} should have a value type');
      }
    });

    test('every event has a non-empty parameters list', () {
      for (final event in Event.values) {
        expect(event.parameters, isNotEmpty,
            reason: '${event.name} should have at least one parameter');
      }
    });

    test('every parameter has format [type, name]', () {
      for (final event in Event.values) {
        for (final param in event.parameters) {
          expect(param, hasLength(2),
              reason:
                  '${event.name} parameter should have [type, name] format');
          expect(param[0], isA<String>(),
              reason: '${event.name} parameter type should be a String');
          expect(param[1], isA<String>(),
              reason: '${event.name} parameter name should be a String');
          expect(param[0], isNotEmpty,
              reason: '${event.name} parameter type should not be empty');
          expect(param[1], isNotEmpty,
              reason: '${event.name} parameter name should not be empty');
        }
      }
    });

    group('specific events', () {
      test('ready event has Bot parameter', () {
        expect(Event.ready.parameters[0][0], 'Bot');
        expect(Event.ready.parameters[0][1], 'bot');
      });

      test('guildMessageCreate has GuildMessage parameter', () {
        expect(Event.guildMessageCreate.parameters[0][0], 'GuildMessage');
        expect(Event.guildMessageCreate.parameters[0][1], 'message');
      });

      test('privateMessageCreate has PrivateMessage parameter', () {
        expect(Event.privateMessageCreate.parameters[0][0], 'PrivateMessage');
        expect(Event.privateMessageCreate.parameters[0][1], 'message');
      });

      test('guildMemberAdd has Guild and Member parameters', () {
        expect(Event.guildMemberAdd.parameters, hasLength(2));
        expect(Event.guildMemberAdd.parameters[0][0], 'Guild');
        expect(Event.guildMemberAdd.parameters[1][0], 'Member');
      });

      test('voiceStateUpdate has before and after VoiceState parameters', () {
        expect(Event.voiceStateUpdate.parameters, hasLength(2));
        expect(Event.voiceStateUpdate.parameters[0][1], 'before');
        expect(Event.voiceStateUpdate.parameters[1][1], 'after');
      });

      test('guildUpdate has before and after Guild parameters', () {
        expect(Event.guildUpdate.parameters, hasLength(2));
        expect(Event.guildUpdate.parameters[0][0], 'Guild');
        expect(Event.guildUpdate.parameters[0][1], 'before');
        expect(Event.guildUpdate.parameters[1][0], 'Guild');
        expect(Event.guildUpdate.parameters[1][1], 'after');
      });

      test('guildButtonClick has GuildButtonContext parameter', () {
        expect(Event.guildButtonClick.parameters[0][0], 'GuildButtonContext');
        expect(Event.guildButtonClick.parameters[0][1], 'ctx');
      });

      test('guildModalSubmit has GuildModalContext parameter', () {
        expect(Event.guildModalSubmit.parameters[0][0], 'GuildModalContext');
        expect(Event.guildModalSubmit.parameters[0][1], 'ctx');
      });
    });

    group('event categories', () {
      test('guild events exist', () {
        final guildEvents =
            Event.values.where((e) => e.name.startsWith('guild'));
        expect(guildEvents.length, greaterThanOrEqualTo(40));
      });

      test('private events exist', () {
        final privateEvents =
            Event.values.where((e) => e.name.startsWith('private'));
        expect(privateEvents.length, greaterThanOrEqualTo(10));
      });

      test('voice events exist', () {
        final voiceEvents =
            Event.values.where((e) => e.name.startsWith('voice'));
        expect(voiceEvents.length, greaterThanOrEqualTo(4));
      });

      test('common events exist', () {
        expect(Event.values.contains(Event.ready), isTrue);
        expect(Event.values.contains(Event.typing), isTrue);
        expect(Event.values.contains(Event.inviteCreate), isTrue);
        expect(Event.values.contains(Event.inviteDelete), isTrue);
      });
    });

    group('all event names are unique', () {
      test('no duplicate event names', () {
        final names = Event.values.map((e) => e.name).toSet();
        expect(names.length, Event.values.length);
      });
    });
  });
}
