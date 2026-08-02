import 'dart:async';

import 'package:mineral/api.dart';
import 'package:test/test.dart';

void main() {
  group('MessageCommandBuilder', () {
    test('toJson emits CommandKind.message (type=3) and name', () {
      final builder = MessageCommandBuilder()..setName('Report message');

      final json = builder.toJson();

      expect(json['type'], equals(CommandKind.message.value));
      expect(json['type'], equals(3));
      expect(json['name'], equals('Report message'));
    });

    test('toJson throws when name is missing', () {
      expect(
        () => MessageCommandBuilder().toJson(),
        throwsA(isA<MissingPropertyException>()),
      );
    });

    test('setName throws when name is empty', () {
      expect(
        () => MessageCommandBuilder().setName(''),
        throwsA(isA<CommandNameException>()),
      );
    });

    test('setName throws when name exceeds 32 characters', () {
      expect(
        () => MessageCommandBuilder().setName('A' * 33),
        throwsA(isA<CommandNameException>()),
      );
    });

    test('setName accepts spaces and mixed case (unlike chat_input)', () {
      final builder = MessageCommandBuilder()..setName('Report Message');
      expect(builder.name, equals('Report Message'));
    });

    test('default context is guild', () {
      final builder = MessageCommandBuilder();
      expect(builder.context, equals(CommandContextType.guild));
    });

    test('setContext mutates context', () {
      final builder = MessageCommandBuilder()
        ..setContext(CommandContextType.global);
      expect(builder.context, equals(CommandContextType.global));
    });

    group('reduceHandlers', () {
      test('returns a single registration for the command name', () {
        FutureOr<void> handler(
          MessageCommandContext ctx,
          CommandOptions options,
        ) {}
        final builder = MessageCommandBuilder()
          ..setName('Report message')
          ..setHandle(handler);

        final registrations = builder.reduceHandlers();

        expect(registrations, hasLength(1));
        expect(registrations.first.name, 'Report message');
        expect(registrations.first.handler, handler);
        expect(registrations.first.declaredOptions, isEmpty);
      });

      test('throws InvalidCommandException naming the command when no '
          'handler is set', () {
        final builder = MessageCommandBuilder()..setName('Report message');

        expect(
          builder.reduceHandlers,
          throwsA(
            isA<InvalidCommandException>().having(
              (e) => e.message,
              'message',
              contains('Report message'),
            ),
          ),
        );
      });
    });

    group('declaration', () {
      test('is null (message commands have no option tree)', () {
        final builder = MessageCommandBuilder()..setName('Report message');
        expect(builder.declaration, isNull);
      });
    });
  });
}
