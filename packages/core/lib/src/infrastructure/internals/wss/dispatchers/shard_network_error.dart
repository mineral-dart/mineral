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

  /// Handles errors from fire-and-forget reconnection futures.
  ///
  /// [FatalGatewayException] → routes to [_handleFatal] (swallowed after
  /// the shutdown sequence so the error does not escape the zone).
  ///
  /// Any other error is logged and rethrown so that unexpected programming
  /// errors are not silently discarded.
  void _onReconnectError(Object error, StackTrace stack) {
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

    if (shard.authentication.intentionalDisconnect) {
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
            ).catchError(_onReconnectError),
          );
        case DisconnectAction.reconnect:
          logger.trace('Attempting full reconnect');
          shard.authentication.invalidateSession();
          unawaited(
            Future.sync(
              () => shard.authentication.reconnect(),
            ).catchError(_onReconnectError),
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
      ).catchError(_onReconnectError),
    );
  }
}
