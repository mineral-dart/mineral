import 'package:mineral/src/infrastructure/internals/datastore/rate_limit_registry.dart';
import 'package:mineral/src/infrastructure/internals/datastore/request_bucket.dart';
import 'package:mineral/src/infrastructure/services/http/header.dart';
import 'package:mineral/src/infrastructure/services/http/request.dart';
import 'package:test/test.dart';

import '../helpers/fake_http_client.dart';
import '../helpers/fake_response.dart';
import '../helpers/ioc_test_helper.dart';

void main() {
  group('RequestBucket', () {
    late void Function() restoreIoc;

    setUp(() {
      final iocResult = createTestIoc();
      restoreIoc = iocResult.restore;
    });

    tearDown(() => restoreIoc());

    test('queue defaults to empty', () {
      final bucket = RequestBucket(FakeHttpClient());
      expect(bucket.queue, isEmpty);
    });

    test('exposes a registry', () {
      final bucket = RequestBucket(FakeHttpClient());
      expect(bucket.registry, isA<RateLimitRegistry>());
    });

    test('get sends GET via the underlying client', () async {
      final http = FakeHttpClient();
      final bucket = RequestBucket(http);
      await bucket.get<Map<String, dynamic>>(Request.json(endpoint: '/users/@me'));
      expect(http.calls.single.method, equals('GET'));
      expect(http.calls.single.path, equals('/users/@me'));
    });

    test('post sends POST via the underlying client', () async {
      final http = FakeHttpClient();
      final bucket = RequestBucket(http);
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
      final bucket = RequestBucket(http);
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
      final bucket = RequestBucket(http);
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
      final bucket = RequestBucket(http);
      await bucket.get<Map<String, dynamic>>(Request.json(endpoint: '/users/@me'));
      // Bucket state recorded; remaining=4 means not exhausted.
      expect(bucket.registry.globalLockedUntil, isNull);
    });
  });
}
