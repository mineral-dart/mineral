import 'package:mineral/src/api/common/commands/command_choice_option.dart';
import 'package:mineral/src/api/common/commands/command_option.dart';
import 'package:mineral/src/api/common/commands/command_option_type.dart';
import 'package:mineral/src/api/common/types/channel_type.dart';
import 'package:test/test.dart';

void main() {
  group('Option', () {
    group('Option.string', () {
      test('creates string option with correct type', () {
        final option = Option.string(name: 'name', description: 'A name');
        expect(option.type, CommandOptionType.string);
        expect(option.name, 'name');
        expect(option.description, 'A name');
        expect(option.isRequired, false);
        expect(option.channelTypes, isNull);
      });

      test('respects required parameter', () {
        final option = Option.string(
          name: 'name',
          description: 'A name',
          required: true,
        );
        expect(option.isRequired, true);
      });

      test('toJson generates correct output', () {
        final option = Option.string(
          name: 'reason',
          description: 'The reason',
          required: true,
        );
        final json = option.toJson();

        expect(json['name'], 'reason');
        expect(json['description'], 'The reason');
        expect(json['type'], CommandOptionType.string.value);
        expect(json['required'], true);
        expect(json['channel_types'], isNull);
      });
    });

    group('Option.integer', () {
      test('creates integer option with correct type', () {
        final option = Option.integer(name: 'count', description: 'A count');
        expect(option.type, CommandOptionType.integer);
        expect(option.name, 'count');
      });

      test('toJson generates correct type value', () {
        final json = Option.integer(name: 'n', description: 'd').toJson();
        expect(json['type'], CommandOptionType.integer.value);
      });
    });

    group('Option.double', () {
      test('creates double option with correct type', () {
        final option = Option.double(name: 'ratio', description: 'A ratio');
        expect(option.type, CommandOptionType.double);
      });

      test('toJson generates correct type value', () {
        final json = Option.double(name: 'n', description: 'd').toJson();
        expect(json['type'], CommandOptionType.double.value);
      });
    });

    group('Option.boolean', () {
      test('creates boolean option with correct type', () {
        final option = Option.boolean(name: 'flag', description: 'A flag');
        expect(option.type, CommandOptionType.boolean);
      });

      test('toJson generates correct type value', () {
        final json = Option.boolean(name: 'f', description: 'd').toJson();
        expect(json['type'], CommandOptionType.boolean.value);
      });
    });

    group('Option.user', () {
      test('creates user option with correct type', () {
        final option = Option.user(name: 'target', description: 'Target user');
        expect(option.type, CommandOptionType.user);
      });

      test('toJson generates correct type value', () {
        final json = Option.user(name: 'u', description: 'd').toJson();
        expect(json['type'], CommandOptionType.user.value);
      });
    });

    group('Option.channel', () {
      test('creates channel option with correct type', () {
        final option = Option.channel(
          name: 'channel',
          description: 'A channel',
        );
        expect(option.type, CommandOptionType.channel);
        expect(option.channelTypes, isEmpty);
      });

      test('accepts channel type filter', () {
        final option = Option.channel(
          name: 'channel',
          description: 'A text channel',
          channels: [ChannelType.guildText],
        );
        expect(option.channelTypes, hasLength(1));
        expect(option.channelTypes!.first, ChannelType.guildText);
      });

      test('toJson serializes channel types', () {
        final option = Option.channel(
          name: 'ch',
          description: 'd',
          channels: [ChannelType.guildText, ChannelType.guildVoice],
        );
        final json = option.toJson();

        expect(json['channel_types'], hasLength(2));
        expect(json['channel_types'][0], ChannelType.guildText.value);
        expect(json['channel_types'][1], ChannelType.guildVoice.value);
      });
    });

    group('Option.role', () {
      test('creates role option with correct type', () {
        final option = Option.role(name: 'role', description: 'A role');
        expect(option.type, CommandOptionType.role);
      });
    });

    group('Option.mentionable', () {
      test('creates mentionable option with correct type', () {
        final option = Option.mentionable(
          name: 'mention',
          description: 'A mentionable',
        );
        expect(option.type, CommandOptionType.mentionable);
      });
    });

    group('Option.attachment', () {
      test('creates attachment option with correct type', () {
        final option = Option.attachment(
          name: 'file',
          description: 'An attachment',
        );
        expect(option.type, CommandOptionType.attachment);
      });
    });

    group('default required value', () {
      test('all factory constructors default to not required', () {
        final options = [
          Option.string(name: 'a', description: 'd'),
          Option.integer(name: 'b', description: 'd'),
          Option.double(name: 'c', description: 'd'),
          Option.boolean(name: 'd', description: 'd'),
          Option.user(name: 'e', description: 'd'),
          Option.channel(name: 'f', description: 'd'),
          Option.role(name: 'g', description: 'd'),
          Option.mentionable(name: 'h', description: 'd'),
          Option.attachment(name: 'i', description: 'd'),
        ];

        for (final option in options) {
          expect(
            option.isRequired,
            false,
            reason: '${option.name} should default to not required',
          );
        }
      });
    });
  });

  group('ChoiceOption', () {
    group('ChoiceOption.string', () {
      test('creates string choice option', () {
        final option = ChoiceOption.string(
          name: 'color',
          description: 'Pick a color',
          choices: [Choice('Red', 'red'), Choice('Blue', 'blue')],
        );

        expect(option.type, CommandOptionType.string);
        expect(option.name, 'color');
        expect(option.choices, hasLength(2));
        expect(option.isRequired, false);
      });

      test('toJson serializes choices', () {
        final option = ChoiceOption.string(
          name: 'color',
          description: 'Pick a color',
          choices: [Choice('Red', 'red'), Choice('Blue', 'blue')],
        );

        final json = option.toJson();

        expect(json['name'], 'color');
        expect(json['type'], CommandOptionType.string.value);
        expect(json['choices'], hasLength(2));
        expect(json['choices'][0]['name'], 'Red');
        expect(json['choices'][0]['value'], 'red');
        expect(json['choices'][1]['name'], 'Blue');
        expect(json['choices'][1]['value'], 'blue');
      });

      test('respects required parameter', () {
        final option = ChoiceOption.string(
          name: 'color',
          description: 'Pick',
          choices: [Choice('Red', 'red')],
          required: true,
        );
        expect(option.isRequired, true);
      });
    });

    group('ChoiceOption.integer', () {
      test('creates integer choice option', () {
        final option = ChoiceOption.integer(
          name: 'level',
          description: 'Pick a level',
          choices: [Choice('Low', 1), Choice('High', 10)],
        );

        expect(option.type, CommandOptionType.integer);
        expect(option.choices, hasLength(2));
      });

      test('toJson serializes integer choices', () {
        final option = ChoiceOption.integer(
          name: 'level',
          description: 'Pick',
          choices: [Choice('Low', 1), Choice('High', 10)],
        );

        final json = option.toJson();
        expect(json['choices'][0]['value'], 1);
        expect(json['choices'][1]['value'], 10);
      });
    });

    group('ChoiceOption.double', () {
      test('creates double choice option', () {
        final option = ChoiceOption.double(
          name: 'multiplier',
          description: 'Pick a multiplier',
          choices: [Choice('Half', 0.5), Choice('Double', 2.0)],
        );

        expect(option.type, CommandOptionType.double);
        expect(option.choices, hasLength(2));
      });

      test('toJson serializes double choices', () {
        final option = ChoiceOption.double(
          name: 'mult',
          description: 'Pick',
          choices: [Choice('Half', 0.5)],
        );

        final json = option.toJson();
        expect(json['choices'][0]['value'], 0.5);
      });
    });
  });

  group('Choice', () {
    test('stores name and value', () {
      final choice = Choice('Red', 'red');
      expect(choice.name, 'Red');
      expect(choice.value, 'red');
    });

    test('supports generic types', () {
      final stringChoice = Choice<String>('Name', 'value');
      final intChoice = Choice<int>('Count', 42);
      final doubleChoice = Choice<double>('Ratio', 1.5);

      expect(stringChoice.value, isA<String>());
      expect(intChoice.value, isA<int>());
      expect(doubleChoice.value, isA<double>());
    });
  });
}
