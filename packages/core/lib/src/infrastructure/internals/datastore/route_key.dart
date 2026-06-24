/// Identifies a Discord API route for rate-limit bucketing.
///
/// Discord scopes per-route limits by HTTP method and the top-level
/// "major" parameters: `channel_id`, `guild_id`, `webhook_id` (and
/// `webhook_token` for webhook execution). Other path parameters (message
/// ids, member ids, etc.) are minor and shared across the same route.
final class RouteKey {
  final String method;
  final String normalizedPath;

  const RouteKey._(this.method, this.normalizedPath);

  factory RouteKey(String method, String path) {
    return RouteKey._(method.toUpperCase(), _normalize(method, path));
  }

  static String _normalize(String method, String path) {
    final pathOnly = path.split('?').first;
    final segments = pathOnly.split('/').where((s) => s.isNotEmpty).toList();

    final out = <String>[];
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final previous = i == 0 ? '' : segments[i - 1];

      if (_isMajorParameter(previous)) {
        out.add(segment);
        continue;
      }

      if (previous == 'webhooks' && i + 1 < segments.length) {
        out.add(segment);
        continue;
      }

      if (_isSnowflake(segment)) {
        out.add('{id}');
        continue;
      }

      if (previous == 'reactions' && segment != '@me') {
        out.add('{emoji}');
        continue;
      }

      out.add(segment);
    }

    final normalized = '/${out.join('/')}';

    if (method.toUpperCase() == 'DELETE' &&
        out.length == 4 &&
        out[0] == 'channels' &&
        out[2] == 'messages' &&
        out[3] == '{id}') {
      return '$normalized::delete-message';
    }

    return normalized;
  }

  static bool _isMajorParameter(String previous) {
    return previous == 'channels' ||
        previous == 'guilds' ||
        previous == 'webhooks';
  }

  static bool _isSnowflake(String segment) {
    if (segment.isEmpty) {
      return false;
    }
    if (segment.length < 15 || segment.length > 21) {
      return false;
    }
    for (final code in segment.codeUnits) {
      if (code < 0x30 || code > 0x39) {
        return false;
      }
    }
    return true;
  }

  /// Returns a human-readable representation of this route with sensitive
  /// credential segments redacted.
  ///
  /// The raw token that follows the webhook/interaction id is masked with
  /// `***` so that it is never exposed in log output (CWE-532).
  /// Bucketing identity ([normalizedPath], [==], [hashCode]) is unaffected.
  String get redactedString {
    final redacted = _redactTokenSegments(normalizedPath);
    return '$method $redacted';
  }

  /// Replaces the token segment that immediately follows a webhook or
  /// interaction id with `***`.
  ///
  /// Patterns handled:
  ///   `/webhooks/<id>/<token>[/...]`   — id kept as raw snowflake (major param)
  ///   `/interactions/{id}/<token>[/...]` — id normalised to `{id}` placeholder
  static String _redactTokenSegments(String path) {
    final segments = path.split('/');
    // segments[0] is always '' because path starts with '/'
    final out = <String>[];
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      if (i >= 3) {
        final routeClass = segments[i - 2]; // e.g. 'webhooks' or 'interactions'
        // For webhooks the id is raw (major param); for interactions it is
        // normalised to '{id}'.  Either way, position i is the token segment.
        if (routeClass == 'webhooks' || routeClass == 'interactions') {
          out.add('***');
          continue;
        }
      }
      out.add(segment);
    }
    return out.join('/');
  }

  @override
  String toString() => '$method $normalizedPath';

  @override
  bool operator ==(Object other) =>
      other is RouteKey &&
      other.method == method &&
      other.normalizedPath == normalizedPath;

  @override
  int get hashCode => Object.hash(method, normalizedPath);
}
