import 'package:mineral/api.dart';
import 'package:test/test.dart';

void main() {
  group('MineralException hierarchy', () {
    group('existing exceptions keep their fields', () {
      test('HttpStatusException contains status code and body', () {
        final exception = HttpStatusException(404, 'Not Found');
        expect(exception.statusCode, equals(404));
        expect(exception.body, equals('Not Found'));
        expect(exception.message, contains('404'));
        expect(exception.toString(), contains('HttpStatusException'));
      });

      test('SerializationException contains descriptive message', () {
        final exception = SerializationException(
          'Expected GuildTextChannel but got Message',
        );
        expect(exception.message, contains('GuildTextChannel'));
        expect(exception.toString(), contains('SerializationException'));
      });

      test('ServiceNotFoundException contains service type', () {
        final exception = ServiceNotFoundException(String);
        expect(exception.serviceType, equals(String));
        expect(exception.message, contains('String'));
        expect(exception.toString(), contains('ServiceNotFoundException'));
      });

      test('ServiceNotFoundException message is actionable', () {
        final exception = ServiceNotFoundException(String);
        expect(exception.message, contains('bind'));
      });

      test('InvalidCommandException contains descriptive message', () {
        final exception = InvalidCommandException(
          'Command /hello already exists',
        );
        expect(exception.message, contains('/hello'));
        expect(exception.toString(), contains('InvalidCommandException'));
      });

      test('InvalidComponentException contains descriptive message', () {
        final exception = InvalidComponentException(
          'Component "my-button" not found',
        );
        expect(exception.message, contains('my-button'));
        expect(exception.toString(), contains('InvalidComponentException'));
      });

      test('FatalGatewayException contains code and message', () {
        final exception = FatalGatewayException('auth failed', 4004);
        expect(exception.code, equals(4004));
        expect(exception.message, contains('4004'));
        expect(exception.message, contains('auth failed'));
        expect(exception.toString(), contains('FatalGatewayException'));
      });
    });

    group('sealed hierarchy — all are MineralException', () {
      test('recoverable exceptions', () {
        expect(HttpStatusException(500, ''), isA<MineralException>());
        expect(SerializationException(''), isA<MineralException>());
        expect(ServiceNotFoundException(String), isA<MineralException>());
        expect(InvalidCommandException(''), isA<MineralException>());
        expect(InvalidComponentException(''), isA<MineralException>());
        expect(MissingPropertyException(''), isA<MineralException>());
        expect(MissingMethodException(''), isA<MineralException>());
        expect(TooManyElementException(''), isA<MineralException>());
        expect(CommandNameException(''), isA<MineralException>());
      });

      test('fatal exceptions', () {
        expect(FatalGatewayException('', -1), isA<MineralException>());
        expect(TokenException(''), isA<MineralException>());
      });
    });

    group('sealed hierarchy — Recoverable vs Fatal', () {
      test('recoverable exceptions extend RecoverableMineralException', () {
        expect(
          HttpStatusException(500, ''),
          isA<RecoverableMineralException>(),
        );
        expect(SerializationException(''), isA<RecoverableMineralException>());
        expect(
          ServiceNotFoundException(String),
          isA<RecoverableMineralException>(),
        );
        expect(InvalidCommandException(''), isA<RecoverableMineralException>());
        expect(
          InvalidComponentException(''),
          isA<RecoverableMineralException>(),
        );
        expect(
          MissingPropertyException(''),
          isA<RecoverableMineralException>(),
        );
        expect(MissingMethodException(''), isA<RecoverableMineralException>());
        expect(TooManyElementException(''), isA<RecoverableMineralException>());
        expect(CommandNameException(''), isA<RecoverableMineralException>());
      });

      test('fatal exceptions extend FatalMineralException', () {
        expect(FatalGatewayException('', -1), isA<FatalMineralException>());
        expect(TokenException(''), isA<FatalMineralException>());
      });

      test('recoverable exceptions are NOT fatal', () {
        expect(
          InvalidCommandException(''),
          isNot(isA<FatalMineralException>()),
        );
        expect(SerializationException(''), isNot(isA<FatalMineralException>()));
      });

      test('fatal exceptions are NOT recoverable', () {
        expect(
          FatalGatewayException('', -1),
          isNot(isA<RecoverableMineralException>()),
        );
        expect(TokenException(''), isNot(isA<RecoverableMineralException>()));
      });
    });

    group('all exceptions implement Exception', () {
      test('recoverable exceptions implement Exception', () {
        expect(HttpStatusException(500, ''), isA<Exception>());
        expect(SerializationException(''), isA<Exception>());
        expect(ServiceNotFoundException(String), isA<Exception>());
        expect(InvalidCommandException(''), isA<Exception>());
        expect(InvalidComponentException(''), isA<Exception>());
        expect(MissingPropertyException(''), isA<Exception>());
        expect(MissingMethodException(''), isA<Exception>());
        expect(TooManyElementException(''), isA<Exception>());
        expect(CommandNameException(''), isA<Exception>());
      });

      test('fatal exceptions implement Exception', () {
        expect(FatalGatewayException('', -1), isA<Exception>());
        expect(TokenException(''), isA<Exception>());
      });
    });
  });
}
