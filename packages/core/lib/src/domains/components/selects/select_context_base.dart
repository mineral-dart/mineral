import 'dart:async';

import 'package:mineral/api.dart';

/// Shared base for select-menu interaction contexts.
///
/// Provides the [messageId] and [channelId] fields shared by both server and
/// private select interactions.
///
/// Concrete subclasses narrow the return type of [resolveMessage] to the
/// context-appropriate message interface ([PrivateMessage] or [ServerMessage])
/// via Dart's covariant return type mechanism.
///
/// `resolveChannel` is intentionally left to each subclass because the
/// server variant exposes a generic `resolveChannel<T extends Channel>()`
/// signature that cannot share a non-generic abstract declaration.
abstract class SelectContextBase extends ComponentContextBase
    implements SelectContext {
  final Snowflake? messageId;
  final Snowflake? channelId;

  SelectContextBase({
    required super.id,
    required super.applicationId,
    required super.token,
    required super.version,
    required super.customId,
    required this.messageId,
    required this.channelId,
    required super.ctx,
  });

  /// Resolves the message that triggered this select interaction, if available.
  ///
  /// Returns [PrivateMessage] in [PrivateSelectContext] and [ServerMessage]
  /// in [ServerSelectContext].
  FutureOr<BaseMessage?> resolveMessage({bool force = false});
}
