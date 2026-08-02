import 'dart:async';

import 'package:mineral/api.dart';
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
      expect(
        () => UserCommandBuilder().toJson(),
        throwsA(isA<MissingPropertyException>()),
      );
    });

    test('setName throws when name is empty', () {
      expect(
        () => UserCommandBuilder().setName(''),
        throwsA(isA<CommandNameException>()),
      );
    });

    test('setName throws when name exceeds 32 characters', () {
      expect(
        () => UserCommandBuilder().setName('A' * 33),
        throwsA(isA<CommandNameException>()),
      );
    });

    test('setName accepts spaces and mixed case (unlike chat_input)', () {
      final builder = UserCommandBuilder()..setName('Get User Info');
      expect(builder.name, equals('Get User Info'));
    });

    test('default context is guild', () {
      final builder = UserCommandBuilder();
      expect(builder.context, equals(CommandContextType.guild));
    });

    test('setContext mutates context', () {
      final builder = UserCommandBuilder()
        ..setContext(CommandContextType.global);
      expect(builder.context, equals(CommandContextType.global));
    });

    group('reduceHandlers', () {
      test('returns a single registration for the command name', () {
        FutureOr<void> handler(
          UserCommandContext ctx,
          CommandOptions options,
        ) {}
        final builder = UserCommandBuilder()
          ..setName('Get user info')
          ..setHandle(handler);

        final registrations = builder.reduceHandlers();

        expect(registrations, hasLength(1));
        expect(registrations.first.name, 'Get user info');
        expect(registrations.first.handler, handler);
        expect(registrations.first.declaredOptions, isEmpty);
      });

      test('throws InvalidCommandException naming the command when no '
          'handler is set', () {
        final builder = UserCommandBuilder()..setName('Get user info');

        expect(
          builder.reduceHandlers,
          throwsA(
            isA<InvalidCommandException>().having(
              (e) => e.message,
              'message',
              contains('Get user info'),
            ),
          ),
        );
      });
    });

    group('declaration', () {
      test('is null (user commands have no option tree)', () {
        final builder = UserCommandBuilder()..setName('Get user info');
        expect(builder.declaration, isNull);
      });
    });
  });
}
