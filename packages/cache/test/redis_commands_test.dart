import 'package:mineral_cache/src/providers/redis/redis_commands.dart';
import 'package:test/test.dart';

void main() {
  group('buildSetCommand', () {
    test('omits PX when ttl is null', () {
      expect(
        buildSetCommand('users/1', '{"id":1}', null),
        ['SET', 'users/1', '{"id":1}'],
      );
    });

    test('omits PX when ttl is zero', () {
      expect(
        buildSetCommand('k', 'v', Duration.zero),
        ['SET', 'k', 'v'],
      );
    });

    test('omits PX when ttl is negative', () {
      expect(
        buildSetCommand('k', 'v', const Duration(seconds: -1)),
        ['SET', 'k', 'v'],
      );
    });

    test('appends PX with milliseconds for positive ttl', () {
      expect(
        buildSetCommand('k', 'v', const Duration(seconds: 30)),
        ['SET', 'k', 'v', 'PX', '30000'],
      );
    });

    test('preserves sub-second precision', () {
      expect(
        buildSetCommand('k', 'v', const Duration(milliseconds: 250)),
        ['SET', 'k', 'v', 'PX', '250'],
      );
    });

    test('handles 4 hour TTL (server entries)', () {
      expect(
        buildSetCommand('server/1', 'payload', const Duration(hours: 4)),
        ['SET', 'server/1', 'payload', 'PX', '14400000'],
      );
    });
  });

  group('buildMsetCommand', () {
    test('flattens entries into key/value pairs', () {
      expect(
        buildMsetCommand({'a': '1', 'b': '2'}),
        ['MSET', 'a', '1', 'b', '2'],
      );
    });

    test('preserves declaration order', () {
      final entries = <String, String>{};
      entries['k3'] = 'v3';
      entries['k1'] = 'v1';
      entries['k2'] = 'v2';

      expect(
        buildMsetCommand(entries),
        ['MSET', 'k3', 'v3', 'k1', 'v1', 'k2', 'v2'],
      );
    });

    test('produces just MSET for an empty map', () {
      expect(buildMsetCommand({}), ['MSET']);
    });
  });
}
