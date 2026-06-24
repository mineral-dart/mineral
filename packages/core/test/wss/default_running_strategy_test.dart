import 'dart:io';

import 'package:mineral/src/domains/services/packets/packet_dispatcher.dart';
import 'package:mineral/src/domains/services/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/wss/running_strategies/default_running_strategy.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:test/test.dart';

import '../helpers/fake_logger.dart';

// ── Helpers ───────────────────────────────────────────────────────────────

/// A [DefaultRunningStrategy] subclass that overrides [readPubspec] so tests
/// control what the strategy reads without touching the filesystem.
final class _FakeReadStrategy extends DefaultRunningStrategy {
  final Future<Map<dynamic, dynamic>> Function(String) _readFn;

  _FakeReadStrategy(this._readFn)
    : super(_NoopPacketDispatcher(), logger: FakeLogger());

  @override
  Future<Map<dynamic, dynamic>> readPubspec(String location) =>
      _readFn(location);
}

/// Minimal [PacketDispatcherContract] stub — tests here do not exercise it.
final class _NoopPacketDispatcher implements PacketDispatcherContract {
  @override
  void dispatch(dynamic payload) {}

  @override
  void listen(
    PacketTypeContract packet,
    Function(ShardMessage, DispatchEvent) listener,
  ) {}

  @override
  void dispose() {}
}

// ── Tests ─────────────────────────────────────────────────────────────────

void main() {
  group('DefaultRunningStrategy.resolveVersion (M8 fallback)', () {
    test('returns version string from a plain mineral dependency', () async {
      final strategy = _FakeReadStrategy(
        (_) async => {
          'dependencies': {'mineral': '5.0.0'},
        },
      );

      expect(await strategy.resolveVersion(), equals('5.0.0'));
    });

    test('returns version from path-based mineral dependency', () async {
      final strategy = _FakeReadStrategy((location) async {
        if (location.endsWith('my_core')) {
          return {'version': '5.1.0'};
        }
        return {
          'dependencies': {
            'mineral': {'path': 'my_core'},
          },
        };
      });

      expect(await strategy.resolveVersion(), equals('5.1.0'));
    });

    test(
      'returns "unknown" when pubspec file is missing (FileSystemException)',
      () async {
        final strategy = _FakeReadStrategy(
          (_) => Future.error(FileSystemException('not found')),
        );

        expect(await strategy.resolveVersion(), equals('unknown'));
      },
    );

    test('returns "unknown" when dependencies key is absent', () async {
      final strategy = _FakeReadStrategy((_) async => <dynamic, dynamic>{});

      expect(await strategy.resolveVersion(), equals('unknown'));
    });

    test(
      'returns "unknown" when mineral version value is not a String',
      () async {
        final strategy = _FakeReadStrategy(
          (_) async => {
            'dependencies': {'mineral': 42},
          },
        );

        expect(await strategy.resolveVersion(), equals('unknown'));
      },
    );

    test(
      'returns "unknown" when path dep but remote pubspec version is not a String',
      () async {
        final strategy = _FakeReadStrategy((location) async {
          if (location.endsWith('my_core')) {
            return {'version': 999};
          }
          return {
            'dependencies': {
              'mineral': {'path': 'my_core'},
            },
          };
        });

        expect(await strategy.resolveVersion(), equals('unknown'));
      },
    );

    test('returns "unknown" when path dep has no path key', () async {
      final strategy = _FakeReadStrategy(
        (_) async => {
          'dependencies': {
            'mineral': {'git': 'https://example.com'},
          },
        },
      );

      expect(await strategy.resolveVersion(), equals('unknown'));
    });
  });
}
