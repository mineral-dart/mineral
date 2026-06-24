import 'package:mineral/src/infrastructure/internals/datastore/route_key.dart';
import 'package:mineral/src/infrastructure/services/http/header.dart';

/// State of a single Discord rate-limit bucket.
final class BucketState {
  final String id;
  int limit;
  int remaining;
  DateTime resetAt;

  BucketState({
    required this.id,
    required this.limit,
    required this.remaining,
    required this.resetAt,
  });

  bool get isExhausted => remaining <= 0 && resetAt.isAfter(DateTime.now());

  Duration get timeUntilReset {
    final delta = resetAt.difference(DateTime.now());
    return delta.isNegative ? Duration.zero : delta;
  }
}

/// Tracks Discord rate-limit state across routes and bucket ids.
///
/// Discord groups one or more routes under a server-defined bucket id,
/// returned as `X-RateLimit-Bucket`. The first hit on a route is
/// optimistic — we have no bucket yet — but subsequent hits use the
/// learnt mapping to pre-empt requests that would 429.
final class RateLimitRegistry {
  final Map<RouteKey, String> _routeToBucket = {};
  final Map<String, BucketState> _buckets = {};
  DateTime? _globalLockedUntil;

  /// Returns the delay to wait before sending a request for [route],
  /// or [Duration.zero] if it can be sent immediately.
  Duration delayFor(RouteKey route) {
    final globalLock = _globalLockedUntil;
    if (globalLock != null && globalLock.isAfter(DateTime.now())) {
      return globalLock.difference(DateTime.now());
    }

    final bucketId = _routeToBucket[route];
    if (bucketId == null) {
      return Duration.zero;
    }

    final state = _buckets[bucketId];
    if (state == null) {
      return Duration.zero;
    }

    return state.isExhausted ? state.timeUntilReset : Duration.zero;
  }

  /// Updates state from a successful or 429 response.
  void updateFromHeaders(RouteKey route, Set<Header> headers) {
    final parsed = _RateLimitHeaders.parse(headers);
    if (parsed.bucketId == null) {
      return;
    }

    _routeToBucket[route] = parsed.bucketId!;

    final existing = _buckets[parsed.bucketId];
    final resetAt = parsed.resetAt ?? existing?.resetAt ?? DateTime.now();
    final limit = parsed.limit ?? existing?.limit ?? 0;
    final remaining = parsed.remaining ?? existing?.remaining ?? 0;

    _buckets[parsed.bucketId!] = BucketState(
      id: parsed.bucketId!,
      limit: limit,
      remaining: remaining,
      resetAt: resetAt,
    );
  }

  /// Records a global lock from a 429 with `global=true`.
  void lockGlobal(Duration retryAfter) {
    _globalLockedUntil = DateTime.now().add(retryAfter);
  }

  /// Records a per-bucket lock from a 429 (non-global).
  void lockRoute(RouteKey route, Duration retryAfter) {
    final bucketId = _routeToBucket[route];
    if (bucketId == null) {
      return;
    }

    final state = _buckets[bucketId];
    final resetAt = DateTime.now().add(retryAfter);
    _buckets[bucketId] = BucketState(
      id: bucketId,
      limit: state?.limit ?? 0,
      remaining: 0,
      resetAt: resetAt,
    );
  }

  BucketState? bucketFor(RouteKey route) {
    final bucketId = _routeToBucket[route];
    if (bucketId == null) {
      return null;
    }
    return _buckets[bucketId];
  }

  DateTime? get globalLockedUntil => _globalLockedUntil;
}

class _RateLimitHeaders {
  final String? bucketId;
  final int? limit;
  final int? remaining;
  final DateTime? resetAt;

  _RateLimitHeaders({
    required this.bucketId,
    required this.limit,
    required this.remaining,
    required this.resetAt,
  });

  factory _RateLimitHeaders.parse(Set<Header> headers) {
    String? bucketId;
    int? limit;
    int? remaining;
    DateTime? resetAt;

    for (final header in headers) {
      final key = header.key.toLowerCase();
      switch (key) {
        case 'x-ratelimit-bucket':
          bucketId = header.value;
        case 'x-ratelimit-limit':
          limit = int.tryParse(header.value);
        case 'x-ratelimit-remaining':
          remaining = int.tryParse(header.value);
        case 'x-ratelimit-reset-after':
          final seconds = double.tryParse(header.value);
          if (seconds != null) {
            resetAt = DateTime.now().add(
              Duration(milliseconds: (seconds * 1000).round()),
            );
          }
      }
    }

    return _RateLimitHeaders(
      bucketId: bucketId,
      limit: limit,
      remaining: remaining,
      resetAt: resetAt,
    );
  }
}
