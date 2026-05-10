import 'package:mineral/api.dart';
import 'package:mineral/src/infrastructure/io/exceptions/command_name_exception.dart';
import 'package:mineral/src/infrastructure/io/exceptions/missing_property_exception.dart';
import 'package:test/test.dart';

void main() {
  group('UserCommandBuilder', () {
    test('toJson emits CommandKind.user (type=2) and name', () {
      final builder = UserCommandBuilder()..setName('Get user info');

      final json = builder.toJson();

      expect(json['type'], equals(CommandKind.user.value));
      expect(json['type'], equals(2));
      expect(json['name'], equals('Get user info'));
    });

    test('toJson throws when name is missing', () {
      expect(() => UserCommandBuilder().toJson(),
          throwsA(isA<MissingPropertyException>()));
    });

    test('setName throws when name is empty', () {
      expect(() => UserCommandBuilder().setName(''),
          throwsA(isA<CommandNameException>()));
    });

    test('setName throws when name exceeds 32 characters', () {
      expect(() => UserCommandBuilder().setName('A' * 33),
          throwsA(isA<CommandNameException>()));
    });

    test('setName accepts spaces and mixed case (unlike chat_input)', () {
      final builder = UserCommandBuilder()..setName('Get User Info');
      expect(builder.name, equals('Get User Info'));
    });

    test('default context is server', () {
      final builder = UserCommandBuilder();
      expect(builder.context, equals(CommandContextType.server));
    });

    test('setContext mutates context', () {
      final builder = UserCommandBuilder()
        ..setContext(CommandContextType.global);
      expect(builder.context, equals(CommandContextType.global));
    });
  });
}
