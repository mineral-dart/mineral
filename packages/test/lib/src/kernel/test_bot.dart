import 'package:mineral/contracts.dart';
import 'package:mineral/mineral_testing.dart';

import '../data_store/test_data_store_facade.dart';
import '../payloads/test_payloads.dart';
import '../recorders/bot_actions.dart';
import '../recorders/handler_error.dart';
import '../simulators/registries.dart';
import 'test_bot_events.dart';
import 'test_kernel.dart';

/// In-memory Mineral bot for integration tests.
///
/// `TestBot` boots a [TestKernel] (no WebSocket, no HTTP) and exposes the
/// command/component/event registration surface plus simulators and
/// recorders. The recording HTTP client lives at the bottom of the stack, so
/// any handler that calls into the IoC-resolved `DataStoreContract` (sending
/// messages, banning members, assigning roles) shows up under `bot.actions`.
final class TestBot {
  final TestKernel _kernel;

  /// Captured logger, useful for asserting on log output.
  FakeLogger get logger => _kernel.logger;

  /// Mineral's slash command registry — accepts real `CommandBuilder`s from
  /// the bot under test for completeness, but most testing happens through
  /// the framework-friendly [BotEvents] façade.
  final CommandInteractionManagerContract commands;

  /// Mineral's component registry (buttons, modals, select menus).
  final InteractiveComponentManagerContract components;

  /// Test-friendly event/listener registry — `bot.events.register(...)`.
  final BotEvents events;

  /// Aggregated, human-readable view of every recorded side-effect.
  BotActions get actions => _kernel.actions;

  /// Errors raised by command/event/component handlers.
  List<HandlerError> get errors => List.unmodifiable(_errors);

  /// In-memory data store for assertions and seeding.
  final TestDataStoreFacade dataStore;

  /// Mutable backing store for [errors] — populated by simulators.
  final List<HandlerError> _errors;

  final Simulator _simulator;

  TestBot._(
    this._kernel,
    this.commands,
    this.components,
    this.events,
    this.dataStore,
    this._errors,
    this._simulator,
  );

  /// Boots the kernel and resolves the manager contracts.
  static Future<TestBot> create() async {
    final kernel = TestKernel.boot();
    final registry = ListenerRegistry();
    final errors = <HandlerError>[];
    final simulator = Simulator(registry, errors);
    final dataStore = TestDataStoreFacade(kernel.actions);

    return TestBot._(
      kernel,
      kernel.container.resolve<CommandInteractionManagerContract>(),
      kernel.container.resolve<InteractiveComponentManagerContract>(),
      BotEvents(registry),
      dataStore,
      errors,
      simulator,
    );
  }

  // -------- simulators --------

  Future<void> simulateMemberJoin({
    required TestMember member,
    required TestGuild guild,
  }) => _simulator.simulateMemberJoin(member, guild);

  Future<void> simulateCommand(
    String name, {
    required TestUser invokedBy,
    Map<String, Object?> options = const {},
    // ignore: non_constant_identifier_names
    TestGuild? in_,
  }) => _simulator.simulateCommand(
    name: name,
    options: options,
    invokedBy: invokedBy,
    guild: in_,
  );

  Future<void> simulateButton(
    String customId, {
    required TestUser clickedBy,
    // ignore: non_constant_identifier_names
    TestGuild? in_,
  }) => _simulator.simulateButton(
    customId: customId,
    clickedBy: clickedBy,
    guild: in_,
  );

  Future<void> simulateModalSubmit(
    String customId, {
    required TestUser submittedBy,
    Map<String, String> fields = const {},
    // ignore: non_constant_identifier_names
    TestGuild? in_,
  }) => _simulator.simulateModalSubmit(
    customId: customId,
    fields: fields,
    submittedBy: submittedBy,
    guild: in_,
  );

  /// Tears down the kernel and restores the previous global IoC container.
  Future<void> dispose() => _kernel.dispose();
}
