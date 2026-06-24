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
}
