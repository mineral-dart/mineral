import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/api/common/bot/bot.dart';
import 'package:mineral/src/domains/commands/command_interaction_manager.dart';
import 'package:mineral/src/domains/common/kernel.dart';
import 'package:mineral/src/domains/events/event_listener.dart';
import 'package:mineral/src/domains/global_states/global_state_manager.dart';
import 'package:mineral/src/domains/providers/provider_manager.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/ready_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_listener.dart';

/// Aggregate of every framework service produced by [ClientBuilder.build]
/// (defined in `client_builder.dart`). Built once in the Composition Root,
/// passed around the core, and mirrored into the IoC container for end-user
/// DX.
///
/// The core itself never reads from the IoC — internal classes receive their
/// dependencies through constructors. The IoC mirror exists purely so user
/// handlers, commands, and providers can keep using
/// `container.resolve<T>()` to look up framework services.
final class AppState {
  final LoggerContract logger;
  final HttpClientContract httpClient;
  final CacheProviderContract? cache;
  final CacheConfig cacheConfig;
  final MarshallerContract marshaller;
  final DataStoreContract dataStore;
  final WebsocketOrchestratorContract wss;
  final PacketListenerContract packetListener;
  final EventListenerContract eventListener;
  final ProviderManagerContract providerManager;
  final GlobalStateManager globalState;
  final InteractiveComponentManagerContract interactiveComponent;
  final CommandInteractionManagerContract commandManager;
  final Kernel kernel;

  /// Bot identity, populated by [ReadyPacket] once the gateway sends READY.
  /// Null until then; downstream packet listeners that need it (e.g.
  /// `GuildCreatePacket`) read this slot at runtime.
  Bot? bot;

  /// HMR-only: most recent READY message, replayed on reload by
  /// [HmrRunningStrategy].
  ReadyPacketMessage? readyPacketMessage;

  AppState({
    required this.logger,
    required this.httpClient,
    required this.cache,
    required this.cacheConfig,
    required this.marshaller,
    required this.dataStore,
    required this.wss,
    required this.packetListener,
    required this.eventListener,
    required this.providerManager,
    required this.globalState,
    required this.interactiveComponent,
    required this.commandManager,
    required this.kernel,
  });
}
