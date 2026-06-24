/// Resolves a TTL for a given cache key based on a list of ordered rules.
///
/// Rules are matched in declaration order; the first match wins. A rule whose
/// pattern starts with `/` matches any key that *contains* that path segment
/// (e.g. `/members/` matches `guild/123/members/456`). Any other pattern is
/// treated as a prefix (e.g. `users/` matches `users/789`).
///
/// `null` TTL means "never expire".
final class CacheTtlPolicy {
  const CacheTtlPolicy._(this._rules, this._fallback);

  final List<_Rule> _rules;
  final Duration? _fallback;

  /// Default policy aligned on the cache keys produced by `CacheKey`.
  factory CacheTtlPolicy.defaults() => _defaults;

  /// Disables expiration entirely (legacy v4 behavior).
  factory CacheTtlPolicy.disabled() => _disabled;

  /// Returns the TTL for [key], or `null` if the key should never expire.
  Duration? ttlFor(String key) {
    for (final rule in _rules) {
      if (rule.matches(key)) {
        return rule.ttl;
      }
    }
    return _fallback;
  }

  /// Returns a new policy where [overrides] take priority over the existing
  /// rules. A pattern starting with `/` is matched as a contained path
  /// segment; any other pattern is matched as a prefix.
  CacheTtlPolicy override(Map<String, Duration?> overrides) {
    final extra = <_Rule>[
      for (final entry in overrides.entries)
        _Rule._fromPattern(entry.key, entry.value),
    ];
    return CacheTtlPolicy._([...extra, ..._rules], _fallback);
  }

  static const _disabled = CacheTtlPolicy._([], null);

  /// Conservative non-null TTL used for any key family not matched by an
  /// explicit rule.  Chosen to match the shortest top-level family TTL
  /// (users / invites = 1 h) so unlisted families cannot grow without bound.
  static const _conservativeFallback = Duration(hours: 1);

  static const _defaults = CacheTtlPolicy._(
    _defaultRules,
    _conservativeFallback,
  );
}

const _defaultRules = <_Rule>[
  // Top-level prefixes for entities that contain sub-paths matching segment
  // rules below (e.g. 'voice_states/guild/.../members/...') must be matched
  // before the segment rules to take priority over them.
  _Rule._prefix('ref:', null),
  _Rule._prefix('voice_states/', Duration(minutes: 5)),
  _Rule._segment('/members/', Duration(minutes: 30)),
  _Rule._segment('/roles/', Duration(hours: 4)),
  _Rule._segment('/emojis/', Duration(hours: 12)),
  _Rule._segment('/stickers/', Duration(hours: 12)),
  _Rule._segment('/messages/', Duration(minutes: 10)),
  _Rule._prefix('guild/', Duration(hours: 4)),
  _Rule._prefix('channels/', Duration(hours: 2)),
  _Rule._prefix('users/', Duration(hours: 1)),
  _Rule._prefix('threads/', Duration(hours: 2)),
  _Rule._prefix('messages/', Duration(minutes: 10)),
  _Rule._prefix('invites/', Duration(hours: 1)),
  _Rule._prefix('webhooks/', Duration(hours: 1)),
];

final class _Rule {
  const _Rule._prefix(this.pattern, this.ttl) : isSegment = false;
  const _Rule._segment(this.pattern, this.ttl) : isSegment = true;

  factory _Rule._fromPattern(String pattern, Duration? ttl) =>
      pattern.startsWith('/')
      ? _Rule._segment(pattern, ttl)
      : _Rule._prefix(pattern, ttl);

  final String pattern;
  final Duration? ttl;
  final bool isSegment;

  bool matches(String key) =>
      isSegment ? key.contains(pattern) : key.startsWith(pattern);
}
