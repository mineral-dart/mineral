import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/runtime_state.dart';

/// Bundle of dependencies injected into Discord entities (Member, Role,
/// Guild, Channel, Message, …) at construction by the marshaller's
/// serializers.
///
/// Entities receive this bundle via their constructor and read
/// `_ctx.datastore` / `_ctx.wss` / `_ctx.runtimeState` rather than reaching
/// into the global IoC. New shared dependencies for entities should be
/// added here so that all entity constructors stay narrow.
///
/// [runtimeState] holds the bot identity and other late-bound runtime data;
/// see [RuntimeState] for the lifecycle.
final class EntityContext {
  final DataStoreContract datastore;
  final WebsocketOrchestratorContract wss;
  final LoggerContract logger;
  final RuntimeState runtimeState;

  const EntityContext({
    required this.datastore,
    required this.wss,
    required this.logger,
    required this.runtimeState,
  });
}
