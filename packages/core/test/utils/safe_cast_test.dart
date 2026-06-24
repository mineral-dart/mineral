import 'package:mineral/src/domains/common/utils/safe_cast.dart';
import 'package:mineral/src/infrastructure/io/exceptions/serialization_exception.dart';
import 'package:test/test.dart';

void main() {
  group('safeCast', () {
    test('returns value when type matches', () {
      expect(safeCast<String>('hello', context: 't'), 'hello');
      expect(safeCast<int>(42, context: 't'), 42);
      expect(safeCast<List<int>>([1, 2, 3], context: 't'), [1, 2, 3]);
    });

    test('throws SerializationException when type mismatches', () {
      expect(
        () => safeCast<String>(42, context: 'test field'),
        throwsA(
          isA<SerializationException>().having(
            (e) => e.message,
            'message',
            contains('test field'),
          ),
        ),
      );
    });

    test('throws SerializationException for null when T is non-nullable', () {
      expect(
        () => safeCast<String>(null, context: 'nullable check'),
        throwsA(isA<SerializationException>()),
      );
    });

    test('accepts null when T is nullable', () {
      expect(safeCast<String?>(null, context: 't'), isNull);
    });
  });
}
