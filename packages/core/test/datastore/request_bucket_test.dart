import 'package:mineral/src/infrastructure/internals/datastore/rate_limit_registry.dart';
import 'package:mineral/src/infrastructure/internals/datastore/request_bucket.dart';
import 'package:mineral/src/infrastructure/services/http/header.dart';
import 'package:mineral/src/infrastructure/services/http/request.dart';
import 'package:mineral/src/testing/fake_logger.dart';
import 'package:test/test.dart';

import '../helpers/fake_http_client.dart';
import '../helpers/fake_response.dart';

void main() {
  group('RequestBucket', () {
    late FakeLogger logger;

    setUp(() {
      logger = FakeLogger();
    });

    test('queue defaults to empty', () {
      final bucket = RequestBucket(FakeHttpClient(), logger: logger);
      expect(bucket.queue, isEmpty);
    });

    test('exposes a registry', () {
      final bucket = RequestBucket(FakeHttpClient(), logger: logger);
      expect(bucket.registry, isA<RateLimitRegistry>());
    });

    test('get sends GET via the underlying client', () async {
      final http = FakeHttpClient();
      final bucket = RequestBucket(http, logger: logger);
      await bucket.get<Map<String, dynamic>>(Request.json(endpoint: '/users/@me'));
      expect(http.calls.single.method, equals('GET'));
      expect(http.calls.single.path, equals('/users/@me'));
    });

    test('post sends POST via the underlying client', () async {
      final http = FakeHttpClient();
      final bucket = RequestBucket(http, logger: logger);
      await bucket.post<Map<String, dynamic>>(Request.json(endpoint: '/x'));
      expect(http.calls.single.method, equals('POST'));
    });

    test('honours retry_after on 429 then completes', () async {
      final http = FakeHttpClient([
        FakeResponse<Map<String, dynamic>>(
          429,
          const {'global': false, 'retry_after': 0.0},
          bodyString: '{"global":false,"retry_after":0.0}',
        ),
        FakeResponse.ok(),
      ]);
      final bucket = RequestBucket(http, logger: logger);
      await bucket.get<Map<String, dynamic>>(Request.json(endpoint: '/foo'));
      expect(http.calls, hasLength(2));
    });

    test('global 429 sets registry global lock', () async {
      final http = FakeHttpClient([
        FakeResponse<Map<String, dynamic>>(
          429,
          const {'global': true, 'retry_after': 0.0},
          bodyString: '{"global":true,"retry_after":0.0}',
        ),
        FakeResponse.ok(),
      ]);
      final bucket = RequestBucket(http, logger: logger);
      await bucket.get<Map<String, dynamic>>(Request.json(endpoint: '/foo'));
      expect(bucket.registry.globalLockedUntil, isNotNull);
    });

    test('learns bucket from response headers on success', () async {
      final headers = <Header>{
        Header('X-RateLimit-Bucket', 'abc123'),
        Header('X-RateLimit-Limit', '5'),
        Header('X-RateLimit-Remaining', '4'),
        Header('X-RateLimit-Reset-After', '1.5'),
      };
      final http = FakeHttpClient([
        FakeResponse<Map<String, dynamic>>(
          200,
          const <String, dynamic>{},
          bodyString: '{}',
          headers: headers,
        ),
      ]);
      final bucket = RequestBucket(http, logger: logger);
      await bucket.get<Map<String, dynamic>>(Request.json(endpoint: '/users/@me'));
      // Bucket state recorded; remaining=4 means not exhausted.
      expect(bucket.registry.globalLockedUntil, isNull);
    });

    test('429 on webhook route logs redacted token, not the raw credential',
        () async {
      const webhookToken = 'supersecretwebhooktoken';
      const webhookId = '111111111111111111';
      final http = FakeHttpClient([
        FakeResponse<Map<String, dynamic>>(
          429,
          const {'global': false, 'retry_after': 0.0},
          bodyString: '{"global":false,"retry_after":0.0}',
        ),
        FakeResponse.ok(),
      ]);
      final bucket = RequestBucket(http, logger: logger);
      await bucket.post<Map<String, dynamic>>(
        Request.json(endpoint: '/webhooks/$webhookId/$webhookToken'),
      );

      expect(logger.warnings, hasLength(1));
      final logLine = logger.warnings.single;
      // Token must not appear in the log
      expect(logLine, isNot(contains(webhookToken)));
      // Redaction marker must be present
      expect(logLine, contains('***'));
      // Webhook id must still appear (it is not a secret)
      expect(logLine, contains(webhookId));
    });

    test('429 on interaction route logs redacted token, not the raw credential',
        () async {
      const interactionToken = 'supersecretinteractiontoken';
      const interactionId = '222222222222222222';
      final http = FakeHttpClient([
        FakeResponse<Map<String, dynamic>>(
          429,
          const {'global': false, 'retry_after': 0.0},
          bodyString: '{"global":false,"retry_after":0.0}',
        ),
        FakeResponse.ok(),
      ]);
      final bucket = RequestBucket(http, logger: logger);
      await bucket.post<Map<String, dynamic>>(
        Request.json(
            endpoint: '/interactions/$interactionId/$interactionToken'),
      );

      expect(logger.warnings, hasLength(1));
      final logLine = logger.warnings.single;
      expect(logLine, isNot(contains(interactionToken)));
      expect(logLine, contains('***'));
    });

    test('429 on normal route logs full route without masking', () async {
      final http = FakeHttpClient([
        FakeResponse<Map<String, dynamic>>(
          429,
          const {'global': false, 'retry_after': 0.0},
          bodyString: '{"global":false,"retry_after":0.0}',
        ),
        FakeResponse.ok(),
      ]);
      final bucket = RequestBucket(http, logger: logger);
      await bucket.get<Map<String, dynamic>>(
        Request.json(endpoint: '/channels/111111111111111111/messages'),
      );

      expect(logger.warnings, hasLength(1));
      final logLine = logger.warnings.single;
      expect(logLine, contains('channels'));
      expect(logLine, contains('messages'));
      expect(logLine, isNot(contains('***')));
    });
  });
}
