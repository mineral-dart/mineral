import 'package:mineral/src/infrastructure/services/http/type/response_code.dart';
import 'package:test/test.dart';

void main() {
  group('ResponseCode', () {
    test('every enum value has a non-empty message', () {
      for (final code in ResponseCode.values) {
        expect(
          code.message,
          isNotEmpty,
          reason: '${code.name} should have a message',
        );
      }
    });

    group('specific codes', () {
      test('success is 200', () {
        expect(ResponseCode.success.code, 200);
      });

      test('created is 201', () {
        expect(ResponseCode.created.code, 201);
      });

      test('accepted is 202', () {
        expect(ResponseCode.accepted.code, 202);
      });

      test('noContent is 204', () {
        expect(ResponseCode.noContent.code, 204);
      });

      test('badRequest is 400', () {
        expect(ResponseCode.badRequest.code, 400);
      });

      test('unauthorized is 401', () {
        expect(ResponseCode.unauthorized.code, 401);
      });

      test('forbidden is 403', () {
        expect(ResponseCode.forbidden.code, 403);
      });

      test('notFound is 404', () {
        expect(ResponseCode.notFound.code, 404);
      });

      test('rateLimit is 429', () {
        expect(ResponseCode.rateLimit.code, 429);
      });

      test('internalServerError is 500', () {
        expect(ResponseCode.internalServerError.code, 500);
      });

      test('unknown is 0', () {
        expect(ResponseCode.unknown.code, 0);
      });
    });

    group('errorsCodes', () {
      test('contains expected error codes', () {
        final errorCodeValues = ResponseCode.errorsCodes
            .map((e) => e.code)
            .toList();

        expect(errorCodeValues, contains(400));
        expect(errorCodeValues, contains(401));
        expect(errorCodeValues, contains(403));
        expect(errorCodeValues, contains(404));
        expect(errorCodeValues, contains(405));
        expect(errorCodeValues, contains(500));
        expect(errorCodeValues, contains(502));
        expect(errorCodeValues, contains(503));
        expect(errorCodeValues, contains(504));
        expect(errorCodeValues, contains(0));
      });

      test('does not contain success codes', () {
        final errorCodeValues = ResponseCode.errorsCodes
            .map((e) => e.code)
            .toList();

        expect(errorCodeValues, isNot(contains(200)));
        expect(errorCodeValues, isNot(contains(201)));
        expect(errorCodeValues, isNot(contains(204)));
      });

      test('does not contain rate limit code', () {
        final errorCodeValues = ResponseCode.errorsCodes
            .map((e) => e.code)
            .toList();
        expect(errorCodeValues, isNot(contains(429)));
      });
    });

    group('successCodes', () {
      test('contains expected success codes', () {
        final successCodeValues = ResponseCode.successCodes
            .map((e) => e.code)
            .toList();

        expect(successCodeValues, contains(200));
        expect(successCodeValues, contains(201));
        expect(successCodeValues, contains(202));
        expect(successCodeValues, contains(204));
      });

      test('has exactly 4 success codes', () {
        expect(ResponseCode.successCodes, hasLength(4));
      });

      test('does not contain error codes', () {
        final successCodeValues = ResponseCode.successCodes
            .map((e) => e.code)
            .toList();

        expect(successCodeValues, isNot(contains(400)));
        expect(successCodeValues, isNot(contains(500)));
      });
    });

    group('rateLimitCodes', () {
      test('contains 429', () {
        final rateLimitValues = ResponseCode.rateLimitCodes
            .map((e) => e.code)
            .toList();
        expect(rateLimitValues, contains(429));
      });

      test('has exactly 1 rate limit code', () {
        expect(ResponseCode.rateLimitCodes, hasLength(1));
      });
    });

    group('toString', () {
      test('returns formatted string', () {
        expect(
          ResponseCode.success.toString(),
          'ResponseCode: 200 - The request is passed with success',
        );
      });
    });
  });
}
