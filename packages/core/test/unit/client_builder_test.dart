import 'dart:io';

import 'package:mineral/api.dart';
import 'package:mineral/container.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/domains/client/client_builder.dart';
import 'package:mineral/src/domains/common/kernel.dart';
import 'package:mineral/src/domains/services/packets/packet_dispatcher.dart';
import 'package:test/test.dart';

import '../helpers/fake_cache_provider.dart';
import '../helpers/fake_logger.dart';

// Regression coverage for the composition root (issue #479 / A26).
//
// `ClientBuilder.build()` used to be the only path through this wiring, and
// it read the process-global `env` and wrote the process-global `ioc`
// directly — there was no way to construct the graph in a test and inspect
// it. `composeApp` (declared alongside `build()` in `client_builder.dart`)
// is the extracted seam: it takes an `Env` as an explicit argument, builds
// the exact same object graph, and returns it instead of mutating globals.
//
// The two things this file exists to catch are the two genuine construction
// cycles `composeApp` closes by hand:
//   1. `WebsocketOrchestrator.onFatalDisconnect` <-> `Kernel`
//   2. `PacketListener.kernel` / `PacketListener.init()` <-> `Kernel`
// If either regresses, the graph still *constructs* successfully — it just
// silently never dispatches a gateway packet. "It returned an object" is
// not a sufficient assertion for that failure mode, so every test below
// checks the actual wiring, not just successful construction.

/// A minimal `.env` fixture satisfying `AppEnv`'s schema (see
/// `lib/src/infrastructure/internals/environment/app_env.dart`).
const _validEnvContents =
    'DART_ENV=development\n'
    'TOKEN=unit-test-token\n'
    'DISCORD_REST_API_VERSION=10\n'
    'DISCORD_WS_VERSION=10\n'
    'INTENT=53608447\n'
    'LOG_LEVEL=INFO\n';

/// Builds a fresh, fully-validated [Env] instance — never the process-global
/// `env` singleton — from a temp `.env` file, and schedules the temp
/// directory for deletion once the current test finishes.
///
/// This is exactly what the acceptance criteria for #479 ask for: composeApp
/// must be callable from a test with an injected [Env], without touching
/// process globals. If composeApp silently fell back to reading the
/// process-global `env` instead of the instance passed to it, every test
/// below would throw instead of passing, because the global `env` is never
/// touched here.
Env _isolatedEnv() {
  final tempDir = Directory.systemTemp.createTempSync('client_builder_test');
  addTearDown(() => tempDir.deleteSync(recursive: true));

  File('${tempDir.path}/.env').writeAsStringSync(_validEnvContents);

  final env = Env()..defineOf(AppEnv.new, root: tempDir, includeDartEnv: false);
  return env;
}

/// Seeds the process-global `env` singleton the way a real bot's startup
/// does, for the duration of [body], without touching the real process
/// working directory or leaving files in the repo.
///
/// `ClientBuilder.build()` always validates against the global `env`
/// (`_validateEnvironment()` calls `env.defineOf(AppEnv.new)` unconditionally,
/// with no way to inject an override) — that coupling is exactly what
/// `composeApp` exists to avoid, but `build()` itself, being the thin
/// adapter, still has it. [IOOverrides.runZoned] lets `env_guard`'s
/// file-based loader see a temp directory as `Directory.current` — confined
/// to this zone — instead of either mutating the real CWD (process-global,
/// unsafe with concurrent test isolates) or writing a `.env` file into the
/// repo itself.
Future<T> _withGlobalEnv<T>(Future<T> Function() body) {
  final tempDir = Directory.systemTemp.createTempSync(
    'client_builder_build_test',
  );
  addTearDown(() {
    env.dispose();
    tempDir.deleteSync(recursive: true);
  });
  File('${tempDir.path}/.env').writeAsStringSync(_validEnvContents);

  return IOOverrides.runZoned(body, getCurrentDirectory: () => tempDir);
}

void main() {
  group('composeApp', () {
    test('closes the WebsocketOrchestrator <-> Kernel cycle '
        '(onFatalDisconnect)', () {
      final composition = composeApp(env: _isolatedEnv());

      expect(composition.wss.onFatalDisconnect, isNotNull);
      // Instance-method tear-offs of the same receiver are `==`-equal in
      // Dart; this fails if the hook were left unset (null) or wired to
      // some other kernel's dispose.
      expect(
        composition.wss.onFatalDisconnect,
        equals(composition.kernel.dispose),
      );
    });

    test('closes the PacketListener <-> Kernel cycle and runs init()', () {
      final composition = composeApp(env: _isolatedEnv());

      expect(
        identical(composition.packetListener.kernel, composition.kernel),
        isTrue,
        reason: "PacketListener.kernel must point at this graph's Kernel",
      );

      // `dispatcher` is a `late final` field only assigned inside
      // PacketListener.init(). If init() were dropped (or called before
      // `kernel` was wired, since init() reads `kernel.logger`/`kernel.wss`
      // to subscribe every packet), accessing it throws instead of
      // returning normally — that's the exact "constructs fine, never
      // dispatches a packet" failure mode this card is about.
      expect(() => composition.packetListener.dispatcher, returnsNormally);
      expect(
        composition.packetListener.dispatcher,
        isA<PacketDispatcherContract>(),
      );
    });

    test('wires the same instances everywhere — no dependency silently '
        'swapped for the wrong module', () {
      final composition = composeApp(env: _isolatedEnv());

      expect(composition.appState.kernel, same(composition.kernel));
      expect(composition.appState.wss, same(composition.wss));
      expect(composition.appState.dataStore, same(composition.dataStore));
      expect(composition.appState.marshaller, same(composition.marshaller));
      expect(
        composition.appState.packetListener,
        same(composition.packetListener),
      );

      expect(
        composition.packetListener.marshaller,
        same(composition.marshaller),
      );
      expect(composition.packetListener.dataStore, same(composition.dataStore));
      expect(
        composition.packetListener.commandManager,
        same(composition.appState.commandManager),
      );
      expect(
        composition.packetListener.cacheConfig,
        same(composition.appState.cacheConfig),
      );
      expect(composition.kernel.wss, same(composition.wss));
      expect(
        composition.kernel.packetListener,
        same(composition.packetListener),
      );
    });

    test('an injected logger is used verbatim, including for labelled '
        'subsystem loggers', () {
      final logger = FakeLogger();
      final composition = composeApp(env: _isolatedEnv(), logger: logger);

      expect(composition.appState.logger, same(logger));
      expect(composition.kernel.logger, same(logger));
    });

    test('an injected cache flows into both the data layer and AppState', () {
      final cache = FakeCacheProvider();
      final composition = composeApp(env: _isolatedEnv(), cache: cache);

      expect(composition.appState.cache, same(cache));
      expect(composition.marshaller.cache, same(cache));
    });

    test('threads env-derived config into the constructed graph', () {
      final composition = composeApp(env: _isolatedEnv());

      expect(composition.wss.config.token, 'unit-test-token');
      expect(composition.wss.config.intent, 53608447);
    });

    test(
      'never reads or writes the global ioc container (pure composition)',
      () {
        final before = ioc.services.length;

        composeApp(env: _isolatedEnv());

        expect(ioc.services.length, before);
      },
    );

    test('two calls produce two fully independent graphs', () {
      final a = composeApp(env: _isolatedEnv());
      final b = composeApp(env: _isolatedEnv());

      expect(identical(a.kernel, b.kernel), isFalse);
      expect(identical(a.packetListener, b.packetListener), isFalse);
      expect(identical(a.wss, b.wss), isFalse);
    });
  });

  group('ClientBuilder.build() — thin adapter over composeApp', () {
    test('stays synchronous and returns a Client', () async {
      await _withGlobalEnv(() async {
        return runWithIoc(IocContainer(), () async {
          final builder = ClientBuilder()..setLogger((_) => FakeLogger());

          // `Client build()` — not `Future<Client> build()` — is a
          // deliberate, recorded design decision (async setup belongs in
          // Client.init()). This is enforced at compile time by the
          // declared return type, and checked here at runtime too.
          expect(builder.build, isA<Client Function()>());
          expect(builder.build(), isA<Client>());
        });
      });
    });

    test('mirrors the composed graph into the IoC container', () async {
      await _withGlobalEnv(() async {
        return runWithIoc(IocContainer(), () async {
          final logger = FakeLogger();
          final client = (ClientBuilder()..setLogger((_) => logger)).build();

          expect(ioc.resolve<LoggerContract>(), same(logger));
          expect(ioc.resolve<Kernel>().logger, same(logger));
          expect(ioc.resolve<DataStoreContract>(), same(client.rest));
          expect(() => ioc.resolve<MarshallerContract>(), returnsNormally);
          expect(
            () => ioc.resolve<CommandInteractionManagerContract>(),
            returnsNormally,
          );
          expect(
            () => ioc.resolve<WebsocketOrchestratorContract>(),
            returnsNormally,
          );
          expect(
            () => ioc.resolve<InteractiveComponentManagerContract>(),
            returnsNormally,
          );
          expect(() => ioc.resolve<HttpClientContract>(), returnsNormally);
        });
      });
    });

    test('still registers builder providers, handed the fully-constructed '
        'client', () async {
      await _withGlobalEnv(() async {
        return runWithIoc(IocContainer(), () async {
          final calls = <String>[];
          Client? receivedClient;

          (ClientBuilder()
                ..setLogger((_) => FakeLogger())
                ..registerProvider((client) {
                  receivedClient = client;
                  return _RecordingProvider(() => calls.add('ready'));
                }))
              .build();

          expect(receivedClient, isA<Client>());

          // ProviderManager.register() has no externally-observable
          // effect until ready() runs — call it directly (no gateway
          // connection needed) to prove the provider this test registered
          // was actually handed to the manager, not just constructed and
          // discarded.
          await ioc.resolve<Kernel>().providerManager.ready();
          expect(calls, ['ready']);
        });
      });
    });
  });
}

final class _RecordingProvider implements ProviderContract {
  _RecordingProvider(this._onReady);

  final void Function() _onReady;

  @override
  Future<void> ready() async => _onReady();

  @override
  Future<void> dispose() async {}
}
