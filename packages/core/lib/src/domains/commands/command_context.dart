import 'package:mineral/src/api/common/channel.dart';
import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/services/interactions/interaction_contract.dart';
import 'package:mineral/src/infrastructure/internals/interactions/interaction.dart';

abstract class CommandContext {
  final Snowflake id;
  final Snowflake applicationId;
  final String token;
  final int version;

  /// The channel in which the command was invoked, if available.
  final Channel? channel;

  /// Entity context required to construct [Interaction]; subclasses pass
  /// their own [EntityContext] through `super.ctx`.
  final EntityContext ctx;

  late final InteractionContract interaction = Interaction(
    token,
    id,
    datastore: ctx.datastore,
    runtimeState: ctx.runtimeState,
  );

  CommandContext({
    required this.id,
    required this.applicationId,
    required this.token,
    required this.version,
    required this.ctx,
    this.channel,
  });
}
