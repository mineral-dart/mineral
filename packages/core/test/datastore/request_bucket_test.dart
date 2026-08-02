import 'dart:async';

// `Header` is hidden: `domains/services/http/http.dart` (re-exported here)
// declares its own contract-level `Header` class distinct from the
// concrete `infrastructure/services/http/header.dart` one this file needs
// to build `X-RateLimit-*` headers for [RateLimitRegistry.updateFromHeaders].
import 'package:mineral/services.dart' hide Header;
import 'package:mineral/src/infrastructure/internals/datastore/rate_limit_registry.dart';
import 'package:mineral/src/infrastructure/internals/datastore/request_bucket.dart';
import 'package:mineral/src/infrastructure/internals/datastore/route_key.dart';
import 'package:mineral/src/infrastructure/services/http/header.dart';
import 'package:mineral/src/testing/fake_logger.dart';
import 'package:test/test.dart';

import '../helpers/fake_http_client.dart';
import '../helpers/fake_response.dart';

/// A [HttpClientContract] whose responses are gated on [Completer]s the
/// test controls explicitly, so genuinely concurrent dispatch can be
/// observed and released independently of real network timing (A24).
///
/// Unlike [FakeHttpClient], calls to [get]/[post]/etc. never resolve on
/// their own — the test must call [completeNext] to release each one in
/// turn. This is what makes it possible to drive concurrent requests
/// "without awaiting the first", per the regression requirement: a test
/// that awaits each call sequentially can never observe a thundering herd.
final class _GatedHttpClient implements HttpClientContract {
  final List<Completer<Response<Map<String, dynamic>>>> _gates = [];

  /// Records `METHOD path` for every call that actually reached the
  /// client, in dispatch order.
  final List<String> calls = [];

  @override
  HttpClientStatus get status => HttpClientStatusImpl();

  @override
  HttpInterceptor get interceptor => HttpInterceptorImpl();

  @override
  HttpClientConfig get config => throw UnimplementedError();

  Future<Response<T>> _dispatch<T>(String method, RequestContract request) {
    calls.add('$method ${request.url.path}');
    final completer = Completer<Response<Map<String, dynamic>>>();
    _gates.add(completer);
    return completer.future.then((response) => response as Response<T>);
  }

  /// Completes the [index]th dispatched call (in the order it reached the
  /// client) with [statusCode] and optional rate-limit [headers].
  void completeNext(
    int index,
    int statusCode, {
    Set<Header> headers = const {},
  }) {
    _gates[index].complete(
      FakeResponse<Map<String, dynamic>>(
        statusCode,
        const <String, dynamic>{},
        bodyString: '{}',
        headers: headers,
      ),
    );
  }

  @override
  Future<Response<T>> get<T>(RequestContract r) => _dispatch<T>('GET', r);

  @override
  Future<Response<T>> post<T>(RequestContract r) => _dispatch<T>('POST', r);

  @override
  Future<Response<T>> put<T>(RequestContract r) => _dispatch<T>('PUT', r);

  @override
  Future<Response<T>> patch<T>(RequestContract r) => _dispatch<T>('PATCH', r);

  @override
  Future<Response<T>> delete<T>(RequestContract r) => _dispatch<T>('DELETE', r);

  @override
  Future<Response<T>> send<T>(RequestContract r) =>
      _dispatch<T>(r.method ?? 'SEND', r);
}

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
      await bucket.get<Map<String, dynamic>>(
        Request.json(endpoint: '/users/@me'),
      );
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
        FakeResponse<Map<String, dynamic>>(429, const {
          'global': false,
          'retry_after': 0.0,
        }, bodyString: '{"global":false,"retry_after":0.0}'),
        FakeResponse.ok(),
      ]);
      final bucket = RequestBucket(http, logger: logger);
      await bucket.get<Map<String, dynamic>>(Request.json(endpoint: '/foo'));
      expect(http.calls, hasLength(2));
    });

    test('global 429 sets registry global lock', () async {
      final http = FakeHttpClient([
        FakeResponse<Map<String, dynamic>>(429, const {
          'global': true,
          'retry_after': 0.0,
        }, bodyString: '{"global":true,"retry_after":0.0}'),
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
      await bucket.get<Map<String, dynamic>>(
        Request.json(endpoint: '/users/@me'),
      );
      // Bucket state recorded; remaining=4 means not exhausted.
      expect(bucket.registry.globalLockedUntil, isNull);
    });

    test(
      '429 on webhook route logs redacted token, not the raw credential',
      () async {
        const webhookToken = 'supersecretwebhooktoken';
        const webhookId = '111111111111111111';
        final http = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(429, const {
            'global': false,
            'retry_after': 0.0,
          }, bodyString: '{"global":false,"retry_after":0.0}'),
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
      },
    );

    test(
      '429 on interaction route logs redacted token, not the raw credential',
      () async {
        const interactionToken = 'supersecretinteractiontoken';
        const interactionId = '222222222222222222';
        final http = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(429, const {
            'global': false,
            'retry_after': 0.0,
          }, bodyString: '{"global":false,"retry_after":0.0}'),
          FakeResponse.ok(),
        ]);
        final bucket = RequestBucket(http, logger: logger);
        await bucket.post<Map<String, dynamic>>(
          Request.json(
            endpoint: '/interactions/$interactionId/$interactionToken',
          ),
        );

        expect(logger.warnings, hasLength(1));
        final logLine = logger.warnings.single;
        expect(logLine, isNot(contains(interactionToken)));
        expect(logLine, contains('***'));
      },
    );

    test('429 on normal route logs full route without masking', () async {
      final http = FakeHttpClient([
        FakeResponse<Map<String, dynamic>>(429, const {
          'global': false,
          'retry_after': 0.0,
        }, bodyString: '{"global":false,"retry_after":0.0}'),
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

    group('unclassified statuses fail fast instead of retrying (#465)', () {
      test('409 completes with an error on the first attempt', () async {
        final http = FakeHttpClient([409]);
        final bucket = RequestBucket(http, logger: logger);

        await expectLater(
          bucket.post<Map<String, dynamic>>(
            Request.json(endpoint: '/channels/1/messages'),
          ),
          throwsA(anything),
        );

        expect(http.calls, hasLength(1));
      });

      test('413 does not re-send the request', () async {
        final http = FakeHttpClient([413]);
        final bucket = RequestBucket(http, logger: logger);

        await expectLater(
          bucket.post<Map<String, dynamic>>(
            Request.json(endpoint: '/channels/1/messages'),
          ),
          throwsA(anything),
        );

        expect(http.calls, hasLength(1));
      });

      test('304 does not re-send the request', () async {
        final http = FakeHttpClient([304]);
        final bucket = RequestBucket(http, logger: logger);

        await expectLater(
          bucket.get<Map<String, dynamic>>(Request.json(endpoint: '/foo')),
          throwsA(anything),
        );

        expect(http.calls, hasLength(1));
      });

      test('the error message names the actual status (409)', () async {
        final http = FakeHttpClient([409]);
        final bucket = RequestBucket(http, logger: logger);

        await expectLater(
          bucket.post<Map<String, dynamic>>(
            Request.json(endpoint: '/channels/1/messages'),
          ),
          throwsA(predicate((e) => e.toString().contains('409'))),
        );
      });

      test('does not misreport a 409 as a rate-limit error', () async {
        final http = FakeHttpClient([409]);
        final bucket = RequestBucket(http, logger: logger);

        await expectLater(
          bucket.post<Map<String, dynamic>>(
            Request.json(endpoint: '/channels/1/messages'),
          ),
          throwsA(
            predicate(
              (e) => !e.toString().toLowerCase().contains('rate limit'),
            ),
          ),
        );
      });

      test(
        'removes the queue entry after an unclassified status fails',
        () async {
          final http = FakeHttpClient([409]);
          final bucket = RequestBucket(http, logger: logger);

          await bucket
              .post<Map<String, dynamic>>(
                Request.json(endpoint: '/channels/1/messages'),
              )
              .catchError((_) => <String, dynamic>{});

          expect(bucket.queue, isEmpty);
        },
      );
    });

    group('in-flight accounting under concurrency (A24)', () {
      test('ten concurrent requests on a remaining:1 bucket produce exactly '
          'one dispatch; the other nine wait instead of firing '
          '(interleaving 1)', () async {
        final http = _GatedHttpClient();
        final bucket = RequestBucket(http, logger: logger);
        const path = '/channels/111111111111111111/messages';
        final route = RouteKey('GET', path);

        bucket.registry.updateFromHeaders(route, {
          Header('X-RateLimit-Bucket', 'burst-bucket'),
          Header('X-RateLimit-Limit', '1'),
          Header('X-RateLimit-Remaining', '1'),
          // Long window: the nine losers must not accidentally fire
          // during this test's real-time execution.
          Header('X-RateLimit-Reset-After', '60'),
        });

        final futures = <Future<Map<String, dynamic>>>[
          for (var i = 0; i < 10; i++)
            bucket.get<Map<String, dynamic>>(Request.json(endpoint: path)),
        ];

        // Deliberately not awaited above: firing all ten without
        // awaiting the first is what makes this a real concurrency
        // test rather than a sequential one that proves nothing.

        // Let every synchronous/microtask step of all ten calls settle
        // without advancing real time — at this point none of them
        // should still be deciding, only (at most) one dispatching and
        // the rest asleep on the bucket.
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(
          http.calls,
          hasLength(1),
          reason:
              'only one of the ten concurrent requests should have '
              'reached the HTTP client; the rest must be waiting on the '
              'bucket instead of racing the same stale "remaining" '
              'value',
        );

        http.completeNext(0, 200);
        await futures[0];
      });

      test(
        'requests queued on an exhausted bucket drain one at a time at '
        'reset instead of all resuming in the same drain (interleaving 2)',
        () async {
          final http = _GatedHttpClient();
          final bucket = RequestBucket(http, logger: logger);
          const path = '/channels/222222222222222222/messages';
          final route = RouteKey('GET', path);

          Set<Header> headers() => {
            Header('X-RateLimit-Bucket', 'drain-bucket'),
            Header('X-RateLimit-Limit', '1'),
            Header('X-RateLimit-Remaining', '0'),
            Header('X-RateLimit-Reset-After', '0.05'),
          };

          bucket.registry.updateFromHeaders(route, headers());

          final futures = <Future<Map<String, dynamic>>>[
            for (var i = 0; i < 3; i++)
              bucket.get<Map<String, dynamic>>(Request.json(endpoint: path)),
          ];

          await Future<void>.delayed(Duration.zero);
          expect(
            http.calls,
            isEmpty,
            reason: 'bucket was seeded already exhausted',
          );

          await Future<void>.delayed(const Duration(milliseconds: 80));
          expect(
            http.calls,
            hasLength(1),
            reason:
                'exactly one queued request should drain at the reset '
                'instant, not all three resuming in the same drain',
          );

          http.completeNext(0, 200, headers: headers());
          await Future<void>.delayed(const Duration(milliseconds: 80));
          expect(http.calls, hasLength(2));

          http.completeNext(1, 200, headers: headers());
          await Future<void>.delayed(const Duration(milliseconds: 80));
          expect(http.calls, hasLength(3));

          http.completeNext(2, 200, headers: headers());
          await Future.wait(futures);
        },
      );
    });
  });
}
