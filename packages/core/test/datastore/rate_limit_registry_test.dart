import 'package:mineral/src/infrastructure/internals/datastore/rate_limit_registry.dart';
import 'package:mineral/src/infrastructure/internals/datastore/route_key.dart';
import 'package:mineral/src/infrastructure/services/http/header.dart';
import 'package:test/test.dart';

void main() {
  group('RateLimitRegistry', () {
    test('delayFor unknown route is zero', () {
      final registry = RateLimitRegistry();
      final route = RouteKey('GET', '/users/@me');
      expect(registry.delayFor(route), equals(Duration.zero));
    });

    test('learns bucket from headers', () {
      final registry = RateLimitRegistry();
      final route = RouteKey('GET', '/users/@me');
      registry.updateFromHeaders(route, {
        Header('X-RateLimit-Bucket', 'bucket-x'),
        Header('X-RateLimit-Limit', '5'),
        Header('X-RateLimit-Remaining', '3'),
        Header('X-RateLimit-Reset-After', '2.0'),
      });
      final state = registry.bucketFor(route);
      expect(state, isNotNull);
      expect(state!.id, equals('bucket-x'));
      expect(state.limit, equals(5));
      expect(state.remaining, equals(3));
    });

    test('exhausted bucket produces non-zero delay', () {
      final registry = RateLimitRegistry();
      final route = RouteKey('GET', '/users/@me');
      registry.updateFromHeaders(route, {
        Header('X-RateLimit-Bucket', 'b1'),
        Header('X-RateLimit-Limit', '1'),
        Header('X-RateLimit-Remaining', '0'),
        Header('X-RateLimit-Reset-After', '1.0'),
      });
      expect(registry.delayFor(route), greaterThan(Duration.zero));
    });

    test('headers without bucket id are ignored', () {
      final registry = RateLimitRegistry();
      final route = RouteKey('GET', '/users/@me');
      registry.updateFromHeaders(route, {Header('X-RateLimit-Limit', '5')});
      expect(registry.bucketFor(route), isNull);
    });

    test('case-insensitive header keys', () {
      final registry = RateLimitRegistry();
      final route = RouteKey('GET', '/x');
      registry.updateFromHeaders(route, {
        Header('x-ratelimit-bucket', 'b'),
        Header('x-ratelimit-remaining', '2'),
        Header('x-ratelimit-reset-after', '0.5'),
      });
      expect(registry.bucketFor(route)?.id, equals('b'));
    });

    test('lockGlobal blocks any route', () {
      final registry = RateLimitRegistry();
      final route = RouteKey('GET', '/users/@me');
      registry.lockGlobal(const Duration(seconds: 2));
      expect(registry.delayFor(route), greaterThan(Duration.zero));
      expect(registry.globalLockedUntil, isNotNull);
    });

    test('lockRoute on unknown bucket is a no-op', () {
      final registry = RateLimitRegistry();
      final route = RouteKey('GET', '/x');
      registry.lockRoute(route, const Duration(seconds: 2));
      expect(registry.delayFor(route), equals(Duration.zero));
    });

    test('lockRoute on known bucket sets remaining=0', () {
      final registry = RateLimitRegistry();
      final route = RouteKey('GET', '/x');
      registry
        ..updateFromHeaders(route, {
          Header('X-RateLimit-Bucket', 'b'),
          Header('X-RateLimit-Limit', '5'),
          Header('X-RateLimit-Remaining', '4'),
          Header('X-RateLimit-Reset-After', '1.0'),
        })
        ..lockRoute(route, const Duration(seconds: 2));
      expect(registry.bucketFor(route)?.remaining, equals(0));
      expect(registry.delayFor(route), greaterThan(Duration.zero));
    });
  });

  group('RateLimitRegistry — token-free bucketing key (A21)', () {
    test('a bucket learnt via one interaction token applies to a different '
        'token on the same interaction id — the raw token must not be part '
        'of the bucketing identity', () {
      final registry = RateLimitRegistry();
      final routeA = RouteKey(
        'POST',
        '/interactions/111111111111111111/tokenA',
      );
      final routeB = RouteKey(
        'POST',
        '/interactions/111111111111111111/tokenB',
      );

      registry.updateFromHeaders(routeA, {
        Header('X-RateLimit-Bucket', 'interaction-bucket'),
        Header('X-RateLimit-Limit', '5'),
        Header('X-RateLimit-Remaining', '3'),
        Header('X-RateLimit-Reset-After', '2.0'),
      });

      final state = registry.bucketFor(routeB);
      expect(
        state,
        isNotNull,
        reason:
            'routeB never received updateFromHeaders directly; it can '
            'only resolve to a bucket if the registry keys on a '
            'token-free identity shared with routeA',
      );
      expect(state!.id, equals('interaction-bucket'));
    });

    test('a bucket learnt via one webhook token applies to a different token '
        'on the same webhook id', () {
      final registry = RateLimitRegistry();
      final routeA = RouteKey('POST', '/webhooks/111111111111111111/tokenA');
      final routeB = RouteKey('POST', '/webhooks/111111111111111111/tokenB');

      registry.updateFromHeaders(routeA, {
        Header('X-RateLimit-Bucket', 'webhook-bucket'),
        Header('X-RateLimit-Limit', '5'),
        Header('X-RateLimit-Remaining', '3'),
        Header('X-RateLimit-Reset-After', '2.0'),
      });

      expect(registry.bucketFor(routeB)?.id, equals('webhook-bucket'));
    });

    test('different webhook ids remain distinguishable buckets — the id is '
        'kept as the major parameter, only the token is redacted', () {
      final registry = RateLimitRegistry();
      final routeA = RouteKey(
        'POST',
        '/webhooks/111111111111111111/sharedtoken',
      );
      final routeB = RouteKey(
        'POST',
        '/webhooks/222222222222222222/sharedtoken',
      );

      registry.updateFromHeaders(routeA, {
        Header('X-RateLimit-Bucket', 'webhook-a-bucket'),
        Header('X-RateLimit-Limit', '5'),
        Header('X-RateLimit-Remaining', '3'),
        Header('X-RateLimit-Reset-After', '2.0'),
      });

      expect(registry.bucketFor(routeB), isNull);
    });

    test('the registry stays bounded across many distinct interaction '
        'tokens on the same interaction id (memory assertion)', () {
      final registry = RateLimitRegistry();
      for (var i = 0; i < 500; i++) {
        final route = RouteKey(
          'POST',
          '/interactions/111111111111111111/token$i',
        );
        registry.updateFromHeaders(route, {
          Header('X-RateLimit-Bucket', 'shared-interaction-bucket'),
          Header('X-RateLimit-Limit', '5'),
          Header('X-RateLimit-Remaining', '5'),
          Header('X-RateLimit-Reset-After', '5.0'),
        });
      }

      expect(registry.trackedRouteCount, equals(1));
      expect(registry.trackedBucketCount, equals(1));
    });
  });

  group('RateLimitRegistry — bounded via eviction (A21)', () {
    test('a bucket whose resetAt is long past the grace period is evicted '
        'on the next mutation, freeing both the bucket and route entries', () {
      final registry = RateLimitRegistry(
        staleGrace: const Duration(seconds: 1),
      );
      final staleRoute = RouteKey(
        'GET',
        '/channels/111111111111111111/messages',
      );
      registry.updateFromHeaders(staleRoute, {
        Header('X-RateLimit-Bucket', 'stale-bucket'),
        Header('X-RateLimit-Limit', '5'),
        Header('X-RateLimit-Remaining', '5'),
        // Already ~100s in the past, well past the 1s grace period.
        Header('X-RateLimit-Reset-After', '-100'),
      });
      expect(registry.trackedBucketCount, equals(1));

      final freshRoute = RouteKey(
        'GET',
        '/channels/222222222222222222/messages',
      );
      registry.updateFromHeaders(freshRoute, {
        Header('X-RateLimit-Bucket', 'fresh-bucket'),
        Header('X-RateLimit-Limit', '5'),
        Header('X-RateLimit-Remaining', '5'),
        Header('X-RateLimit-Reset-After', '5.0'),
      });

      expect(
        registry.trackedBucketCount,
        equals(1),
        reason: 'the stale bucket must have been evicted',
      );
      expect(registry.bucketFor(staleRoute), isNull);
      expect(registry.bucketFor(freshRoute)?.id, equals('fresh-bucket'));
    });

    test('a fresh bucket within the grace period is not evicted', () {
      final registry = RateLimitRegistry(
        staleGrace: const Duration(minutes: 10),
      );
      final route = RouteKey('GET', '/channels/111111111111111111/messages');
      registry.updateFromHeaders(route, {
        Header('X-RateLimit-Bucket', 'b'),
        Header('X-RateLimit-Limit', '5'),
        Header('X-RateLimit-Remaining', '5'),
        Header('X-RateLimit-Reset-After', '1.0'),
      });

      final other = RouteKey('GET', '/channels/222222222222222222/messages');
      registry.updateFromHeaders(other, {
        Header('X-RateLimit-Bucket', 'b2'),
        Header('X-RateLimit-Limit', '5'),
        Header('X-RateLimit-Remaining', '5'),
        Header('X-RateLimit-Reset-After', '1.0'),
      });

      expect(registry.trackedBucketCount, equals(2));
      expect(registry.bucketFor(route)?.id, equals('b'));
    });
  });

  group('RateLimitRegistry.reserve — in-flight accounting (A24)', () {
    test('reserve consumes the last slot then blocks the next caller', () {
      final registry = RateLimitRegistry();
      final route = RouteKey('GET', '/channels/111111111111111111/messages');
      registry.updateFromHeaders(route, {
        Header('X-RateLimit-Bucket', 'b'),
        Header('X-RateLimit-Limit', '1'),
        Header('X-RateLimit-Remaining', '1'),
        Header('X-RateLimit-Reset-After', '5.0'),
      });

      expect(registry.reserve(route), equals(Duration.zero));
      expect(registry.reserve(route), greaterThan(Duration.zero));
    });

    test('reserve on a route with no learnt bucket is always immediate '
        '(first hit stays optimistic)', () {
      final registry = RateLimitRegistry();
      final route = RouteKey('GET', '/never/seen/before');
      expect(registry.reserve(route), equals(Duration.zero));
      expect(registry.reserve(route), equals(Duration.zero));
    });

    test(
      'reserve rearms exactly one slot per window once resetAt has '
      'elapsed, rather than treating an elapsed reset as unlimited',
      () async {
        final registry = RateLimitRegistry();
        final route = RouteKey('GET', '/channels/111111111111111111/messages');
        registry.updateFromHeaders(route, {
          Header('X-RateLimit-Bucket', 'b'),
          Header('X-RateLimit-Limit', '1'),
          Header('X-RateLimit-Remaining', '0'),
          Header('X-RateLimit-Reset-After', '0.05'),
        });

        // Let the 50ms window genuinely elapse in real time.
        await Future<void>.delayed(const Duration(milliseconds: 80));

        // First caller after the window elapsed rearms the bucket and
        // consumes the single slot.
        expect(registry.reserve(route), equals(Duration.zero));
        // A second caller in the same instant must not also see the
        // window as "elapsed" and get a free pass — it must wait for the
        // newly re-armed window instead of also getting Duration.zero.
        expect(registry.reserve(route), greaterThan(Duration.zero));
      },
    );

    test('a malformed/negative reset-after header does not leave the bucket '
        'permanently re-armed to the past — the re-arm window is clamped '
        'to a sane non-negative value', () {
      final registry = RateLimitRegistry();
      final route = RouteKey('GET', '/x');
      registry.updateFromHeaders(route, {
        Header('X-RateLimit-Bucket', 'b'),
        Header('X-RateLimit-Limit', '1'),
        Header('X-RateLimit-Remaining', '0'),
        Header('X-RateLimit-Reset-After', '-100'),
      });

      // Must not throw or hang; a clamped (zero) window degrades to
      // "always immediately available" rather than a negative one that
      // would keep resetAt stuck in the past forever.
      expect(registry.reserve(route), equals(Duration.zero));
    });

    test('reserve respects an active global lock', () {
      final registry = RateLimitRegistry();
      final route = RouteKey('GET', '/x');
      registry.lockGlobal(const Duration(seconds: 2));
      expect(registry.reserve(route), greaterThan(Duration.zero));
    });

    test('delayFor stays a pure read — calling it never consumes a slot', () {
      final registry = RateLimitRegistry();
      final route = RouteKey('GET', '/x');
      registry
        ..updateFromHeaders(route, {
          Header('X-RateLimit-Bucket', 'b'),
          Header('X-RateLimit-Limit', '1'),
          Header('X-RateLimit-Remaining', '1'),
          Header('X-RateLimit-Reset-After', '5.0'),
        })
        ..delayFor(route)
        ..delayFor(route)
        ..delayFor(route);

      // remaining is still 1 — delayFor never decremented it — so the
      // first (and only) reserve() call still succeeds immediately.
      expect(registry.reserve(route), equals(Duration.zero));
    });
  });
}
