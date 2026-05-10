import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/components/component_context.dart';
import 'package:mineral/src/domains/services/interactions/interaction_contract.dart';
import 'package:mineral/src/infrastructure/internals/interactions/interaction.dart';

abstract class ComponentContextBase implements ComponentContext {
  @override
  final Snowflake id;

  @override
  final Snowflake applicationId;

  @override
  final String token;

  @override
  final int version;

  @override
  final String customId;

  /// Entity context required to construct [Interaction]; subclasses
  /// (button/select/modal contexts) pass their own [EntityContext.ctx]
  /// through `super.ctx`.
  final EntityContext ctx;

  @override
  late final InteractionContract interaction = Interaction(
    token,
    id,
    datastore: ctx.datastore,
    runtimeState: ctx.runtimeState,
  );

  ComponentContextBase({
    required this.id,
    required this.applicationId,
    required this.token,
    required this.version,
    required this.customId,
    required this.ctx,
  });
}
