import 'package:mineral/src/domains/services/wss/constants/shard_disconnect_error.dart';
import 'package:test/test.dart';

void main() {
  group('ShardDisconnectError', () {
    test('code 1005 exists in enum', () {
      final error = ShardDisconnectError.values
          .where((e) => e.code == 1005)
          .firstOrNull;

      expect(error, isNotNull);
      expect(error, ShardDisconnectError.noStatusReceived);
    });

    test('all standard WebSocket codes (1xxx) have reconnect action', () {
      final standardCodes = ShardDisconnectError.values.where(
        (e) => e.code >= 1000 && e.code < 2000,
      );

      expect(standardCodes, isNotEmpty);
      for (final error in standardCodes) {
        expect(
          error.action,
          DisconnectAction.reconnect,
          reason: '${error.name} (${error.code}) should be reconnect',
        );
      }
    });

    test('resumable Discord codes have resume action', () {
      const resumableCodes = [4000, 4001, 4002, 4003, 4007, 4008, 4009];

      for (final code in resumableCodes) {
        final error = ShardDisconnectError.values
            .where((e) => e.code == code)
            .first;

        expect(
          error.action,
          DisconnectAction.resume,
          reason: '${error.name} ($code) should be resume',
        );
      }
    });

    test('fatal Discord codes have fatal action', () {
      const fatalCodes = [4004, 4010, 4011, 4012, 4013, 4014];

      for (final code in fatalCodes) {
        final error = ShardDisconnectError.values
            .where((e) => e.code == code)
            .first;

        expect(
          error.action,
          DisconnectAction.fatal,
          reason: '${error.name} ($code) should be fatal',
        );
      }
    });

    test('every enum value has a non-empty message', () {
      for (final error in ShardDisconnectError.values) {
        expect(
          error.message,
          isNotEmpty,
          reason: '${error.name} should have a message',
        );
      }
    });
  });
}
