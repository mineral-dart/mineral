import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

/// Shared base for button interaction contexts.
///
/// Holds the [channelId] and [messageId] that are common to both server and
/// private button interactions, and provides the default [resolveChannel] /
/// [resolveMessage] implementations that return the more-specific sub-types
/// in concrete subclasses via covariant return types.
abstract class ButtonContextBase extends ComponentContextBase
    implements ButtonContext {
  final EntityContext ctx;
  DataStoreContract get _dataStore => ctx.datastore;

  final Snowflake channelId;
  final Snowflake messageId;

  ButtonContextBase({
    required super.id,
    required super.applicationId,
    required super.token,
    required super.version,
    required super.customId,
    required this.channelId,
    required this.messageId,
    required this.ctx,
  });

  Future<ServerChannel> resolveChannel({bool force = false}) async {
    final channel =
        await _dataStore.channel.get<ServerChannel>(channelId.value, force);
    return channel!;
  }

  Future<ServerMessage> resolveMessage({bool force = false}) async {
    final message = await _dataStore.message
        .get<ServerMessage>(channelId.value, messageId.value, force);
    return message!;
  }
}
