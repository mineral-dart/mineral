import 'package:mineral/src/infrastructure/internals/datastore/route_key.dart';
import 'package:mineral/src/infrastructure/services/http/header.dart';

/// State of a single Discord rate-limit bucket.
final class BucketState {
  final String id;
  int limit;
  int remaining;
  DateTime resetAt;

  /// The bucket's last known window length (the `X-RateLimit-Reset-After`
  /// duration it was last updated with, or the `retry_after` of the last
  /// 429). Used to optimistically re-arm [remaining] once [resetAt] has
  /// elapsed but no fresh response has reconciled the state yet — see
  /// [RateLimitRegistry.reserve].
  Duration window;

  BucketState({
    required this.id,
    required this.limit,
    required this.remaining,
    required this.resetAt,
    this.window = Duration.zero,
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
  /// Grace period past [BucketState.resetAt] after which an entry is
  /// considered stale and evicted (A21). Without this, a bot that keeps
  /// hitting new guilds/channels/interactions over a long uptime would
  /// grow these maps forever.
  final Duration _staleGrace;

  /// Keyed on [RouteKey.redactedString] — a token-free identity — rather
  /// than the [RouteKey] itself, so that distinct interaction/webhook
  /// tokens for the same resource collapse onto one entry instead of
  /// growing the map per credential (A21, CWE-532: raw tokens are never
  /// retained as map keys here).
  final Map<String, String> _routeToBucket = {};
  final Map<String, BucketState> _buckets = {};
  DateTime? _globalLockedUntil;

  RateLimitRegistry({Duration staleGrace = const Duration(minutes: 15)})
    : _staleGrace = staleGrace;

  /// Number of distinct buckets currently tracked. Exposed so callers
  /// (and tests) can assert the registry stays bounded.
  int get trackedBucketCount => _buckets.length;

  /// Number of distinct route identities currently mapped to a bucket.
  int get trackedRouteCount => _routeToBucket.length;

  static String _bucketKey(RouteKey route) => route.redactedString;

  /// Returns the delay to wait before sending a request for [route],
  /// or [Duration.zero] if it can be sent immediately.
  ///
  /// This is a pure read: it never mutates [BucketState.remaining]. Use
  /// [reserve] to make an actual dispatch decision — see its doc for why
  /// this distinction matters for in-flight accounting (A24).
  Duration delayFor(RouteKey route) {
    final globalLock = _globalLockedUntil;
    if (globalLock != null && globalLock.isAfter(DateTime.now())) {
      return globalLock.difference(DateTime.now());
    }

    final bucketId = _routeToBucket[_bucketKey(route)];
    if (bucketId == null) {
      return Duration.zero;
    }

    final state = _buckets[bucketId];
    if (state == null) {
      return Duration.zero;
    }

    return state.isExhausted ? state.timeUntilReset : Duration.zero;
  }

  /// Reserves a dispatch slot for [route], returning the delay to wait
  /// before sending (or [Duration.zero] to dispatch immediately).
  ///
  /// Unlike [delayFor], this is *not* a pure read: when it authorises an
  /// immediate dispatch it also decrements the bucket's `remaining` count
  /// synchronously, before returning. This method contains no `await`, so
  /// under Dart's single-threaded, run-to-completion scheduling the whole
  /// read-decide-decrement sequence is atomic with respect to every other
  /// synchronous caller. Concrete consequence: if N callers each evaluate
  /// this before any HTTP response has come back, they do not all observe
  /// the same stale `remaining` and all get a go-ahead — each one's call
  /// runs to completion (there being no suspension point inside it)
  /// before the next caller's call begins, so the decrements are properly
  /// serialized and only as many callers as there is `remaining` capacity
  /// get [Duration.zero] back (A24, interleaving 1).
  ///
  /// When [BucketState.resetAt] has elapsed, `remaining` is optimistically
  /// re-armed to `limit` and `resetAt` is pushed forward by the bucket's
  /// last known [BucketState.window] — both within this same atomic step.
  /// That means only `limit`-many queued callers get to proceed on a given
  /// reset instant, not every waiter that happened to be sleeping on the
  /// same target time (A24, interleaving 2). Callers that lose the race
  /// receive the (freshly extended) time remaining until the next window
  /// and are expected to call [reserve] again after waiting — not to reuse
  /// a delay computed before the wait, which is what let every waiter
  /// resume together in the first place.
  ///
  /// The response, once it lands, still reconciles the authoritative state
  /// via [updateFromHeaders]; this is only an optimistic guess in between.
  Duration reserve(RouteKey route) {
    final now = DateTime.now();

    final globalLock = _globalLockedUntil;
    if (globalLock != null && globalLock.isAfter(now)) {
      return globalLock.difference(now);
    }

    final bucketId = _routeToBucket[_bucketKey(route)];
    if (bucketId == null) {
      return Duration.zero;
    }

    final state = _buckets[bucketId];
    if (state == null) {
      return Duration.zero;
    }

    if (!state.resetAt.isAfter(now)) {
      state
        ..remaining = state.limit
        ..resetAt = now.add(state.window);
    }

    if (state.remaining <= 0) {
      final delta = state.resetAt.difference(now);
      return delta.isNegative ? Duration.zero : delta;
    }

    state.remaining -= 1;
    return Duration.zero;
  }

  /// Updates state from a successful or 429 response.
  void updateFromHeaders(RouteKey route, Set<Header> headers) {
    _evictStale();

    final parsed = _RateLimitHeaders.parse(headers);
    if (parsed.bucketId == null) {
      return;
    }

    _routeToBucket[_bucketKey(route)] = parsed.bucketId!;

    final existing = _buckets[parsed.bucketId];
    final resetAt = parsed.resetAt ?? existing?.resetAt ?? DateTime.now();
    final limit = parsed.limit ?? existing?.limit ?? 0;
    final remaining = parsed.remaining ?? existing?.remaining ?? 0;
    final window = parsed.resetAfter ?? existing?.window ?? Duration.zero;

    _buckets[parsed.bucketId!] = BucketState(
      id: parsed.bucketId!,
      limit: limit,
      remaining: remaining,
      resetAt: resetAt,
      window: window,
    );
  }

  /// Records a global lock from a 429 with `global=true`.
  void lockGlobal(Duration retryAfter) {
    _globalLockedUntil = DateTime.now().add(retryAfter);
  }

  /// Records a per-bucket lock from a 429 (non-global).
  void lockRoute(RouteKey route, Duration retryAfter) {
    final bucketId = _routeToBucket[_bucketKey(route)];
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
      window: retryAfter,
    );
  }

  BucketState? bucketFor(RouteKey route) {
    final bucketId = _routeToBucket[_bucketKey(route)];
    if (bucketId == null) {
      return null;
    }
    return _buckets[bucketId];
  }

  DateTime? get globalLockedUntil => _globalLockedUntil;

  /// Evicts buckets (and their route mappings) whose [BucketState.resetAt]
  /// is more than [_staleGrace] in the past, bounding the registry's
  /// memory footprint across a long-running process (A21).
  void _evictStale() {
    final now = DateTime.now();
    final staleIds = <String>{
      for (final entry in _buckets.entries)
        if (now.isAfter(entry.value.resetAt.add(_staleGrace))) entry.key,
    };

    if (staleIds.isEmpty) {
      return;
    }

    _buckets.removeWhere((id, _) => staleIds.contains(id));
    _routeToBucket.removeWhere((_, id) => staleIds.contains(id));
  }
}

class _RateLimitHeaders {
  final String? bucketId;
  final int? limit;
  final int? remaining;
  final DateTime? resetAt;
  final Duration? resetAfter;

  _RateLimitHeaders({
    required this.bucketId,
    required this.limit,
    required this.remaining,
    required this.resetAt,
    required this.resetAfter,
  });

  factory _RateLimitHeaders.parse(Set<Header> headers) {
    String? bucketId;
    int? limit;
    int? remaining;
    DateTime? resetAt;
    Duration? resetAfter;

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
            final rawResetAfter = Duration(
              milliseconds: (seconds * 1000).round(),
            );
            // resetAt is allowed to land in the past (tests use this to
            // simulate an already-stale bucket for eviction); the window
            // used to re-arm in [RateLimitRegistry.reserve] is clamped to
            // a sane non-negative value so a malformed/negative header
            // can't produce a permanently-elapsed re-arm target.
            resetAt = DateTime.now().add(rawResetAfter);
            resetAfter = rawResetAfter.isNegative
                ? Duration.zero
                : rawResetAfter;
          }
      }
    }

    return _RateLimitHeaders(
      bucketId: bucketId,
      limit: limit,
      remaining: remaining,
      resetAt: resetAt,
      resetAfter: resetAfter,
    );
  }
}
