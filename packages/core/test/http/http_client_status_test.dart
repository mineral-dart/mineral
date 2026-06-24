import 'package:mineral/src/infrastructure/services/http/http_client_status.dart';
import 'package:test/test.dart';

void main() {
  group('HttpClientStatusImpl', () {
    final status = HttpClientStatusImpl();

    group('isError', () {
      test('returns true for 400 Bad Request', () {
        expect(status.isError(400), isTrue);
      });

      test('returns true for 401 Unauthorized', () {
        expect(status.isError(401), isTrue);
      });

      test('returns true for 403 Forbidden', () {
        expect(status.isError(403), isTrue);
      });

      test('returns true for 404 Not Found', () {
        expect(status.isError(404), isTrue);
      });

      test('returns true for 405 Method Not Allowed', () {
        expect(status.isError(405), isTrue);
      });

      test('returns true for 500 Internal Guild Error', () {
        expect(status.isError(500), isTrue);
      });

      test('returns true for 502 Bad Gateway', () {
        expect(status.isError(502), isTrue);
      });

      test('returns true for 503 Service Unavailable', () {
        expect(status.isError(503), isTrue);
      });

      test('returns true for 504 Gateway Timeout', () {
        expect(status.isError(504), isTrue);
      });

      test('returns false for 200 OK', () {
        expect(status.isError(200), isFalse);
      });

      test('returns false for 201 Created', () {
        expect(status.isError(201), isFalse);
      });

      test('returns false for 429 Rate Limit', () {
        expect(status.isError(429), isFalse);
      });
    });

    group('isSuccess', () {
      test('returns true for 200 OK', () {
        expect(status.isSuccess(200), isTrue);
      });

      test('returns true for 201 Created', () {
        expect(status.isSuccess(201), isTrue);
      });

      test('returns true for 202 Accepted', () {
        expect(status.isSuccess(202), isTrue);
      });

      test('returns true for 204 No Content', () {
        expect(status.isSuccess(204), isTrue);
      });

      test('returns false for 400 Bad Request', () {
        expect(status.isSuccess(400), isFalse);
      });

      test('returns false for 500 Internal Guild Error', () {
        expect(status.isSuccess(500), isFalse);
      });

      test('returns false for 429 Rate Limit', () {
        expect(status.isSuccess(429), isFalse);
      });
    });

    group('isRateLimit', () {
      test('returns true for 429', () {
        expect(status.isRateLimit(429), isTrue);
      });

      test('returns false for 200', () {
        expect(status.isRateLimit(200), isFalse);
      });

      test('returns false for 400', () {
        expect(status.isRateLimit(400), isFalse);
      });

      test('returns false for 500', () {
        expect(status.isRateLimit(500), isFalse);
      });
    });
  });
}
