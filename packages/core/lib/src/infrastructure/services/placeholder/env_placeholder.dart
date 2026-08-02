import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/utils/redact.dart';
import 'package:recase/recase.dart';

/// Exposes an allowlisted, redacted slice of the process environment for
/// string substitution in command definition files (see
/// `CommandDefinitionBuilder.using`).
///
/// # Security
///
/// `env.toJson()` (from `env_guard`) reflects the *entire* `_environments`
/// map maintained by the package-level `env` singleton. `ClientBuilder`
/// seeds that map from `Platform.environment` before validating the
/// application schema on top of it, so by the time a bot is running it
/// holds every process environment variable — including `TOKEN` — not just
/// the ones declared in `AppEnv`.
///
/// Because this class' output can end up in Discord-visible command
/// metadata, it never exposes anything by default:
///
/// - Only variable names passed explicitly via the [keys] constructor
///   parameter are ever readable through [values] or substituted by
///   [apply]. An absent or empty allowlist exposes nothing — there is no
///   implicit "everything" mode.
/// - [AppEnv.token] is hard-excluded unconditionally, even if it is named
///   explicitly in [keys].
/// - Whatever survives the allowlist is additionally passed through
///   [redactSensitiveFields] before being stored, as a second, independent
///   layer of defense (it also catches other secret-shaped keys, e.g. a
///   `*_PASSWORD` or `*_SECRET` variable a caller might allowlist by
///   mistake).
///
/// SECURITY: [apply] must never be called on a string sourced from Discord
/// (interaction option values, message content, embed fields, etc). It
/// performs literal substring substitution — this class restricts which
/// *values* can be substituted into a template, it does not sanitise the
/// template itself.
final class EnvPlaceholder implements PlaceholderContract {
  final Map<String, dynamic> _values = {};

  @override
  String get identifier => 'env';

  @override
  Map<String, dynamic> get values => _values;

  /// [keys] is the explicit allowlist of environment variable names to
  /// expose (as declared in your `DefineEnvironment` schema, e.g.
  /// `EnvPlaceholder(keys: {'GUILD_ID', 'PREFIX'})`). Matching is
  /// case-insensitive. Omitting [keys], or passing an empty set, exposes
  /// nothing: that is the only safe default for a class whose output can
  /// reach Discord.
  EnvPlaceholder({Set<String> keys = const {}}) {
    final allowedKeys = keys.map((key) => key.toUpperCase()).toSet();
    final tokenKey = AppEnv.token.toUpperCase();

    final allowed = Map<String, dynamic>.fromEntries(
      env.toJson().entries.where((entry) {
        final normalizedKey = entry.key.toUpperCase();
        return normalizedKey != tokenKey &&
            allowedKeys.contains(normalizedKey);
      }),
    );

    _injectEntryMap(identifier, redactSensitiveFields(allowed));
  }

  void _injectEntryMap(String identifier, Map<String, dynamic> values) {
    final mapEntry = Map<String, dynamic>.from(
      values.map((key, value) {
        final currentKey = key.snakeCase.toUpperCase();
        return MapEntry('$identifier.$currentKey', value);
      }),
    );

    _values.addAll(mapEntry);
  }

  @override
  String apply(String value) {
    return values.entries.fold(value, (acc, element) {
      final String finalValue = switch (element.value) {
        final String s => s,
        final num n => n.toString(),
        final other => other.toString(),
      };

      return acc
          .replaceAll('{${element.key}}', finalValue)
          .replaceAll('{{ ${element.key} }}', finalValue);
    });
  }
}
