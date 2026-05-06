/// Pure helpers that build raw Redis command arrays.
///
/// Extracted from `RedisProvider` so the command shape (in particular the
/// `SET … PX millis` variant introduced for TTL support) can be unit-tested
/// without a live Redis connection.
library;

/// Builds a `SET` command, optionally with a millisecond expiration.
///
/// When [ttl] is `null` or non-positive, falls back to a plain `SET`. When
/// [ttl] is positive, appends `PX <millis>` so sub-second precision is
/// preserved (Discord rate-limit and message TTLs often need this).
List<String> buildSetCommand(String key, String value, Duration? ttl) {
  if (ttl == null || ttl <= Duration.zero) {
    return ['SET', key, value];
  }
  return ['SET', key, value, 'PX', ttl.inMilliseconds.toString()];
}

/// Builds an `MSET` command for atomic multi-key writes without TTL.
///
/// Redis `MSET` does not accept `EX`/`PX`, so callers must use a sequence of
/// `SET … PX` commands when any TTL is required.
List<String> buildMsetCommand(Map<String, String> entries) {
  return [
    'MSET',
    for (final entry in entries.entries) ...[entry.key, entry.value],
  ];
}
