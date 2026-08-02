import 'dart:async';

import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/services/wss/constants/shard_disconnect_error.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard.dart';
import 'package:mineral/src/infrastructure/io/exceptions/fatal_gateway_exception.dart';

final class ShardNetworkError implements ShardNetworkErrorContract {
  final Shard shard;

  ShardNetworkError(this.shard);

  // ── Fatal-path helpers ─────────────────────────────────────────────────────

  /// Performs the fatal shutdown sequence: cancel heartbeat, disconnect the
  /// client, and invoke [WebsocketOrchestrator.onFatalDisconnect] if set.
  /// Nothing is thrown — the error is fully handled here.
  void _handleFatal(FatalGatewayException e) {
    shard.logger.error(
      'Fatal gateway error: ${e.message} (${e.code}). Cannot reconnect.',
    );
    shard.authentication.cancelHeartbeat();
    unawaited(shard.client.disconnect());
    unawaited(shard.wss.onFatalDisconnect?.call() ?? Future<void>.value());
  }

  /// Shared fire-and-forget error policy for every entry point that kicks
  /// off a reconnect/resume/heartbeat [Future] without awaiting it: the
  /// network-error [dispatch] paths below, [Shard]'s opcode handlers
  /// (OpCode.reconnect / OpCode.invalidSession / OpCode.heartbeat), and
  /// [ShardAuthenticationContract]'s heartbeat timer. Centralised here so
  /// every one of those call sites applies the same policy instead of each
  /// re-implementing (and subtly diverging from) fatal-error handling.
  ///
  /// [FatalGatewayException] → routes to [_handleFatal] (swallowed after
  /// the shutdown sequence so the error does not escape the zone).
  ///
  /// Any other error is logged and rethrown so that unexpected programming
  /// errors are not silently discarded.
  void onReconnectError(Object error, StackTrace stack) {
    if (error is FatalGatewayException) {
      _handleFatal(error);
      return; // handled — do not propagate
    }
    shard.logger.error('Unexpected reconnect error: $error\n$stack');
    Error.throwWithStackTrace(error, stack);
  }

  // ── Public dispatch ────────────────────────────────────────────────────────

  @override
  void dispatch(dynamic payload) {
    if (payload == null) {
      return;
    }

    // `intentionalDisconnect` masks the brief, self-inflicted close of the
    // *current* socket while a reconnect attempt is starting up.
    // `shuttingDown` is the separate, permanent concern of a deliberate
    // process-level teardown (e.g. Kernel.dispose) — the two used to share
    // one boolean, which is what let a failed reconnect attempt mask its
    // own retry (see A5). Keep them distinct even though only the first is
    // wired up from within this file's scope today.
    if (shard.authentication.intentionalDisconnect ||
        shard.authentication.shuttingDown) {
      return;
    }

    final logger = shard.logger;

    final ShardDisconnectError? error = ShardDisconnectError.values
        .where((element) => element.code == payload)
        .firstOrNull;

    if (error != null) {
      logger.warn('WebSocket closed with code ${error.code}: ${error.message}');

      switch (error.action) {
        case DisconnectAction.resume:
          logger.trace('Attempting to resume session');
          unawaited(
            Future.sync(
              () => shard.authentication.resume(),
            ).catchError(onReconnectError),
          );
        case DisconnectAction.reconnect:
          logger.trace('Attempting full reconnect');
          shard.authentication.invalidateSession();
          unawaited(
            Future.sync(
              () => shard.authentication.reconnect(),
            ).catchError(onReconnectError),
          );
        case DisconnectAction.fatal:
          _handleFatal(FatalGatewayException(error.message, error.code));
      }
      return;
    }

    logger.warn(
      'WebSocket closed with unknown code: $payload. Attempting reconnect.',
    );
    shard.authentication.invalidateSession();
    unawaited(
      Future.sync(
        () => shard.authentication.reconnect(),
      ).catchError(onReconnectError),
    );
  }
}
