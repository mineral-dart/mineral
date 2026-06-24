import 'package:mineral/src/api/common/commands/command_context_type.dart';
import 'package:mineral/src/api/common/commands/command_option_type.dart';
import 'package:mineral/src/api/common/commands/command_type.dart';
import 'package:test/test.dart';

void main() {
  group('CommandOptionType', () {
    test('string has value 3', () {
      expect(CommandOptionType.string.value, 3);
    });

    test('integer has value 4', () {
      expect(CommandOptionType.integer.value, 4);
    });

    test('boolean has value 5', () {
      expect(CommandOptionType.boolean.value, 5);
    });

    test('user has value 6', () {
      expect(CommandOptionType.user.value, 6);
    });

    test('channel has value 7', () {
      expect(CommandOptionType.channel.value, 7);
    });

    test('role has value 8', () {
      expect(CommandOptionType.role.value, 8);
    });

    test('mentionable has value 9', () {
      expect(CommandOptionType.mentionable.value, 9);
    });

    test('double has value 10', () {
      expect(CommandOptionType.double.value, 10);
    });

    test('attachment has value 11', () {
      expect(CommandOptionType.attachment.value, 11);
    });

    test('has 10 values total', () {
      expect(CommandOptionType.values, hasLength(10));
    });

    test('all values have unique int values', () {
      final values = CommandOptionType.values.map((e) => e.value).toSet();
      expect(values, hasLength(CommandOptionType.values.length));
    });
  });

  group('CommandType', () {
    test('subCommand has value 1', () {
      expect(CommandType.subCommand.value, 1);
    });

    test('subCommandGroup has value 2', () {
      expect(CommandType.subCommandGroup.value, 2);
    });

    test('has 3 values total', () {
      expect(CommandType.values, hasLength(3));
    });
  });

  group('CommandContextType', () {
    test('guild has value 0', () {
      expect(CommandContextType.guild.value, 0);
    });

    test('global has value 1', () {
      expect(CommandContextType.global.value, 1);
    });

    test('has 2 values total', () {
      expect(CommandContextType.values, hasLength(2));
    });
  });
}
