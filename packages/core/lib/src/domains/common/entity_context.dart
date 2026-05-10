import 'package:mineral/contracts.dart';

/// Bundle of dependencies injected into Discord entities (Member, Role,
/// Server, Channel, Message, …) at construction by the marshaller's
/// serializers.
///
/// Entities receive this bundle via their constructor and read
/// `_ctx.datastore` / `_ctx.wss` rather than reaching into the global IoC.
/// New shared dependencies for entities should be added here so that all
/// entity constructors stay narrow.
final class EntityContext {
  final DataStoreContract datastore;
  final WebsocketOrchestratorContract wss;
  final LoggerContract logger;

  const EntityContext({
    required this.datastore,
    required this.wss,
    required this.logger,
  });
}
