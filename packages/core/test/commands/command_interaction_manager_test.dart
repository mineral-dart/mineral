import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/common/runtime_state.dart';
import 'package:mineral/src/domains/services/datastore/request_bucket_contract.dart';
import 'package:test/test.dart';

import '../helpers/fake_datastore.dart';
import '../helpers/fake_entity_context.dart';
import '../helpers/fake_http_client.dart';
import '../helpers/fake_marshaller.dart';
import '../helpers/fake_response.dart';
import '../helpers/fake_websocket_orchestrator.dart';
import '../packets/helpers/packet_test_helpers.dart' show buildMinimalGuild;

// ── Fakes ────────────────────────────────────────────────────────────────────
//
// Regression coverage for #470: registerGlobal/registerServer used to call
// `dataStore.client.put(...)` directly (skipping RateLimitRegistry) and only
// ever inspected `statusCode == 400`, so a 401/403/429/5xx completed as a
// silent success. These fakes let the tests assert routing and error
// handling without depending on RateLimitRegistry's retry/backoff internals.

/// Fails the test loudly if registration ever calls the raw HTTP client
/// directly. Registration must go through [RequestBucketContract] so
/// rate-limit backoff and bucket accounting apply (#470).
final class _ForbiddenHttpClient implements HttpClientContract {
  @override
  Future<Response<T>> put<T>(RequestContract request) {
    fail(
      'registration called dataStore.client.put(...) directly instead of '
      'routing through dataStore.requestBucket — rate-limit backoff and '
      'bucket accounting are skipped (#470)',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

/// Records every [put] call and lets the test dictate the outcome directly,
/// mirroring what the real `RequestBucket` does for a given response without
/// depending on `RateLimitRegistry`'s retry/backoff internals.
final class _RecordingRequestBucket implements RequestBucketContract {
  int putCalls = 0;
  RequestContract? lastRequest;

  /// When set, [put] hands this response to the caller's `onError` and
  /// throws whatever it returns, exactly like the real bucket does for any
  /// non-success status.
  Response? failWith;

  @override
  Future<T> put<T>(
    RequestContract request, {
    void Function(T)? onSuccess,
    Exception Function(Response)? onError,
    void Function(Duration)? onRateLimit,
  }) async {
    putCalls++;
    lastRequest = request;

    final response = failWith;
    if (response != null) {
      throw onError?.call(response) ??
          Exception('unhandled error response ${response.statusCode}');
    }

    return <String, dynamic>{} as T;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

final class _RoutingDataStore implements DataStoreContract {
  @override
  final RequestBucketContract requestBucket;

  @override
  final HttpClientContract client = _ForbiddenHttpClient();

  _RoutingDataStore(this.requestBucket);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

// ── Builders ─────────────────────────────────────────────────────────────────

CommandInteractionManager _buildManager({
  required DataStoreContract dataStore,
  required MarshallerContract marshaller,
}) => CommandInteractionManager(
  dataStore: dataStore,
  marshaller: marshaller,
  ctx: EntityContext(
    datastore: dataStore,
    wss: FakeWebsocketOrchestrator(),
    logger: marshaller.logger,
    runtimeState: RuntimeState(),
  ),
);

Bot _buildBot({String id = '999999999999999999'}) => Bot.fromJson({
  'user': {
    'id': id,
    'username': 'TestBot',
    'discriminator': '0000',
    'mfa_enabled': false,
    'global_name': null,
    'flags': 0,
    'avatar': null,
  },
  'v': 10,
  'session_type': 'normal',
  'private_channels': [],
  'presences': [],
  'guilds': [],
  'application': {'id': id, 'flags': 0},
}, wss: FakeWebsocketOrchestrator());

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('CommandInteractionManager command registration (#470)', () {
    late Bot bot;
    late Guild guild;

    setUp(() {
      bot = _buildBot();
      guild = buildMinimalGuild('222222222222222222', fakeEntityContext());
    });

    group('routes through the rate-limit bucket, never the raw client', () {
      test('registerGlobal calls requestBucket.put exactly once', () async {
        final bucket = _RecordingRequestBucket();
        final dataStore = _RoutingDataStore(bucket);
        final marshaller = FakeMarshaller(dataStore: dataStore);
        final manager = _buildManager(
          dataStore: dataStore,
          marshaller: marshaller,
        );

        await manager.registerGlobal(bot);

        expect(bucket.putCalls, equals(1));
        expect(
          bucket.lastRequest?.url.path,
          contains('/applications/${bot.id.value}/commands'),
        );
      });

      test('registerServer calls requestBucket.put exactly once', () async {
        final bucket = _RecordingRequestBucket();
        final dataStore = _RoutingDataStore(bucket);
        final marshaller = FakeMarshaller(dataStore: dataStore);
        final manager = _buildManager(
          dataStore: dataStore,
          marshaller: marshaller,
        );

        await manager.registerServer(bot, guild);

        expect(bucket.putCalls, equals(1));
        expect(
          bucket.lastRequest?.url.path,
          contains('/guilds/${guild.id.value}/commands'),
        );
      });
    });

    group('surfaces every non-success status, not only 400', () {
      for (final status in [401, 403, 429, 500, 503]) {
        test(
          'registerGlobal throws on $status instead of completing silently',
          () async {
            final bucket = _RecordingRequestBucket()
              ..failWith = FakeResponse<dynamic>(
                status,
                {'message': 'boom'},
                bodyString: '{"message":"boom"}',
              );
            final dataStore = _RoutingDataStore(bucket);
            final marshaller = FakeMarshaller(dataStore: dataStore);
            final manager = _buildManager(
              dataStore: dataStore,
              marshaller: marshaller,
            );

            await expectLater(
              () => manager.registerGlobal(bot),
              throwsA(
                isA<InvalidCommandException>().having(
                  (e) => e.message,
                  'message',
                  contains('$status'),
                ),
              ),
            );
          },
        );

        test(
          'registerServer throws on $status and names the guild instead of '
          'completing silently',
          () async {
            final bucket = _RecordingRequestBucket()
              ..failWith = FakeResponse<dynamic>(
                status,
                {'message': 'boom'},
                bodyString: '{"message":"boom"}',
              );
            final dataStore = _RoutingDataStore(bucket);
            final marshaller = FakeMarshaller(dataStore: dataStore);
            final manager = _buildManager(
              dataStore: dataStore,
              marshaller: marshaller,
            );

            await expectLater(
              () => manager.registerServer(bot, guild),
              throwsA(
                isA<InvalidCommandException>()
                    .having((e) => e.message, 'message', contains('$status'))
                    .having(
                      (e) => e.message,
                      'message',
                      contains(guild.id.value),
                    ),
              ),
            );
          },
        );
      }
    });

    group('does not throw on success', () {
      test('registerGlobal completes on 200', () async {
        final bucket = _RecordingRequestBucket();
        final dataStore = _RoutingDataStore(bucket);
        final marshaller = FakeMarshaller(dataStore: dataStore);
        final manager = _buildManager(
          dataStore: dataStore,
          marshaller: marshaller,
        );

        await manager.registerGlobal(bot);
      });

      test('registerServer completes on 200', () async {
        final bucket = _RecordingRequestBucket();
        final dataStore = _RoutingDataStore(bucket);
        final marshaller = FakeMarshaller(dataStore: dataStore);
        final manager = _buildManager(
          dataStore: dataStore,
          marshaller: marshaller,
        );

        await manager.registerServer(bot, guild);
      });
    });

    test('preserves the structured Discord validation detail on 400', () async {
      final bucket = _RecordingRequestBucket()
        ..failWith = FakeResponse<dynamic>(400, {
          'code': 50035,
          'message': 'Invalid Form Body',
          'errors': {
            '0': {
              'name': {
                '_errors': [
                  {
                    'code': 'BASE_TYPE_BAD_LENGTH',
                    'message': 'Must be between 1 and 32 in length.',
                  },
                ],
              },
            },
          },
        });
      final dataStore = _RoutingDataStore(bucket);
      final marshaller = FakeMarshaller(dataStore: dataStore);
      final manager = _buildManager(
        dataStore: dataStore,
        marshaller: marshaller,
      );

      await expectLater(
        () => manager.registerGlobal(bot),
        throwsA(
          isA<InvalidCommandException>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('BASE_TYPE_BAD_LENGTH'),
              contains('Must be between 1 and 32 in length.'),
            ),
          ),
        ),
      );
    });

    group('end-to-end through the real RequestBucket', () {
      test(
        'registerGlobal throws on a 403 (missing applications.commands '
        'scope)',
        () async {
          final http = FakeHttpClient([
            FakeResponse<dynamic>(
              403,
              {'message': 'Missing Access', 'code': 50001},
              bodyString: '{"message":"Missing Access","code":50001}',
            ),
          ]);
          final dataStore = FakeDataStore(http);
          final marshaller = FakeMarshaller(dataStore: dataStore);
          final manager = _buildManager(
            dataStore: dataStore,
            marshaller: marshaller,
          );

          await expectLater(
            () => manager.registerGlobal(bot),
            throwsA(isA<InvalidCommandException>()),
          );
        },
      );

      test('registerServer throws on a 500 and names the guild', () async {
        final http = FakeHttpClient([
          FakeResponse<dynamic>(500, {'message': 'Internal Server Error'}),
        ]);
        final dataStore = FakeDataStore(http);
        final marshaller = FakeMarshaller(dataStore: dataStore);
        final manager = _buildManager(
          dataStore: dataStore,
          marshaller: marshaller,
        );

        await expectLater(
          () => manager.registerServer(bot, guild),
          throwsA(
            isA<InvalidCommandException>().having(
              (e) => e.message,
              'message',
              allOf(contains('500'), contains(guild.id.value)),
            ),
          ),
        );
      });

      test('registerGlobal does not throw on 200', () async {
        final http = FakeHttpClient([
          FakeResponse<dynamic>(200, const <Map<String, dynamic>>[]),
        ]);
        final dataStore = FakeDataStore(http);
        final marshaller = FakeMarshaller(dataStore: dataStore);
        final manager = _buildManager(
          dataStore: dataStore,
          marshaller: marshaller,
        );

        await manager.registerGlobal(bot);
      });
    });
  });
}
