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
