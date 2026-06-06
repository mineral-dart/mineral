import 'package:mineral/src/api/common/commands/command_option.dart';
import 'package:mineral/src/domains/commands/command_registration.dart';
import 'package:mineral/src/domains/commands/command_result.dart';
import 'package:test/test.dart';

void main() {
  group('CommandResult', () {
    test('CommandSuccess is a CommandResult', () {
      const result = CommandSuccess();
      expect(result, isA<CommandResult>());
    });

    test('CommandFailure carries error details', () {
      final failure = CommandFailure(
        commandName: 'ban',
        error: Exception('test error'),
        stackTrace: StackTrace.current,
      );
      expect(failure.commandName, 'ban');
      expect(failure.error, isA<Exception>());
      expect(failure.toString(), contains('ban'));
    });

    test('CommandFailure is a CommandResult', () {
      final failure = CommandFailure(
        commandName: 'test',
        error: 'error',
        stackTrace: StackTrace.current,
      );
      expect(failure, isA<CommandResult>());
    });
  });

  group('CommandRegistration', () {
    test('stores handler and options', () {
      void handler(ctx, options) {}
      final registration = CommandRegistration(
        name: 'test',
        handler: handler,
        declaredOptions: [
          Option.string(name: 'reason', description: 'Reason', required: true),
        ],
      );

      expect(registration.name, 'test');
      expect(registration.handler, handler);
      expect(registration.declaredOptions, hasLength(1));
      expect(registration.declaredOptions.first.name, 'reason');
      expect(registration.declaredOptions.first.isRequired, isTrue);
    });

    test('stores empty options list', () {
      final registration = CommandRegistration(
        name: 'ping',
        handler: (ctx, options) {},
        declaredOptions: [],
      );

      expect(registration.declaredOptions, isEmpty);
    });
  });
}
