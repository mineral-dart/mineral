import 'dart:io';

import 'package:mineral/services.dart';
import 'package:test/test.dart';

import '../helpers/fake_http_client.dart';

Request get _req => Request.json(endpoint: '/test');

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('ResilientHttpClient', () {
    group('success on first attempt', () {
      test('returns response immediately for 200', () async {
        final inner = FakeHttpClient([200]);
        final client = ResilientHttpClient(inner,
            maxRetries: 3, initialBackoff: Duration.zero);

        final response = await client.get(_req);

        expect(response.statusCode, 200);
        expect(inner.calls.length, 1);
      });

      test('returns response immediately for 201', () async {
        final inner = FakeHttpClient([201]);
        final client = ResilientHttpClient(inner,
            maxRetries: 3, initialBackoff: Duration.zero);

        final response = await client.post(_req);

        expect(response.statusCode, 201);
        expect(inner.calls.length, 1);
      });
    });

    group('retries on transient guild errors', () {
      for (final code in [500, 502, 503, 504]) {
        test('retries on $code and succeeds on next attempt', () async {
          final inner = FakeHttpClient([code, 200]);
          final client = ResilientHttpClient(inner,
              maxRetries: 3, initialBackoff: Duration.zero);

          final response = await client.get(_req);

          expect(response.statusCode, 200);
          expect(inner.calls.length, 2);
        });
      }

      test('exhausts all retries and returns last error response', () async {
        final inner = FakeHttpClient([503, 503, 503, 503]); // 1 + 3 retries
        final client = ResilientHttpClient(inner,
            maxRetries: 3, initialBackoff: Duration.zero);

        final response = await client.get(_req);

        expect(response.statusCode, 503);
        expect(inner.calls.length, 4);
      });

      test('stops after maxRetries even if errors continue', () async {
        final inner = FakeHttpClient([502, 502, 200]); // succeeds on 3rd
        final client = ResilientHttpClient(inner,
            maxRetries: 2, initialBackoff: Duration.zero);

        final response = await client.get(_req);

        expect(response.statusCode, 200);
        expect(inner.calls.length, 3);
      });
    });

    group('retries on SocketException', () {
      test('retries after SocketException and succeeds', () async {
        final inner = FakeHttpClient([
          SocketException('connection refused'),
          200,
        ]);
        final client = ResilientHttpClient(inner,
            maxRetries: 3, initialBackoff: Duration.zero);

        final response = await client.get(_req);

        expect(response.statusCode, 200);
        expect(inner.calls.length, 2);
      });

      test('rethrows SocketException after exhausting retries', () async {
        final inner = FakeHttpClient([
          SocketException('unreachable'),
          SocketException('unreachable'),
        ]);
        final client = ResilientHttpClient(inner,
            maxRetries: 1, initialBackoff: Duration.zero);

        await expectLater(client.get(_req), throwsA(isA<SocketException>()));
        expect(inner.calls.length, 2);
      });
    });

    group('does not retry non-transient errors', () {
      for (final code in [400, 401, 403, 404, 429]) {
        test('returns $code without retrying', () async {
          final inner = FakeHttpClient([code]);
          final client = ResilientHttpClient(inner,
              maxRetries: 3, initialBackoff: Duration.zero);

          final response = await client.get(_req);

          expect(response.statusCode, code);
          expect(inner.calls.length, 1);
        });
      }
    });

    group('delegates to inner client', () {
      test('delegates post()', () async {
        final inner = FakeHttpClient([201]);
        final client = ResilientHttpClient(inner, initialBackoff: Duration.zero);

        await client.post(_req);
        expect(inner.calls.length, 1);
      });

      test('delegates put()', () async {
        final inner = FakeHttpClient([200]);
        final client = ResilientHttpClient(inner, initialBackoff: Duration.zero);

        await client.put(_req);
        expect(inner.calls.length, 1);
      });

      test('delegates patch()', () async {
        final inner = FakeHttpClient([200]);
        final client = ResilientHttpClient(inner, initialBackoff: Duration.zero);

        await client.patch(_req);
        expect(inner.calls.length, 1);
      });

      test('delegates delete()', () async {
        final inner = FakeHttpClient([200]);
        final client = ResilientHttpClient(inner, initialBackoff: Duration.zero);

        await client.delete(_req);
        expect(inner.calls.length, 1);
      });

      test('exposes inner status', () {
        final inner = FakeHttpClient([]);
        final client = ResilientHttpClient(inner);
        expect(client.status, isA<HttpClientStatus>());
      });

      test('exposes inner interceptor', () {
        final inner = FakeHttpClient([]);
        final client = ResilientHttpClient(inner);
        expect(client.interceptor, isA<HttpInterceptor>());
      });
    });
  });
}
