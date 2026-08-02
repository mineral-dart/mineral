import 'package:mineral/src/api/common/types/enhanced_enum.dart';
import 'package:mineral/src/domains/common/utils/utils.dart';
import 'package:test/test.dart';

/// Minimal [EnhancedEnum<int>] fixture with a deliberately aliased bit
/// (`a` and `aAlias` both map to `1 << 0`), mirroring the real-world
/// `Permission.usePublicThreads` / `Permission.createPublicThreads` shape,
/// but decoupled from `Permission` so these tests exercise `listToBitfield`
/// and `bitfieldToList` generically.
enum _Flag implements EnhancedEnum<int> {
  a(1 << 0),
  aAlias(1 << 0),
  b(1 << 1),
  c(1 << 2);

  @override
  final int value;

  const _Flag(this.value);
}

void main() {
  group('listToBitfield', () {
    test('ORs disjoint values together', () {
      expect(listToBitfield([_Flag.a, _Flag.b]), equals((1 << 0) | (1 << 1)));
    });

    test('OR-ing the same bit twice does not carry into the next bit', () {
      // Summing (the old, buggy behaviour) would produce
      // (1 << 0) + (1 << 0) == 1 << 1, silently colliding with `_Flag.b`.
      final bitfield = listToBitfield([_Flag.a, _Flag.aAlias]);

      expect(bitfield, equals(1 << 0));
      expect(bitfield, isNot(equals(_Flag.b.value)));
    });

    test('OR-ing an aliased pair alongside another flag stays correct', () {
      final bitfield = listToBitfield([_Flag.a, _Flag.aAlias, _Flag.b]);

      expect(bitfield, equals((1 << 0) | (1 << 1)));
    });
  });

  group('listToBitfield(bitfieldToList(x)) round trip', () {
    test('round-trips every raw combination, including aliased bits', () {
      for (var raw = 0; raw <= ((1 << 0) | (1 << 1) | (1 << 2)); raw++) {
        final roundTripped = listToBitfield(bitfieldToList(_Flag.values, raw));

        expect(
          roundTripped,
          equals(raw),
          reason: 'round-trip failed for raw=$raw',
        );
      }
    });
  });

  group('toDiscordTimestamp', () {
    test('produces a UTC ISO-8601 string with a Z suffix', () {
      final utcInstant = DateTime.utc(2026, 8, 2, 12, 30, 0);
      final local = utcInstant.toLocal();

      final result = toDiscordTimestamp(local);

      expect(result, endsWith('Z'));
      expect(DateTime.parse(result).toUtc(), equals(utcInstant));
    });

    test('preserves the exact instant regardless of the input zone', () {
      final utcInstant = DateTime.utc(2026, 1, 1, 0, 0, 0);
      final local = utcInstant.toLocal();

      expect(toDiscordTimestamp(local), equals(toDiscordTimestamp(utcInstant)));
    });

    test('a UTC input is unaffected beyond formatting', () {
      final utcInstant = DateTime.utc(2025, 12, 31, 23, 59, 59);

      expect(
        toDiscordTimestamp(utcInstant),
        equals(utcInstant.toIso8601String()),
      );
    });
  });
}
