import 'dart:async';

import 'package:mineral/services.dart';
import 'package:mineral/src/domains/services/wss/websocket_orchestrator.dart';
import 'package:mineral/src/infrastructure/internals/wss/websocket_orchestrator.dart';
import 'package:mineral/src/testing/fake_logger.dart';
import 'package:test/test.dart';

import '../helpers/fake_sharding_config.dart';

// ── Helpers ────────────────────────────────────────────────────────────────

RequestQueueEntry _entry(String uid) =>
    (uid: uid, targetKeys: ['data'], completer: Completer<dynamic>());

final class _NoopHttpClient implements HttpClientContract {
  @override
  HttpClientConfig get config => throw UnimplementedError();
  @override
  HttpClientStatus get status => throw UnimplementedError();
  @override
  HttpInterceptor get interceptor => throw UnimplementedError();
  @override
  Future<Response<T>> get<T>(RequestContract r) => throw UnimplementedError();
  @override
  Future<Response<T>> post<T>(RequestContract r) => throw UnimplementedError();
  @override
  Future<Response<T>> put<T>(RequestContract r) => throw UnimplementedError();
  @override
  Future<Response<T>> patch<T>(RequestContract r) => throw UnimplementedError();
  @override
  Future<Response<T>> delete<T>(RequestContract r) => throw UnimplementedError();
  @override
  Future<Response<T>> send<T>(RequestContract r) => throw UnimplementedError();
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('WebsocketOrchestrator — request queue', () {
    late WebsocketOrchestrator orchestrator;

    setUp(() {
      orchestrator = WebsocketOrchestrator(
        FakeShardingConfig(),
        logger: FakeLogger(),
        httpClient: _NoopHttpClient(),
      );
    });

    group('addToRequestQueue', () {
      test('adds an entry to the queue', () {
        final entry = _entry('uid-1');
        orchestrator.addToRequestQueue(entry);

        expect(orchestrator.requestQueue, hasLength(1));
        expect(orchestrator.requestQueue.first.uid, equals('uid-1'));
      });

      test('preserves insertion order', () {
        orchestrator
          ..addToRequestQueue(_entry('a'))
          ..addToRequestQueue(_entry('b'))
          ..addToRequestQueue(_entry('c'));

        final uids = orchestrator.requestQueue.map((e) => e.uid).toList();
        expect(uids, equals(['a', 'b', 'c']));
      });
    });

    group('findInRequestQueue', () {
      test('returns the entry when uid matches', () {
        final entry = _entry('target');
        orchestrator.addToRequestQueue(entry);

        final found = orchestrator.findInRequestQueue('target');

        expect(found, isNotNull);
        expect(found!.uid, equals('target'));
      });

      test('returns null when uid is not present', () {
        orchestrator.addToRequestQueue(_entry('other'));

        expect(orchestrator.findInRequestQueue('missing'), isNull);
      });

      test('returns null on empty queue', () {
        expect(orchestrator.findInRequestQueue('anything'), isNull);
      });

      test('returns first match when multiple entries exist', () {
        orchestrator
          ..addToRequestQueue(_entry('a'))
          ..addToRequestQueue(_entry('b'));

        final found = orchestrator.findInRequestQueue('b');
        expect(found?.uid, equals('b'));
      });
    });

    group('removeFromRequestQueue', () {
      test('removes the specified entry', () {
        final entry = _entry('to-remove');
        orchestrator.addToRequestQueue(entry);
        orchestrator.removeFromRequestQueue(entry);

        expect(orchestrator.requestQueue, isEmpty);
      });

      test('only removes the specified entry', () {
        final keep = _entry('keep');
        final remove = _entry('remove');
        orchestrator
          ..addToRequestQueue(keep)
          ..addToRequestQueue(remove);

        orchestrator.removeFromRequestQueue(remove);

        expect(orchestrator.requestQueue, hasLength(1));
        expect(orchestrator.requestQueue.first.uid, equals('keep'));
      });

      test('is a no-op when entry is not in the queue', () {
        final outside = _entry('outside');
        orchestrator.addToRequestQueue(_entry('inside'));

        expect(() => orchestrator.removeFromRequestQueue(outside), returnsNormally);
        expect(orchestrator.requestQueue, hasLength(1));
      });
    });

    group('requestQueue immutability', () {
      test('exposed list is unmodifiable', () {
        orchestrator.addToRequestQueue(_entry('a'));

        expect(
          () => orchestrator.requestQueue.add(_entry('b')),
          throwsUnsupportedError,
        );
      });
    });
  });
}
