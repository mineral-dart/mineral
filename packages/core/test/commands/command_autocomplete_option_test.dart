import 'package:mineral/src/api/common/commands/command_choice_option.dart';
import 'package:mineral/src/api/common/commands/command_option.dart';
import 'package:mineral/src/api/common/commands/command_option_type.dart';
import 'package:mineral/src/domains/commands/contexts/autocomplete_context.dart';
import 'package:test/test.dart';

List<Choice> _defaultHandler(AutocompleteContext ctx) => [
  Choice('Option A', 'a'),
  Choice('Option B', 'b'),
];

void main() {
  group('Option autocomplete', () {
    final AutocompleteHandler handler = _defaultHandler;

    group('Option.string with autocomplete', () {
      test('serializes autocomplete: true in toJson', () {
        final option = Option.string(
          name: 'query',
          description: 'Search query',
          autocomplete: true,
          onAutocomplete: handler,
        );

        final json = option.toJson();
        expect(json['autocomplete'], isTrue);
      });

      test('does not emit autocomplete key when false', () {
        final option = Option.string(
          name: 'query',
          description: 'Search query',
        );
        final json = option.toJson();
        expect(json.containsKey('autocomplete'), isFalse);
      });

      test('stores the handler', () {
        final option = Option.string(
          name: 'query',
          description: 'Search query',
          autocomplete: true,
          onAutocomplete: handler,
        );

        expect(option.onAutocomplete, isNotNull);
        expect(option.autocomplete, isTrue);
      });

      test('type is still CommandOptionType.string', () {
        final option = Option.string(
          name: 'query',
          description: 'Search query',
          autocomplete: true,
          onAutocomplete: handler,
        );

        expect(option.type, CommandOptionType.string);
      });

      test('throws when autocomplete=true but no handler provided', () {
        expect(
          () => Option.string(
            name: 'query',
            description: 'Search query',
            autocomplete: true,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Option.integer with autocomplete', () {
      test('serializes autocomplete: true in toJson', () {
        final option = Option.integer(
          name: 'level',
          description: 'A level',
          autocomplete: true,
          onAutocomplete: (ctx) => [],
        );

        final json = option.toJson();
        expect(json['autocomplete'], isTrue);
      });

      test('does not emit autocomplete key when false', () {
        final option = Option.integer(name: 'level', description: 'A level');
        expect(option.toJson().containsKey('autocomplete'), isFalse);
      });

      test('throws when autocomplete=true but no handler provided', () {
        expect(
          () => Option.integer(
            name: 'level',
            description: 'A level',
            autocomplete: true,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Option.double with autocomplete', () {
      test('serializes autocomplete: true in toJson', () {
        final option = Option.double(
          name: 'ratio',
          description: 'A ratio',
          autocomplete: true,
          onAutocomplete: (ctx) => [],
        );

        final json = option.toJson();
        expect(json['autocomplete'], isTrue);
      });

      test('does not emit autocomplete key when false', () {
        final option = Option.double(name: 'ratio', description: 'A ratio');
        expect(option.toJson().containsKey('autocomplete'), isFalse);
      });

      test('throws when autocomplete=true but no handler provided', () {
        expect(
          () => Option.double(
            name: 'ratio',
            description: 'A ratio',
            autocomplete: true,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('non-autocomplete options', () {
      test('Option.boolean does not have autocomplete field', () {
        final option = Option.boolean(name: 'flag', description: 'A flag');
        expect(option.toJson().containsKey('autocomplete'), isFalse);
      });

      test('Option without autocomplete has null onAutocomplete', () {
        final option = Option.string(name: 'name', description: 'A name');
        expect(option.onAutocomplete, isNull);
        expect(option.autocomplete, isFalse);
      });
    });

    group('AutocompleteHandler invocation', () {
      test('handler returns choices', () async {
        final option = Option.string(
          name: 'fruit',
          description: 'Pick a fruit',
          autocomplete: true,
          onAutocomplete: (ctx) => [
            Choice('Apple', 'apple'),
            Choice('Banana', 'banana'),
          ],
        );

        final ctx = AutocompleteContext(
          name: 'fruit',
          value: 'app',
          options: {},
        );

        final choices = await option.onAutocomplete!(ctx);
        expect(choices, hasLength(2));
        expect(choices[0].name, 'Apple');
        expect(choices[0].value, 'apple');
      });

      test('handler receives partial value', () async {
        String? capturedValue;

        final option = Option.string(
          name: 'query',
          description: 'Search',
          autocomplete: true,
          onAutocomplete: (ctx) {
            capturedValue = ctx.value;
            return [];
          },
        );

        final ctx = AutocompleteContext(
          name: 'query',
          value: 'hell',
          options: {},
        );

        await option.onAutocomplete!(ctx);
        expect(capturedValue, 'hell');
      });
    });
  });
}
