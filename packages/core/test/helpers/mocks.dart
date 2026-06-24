import 'dart:async';

import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/api/common/bot/bot.dart';
import 'package:mineral/src/api/guild/guild.dart';
import 'package:mineral/src/domains/commands/command_builder.dart';
import 'package:mineral/src/domains/events/event_dispatcher.dart';
import 'package:mineral/src/domains/events/event_listener.dart';
import 'package:mineral/src/domains/providers/provider_manager.dart';
import 'package:mineral/src/domains/services/packets/packet_dispatcher.dart';
import 'package:mineral/src/domains/services/wss/running_strategy.dart';
import 'package:mineral/src/infrastructure/services/wss/websocket_message.dart';
import 'package:mocktail/mocktail.dart';

// ── Mocktail mocks ───────────────────────────────────────────────────────────
//
// Use these in tests that only need a no-op or verifiable dependency.
// For stateful test doubles (FakeHttpClient, FakeDataStore, etc.) see the
// other helpers in this directory.

class MockLogger extends Mock implements LoggerContract {}

class MockEventDispatcher extends Mock implements EventDispatcherContract {}

class MockEventListener extends Mock implements EventListenerContract {}

class MockPacketDispatcher extends Mock implements PacketDispatcherContract {}

class MockPacketListener extends Mock implements PacketListenerContract {}

class MockPacketType extends Mock implements PacketTypeContract {}

class MockProviderManager extends Mock implements ProviderManagerContract {}

class MockInteractiveComponentManager extends Mock
    implements InteractiveComponentManagerContract {}

class MockChannelPart extends Mock implements ChannelPartContract {}

class MockRunningStrategy extends Mock implements RunningStrategy {}

class MockHttpClient extends Mock implements HttpClientContract {}

// ── Simple fakes for abstract classes with concrete fields ───────────────────
//
// These cannot be Mocktail mocks because their base declares mutable fields.
// They are intentionally minimal.

/// A no-op [CommandInteractionManagerContract] for tests that register a
/// manager without caring about its behaviour.
final class FakeCommandInteractionManager
    extends CommandInteractionManagerContract {
  @override
  Future<void> registerGlobal(Bot bot) async {}

  @override
  Future<void> registerServer(Bot bot, Guild guild) async {}

  @override
  void addCommand(CommandBuilder command) {}

  @override
  Future<void> handleAutocomplete(Map<String, dynamic> payload) async {}
}

/// A no-op [RunningStrategy] that immediately returns from every hook.
final class FakeRunningStrategy implements RunningStrategy {
  @override
  FutureOr<void> init(RunningStrategyFactory createShards) async {}

  @override
  FutureOr<void> dispatch(WebsocketMessage message) {}
}
