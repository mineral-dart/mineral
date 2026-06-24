import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/wss/builders/discord_message_builder.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard.dart';
import 'package:mineral/src/infrastructure/io/exceptions/fatal_gateway_exception.dart';

/// Custom close code for library-internal disconnects.
/// Preserves the Discord session (unlike 1000/1001 which invalidate it).
const int _internalCloseCode = 4900;

final class ShardAuthentication implements ShardAuthenticationContract {
  final Shard shard;
  final Random _random = Random();

  int? sequence;
  String? sessionId;
  String? resumeUrl;
  int attempts = 0;
  int _reconnectAttempts = 0;
  bool _pendingResume = false;
  bool intentionalDisconnect = false;
  Timer? _heartbeatTimer;

  ShardAuthentication(this.shard);

  @override
  void identify(Map<String, dynamic> payload) {
    intentionalDisconnect = false;
    createHeartbeatTimer(payload['heartbeat_interval'] as int);

    if (_pendingResume) {
      _pendingResume = false;

      final message = ShardMessageBuilder()
        ..setOpCode(OpCode.resume)
        ..append('token', shard.wss.config.token)
        ..append('session_id', sessionId)
        ..append('seq', sequence);

      shard.client.send(message.build());
      return;
    }

    if (shard.wss.config.compress) {
      throw UnsupportedError(
        'compress: true is set but zlib-stream decompression is not implemented. '
        'Set compress: false in your ShardingConfig.',
      );
    }

    final message = ShardMessageBuilder()
      ..setOpCode(OpCode.identify)
      ..append('token', shard.wss.config.token)
      ..append('intents', shard.wss.config.intent)
      ..append('compress', false)
      ..append('large_threshold', shard.wss.config.largeThreshold)
      ..append('shard', [shard.shardIndex, shard.shardCount])
      ..append('properties', {
        'os': Platform.operatingSystem,
        'browser': 'mineral',
        'device': 'mineral',
      });

    shard.client.send(message.build());
  }

  /// Handles errors from fire-and-forget heartbeat futures.
  ///
  /// [FatalGatewayException] → cancel heartbeat, disconnect the client, and
  /// invoke [WebsocketOrchestrator.onFatalDisconnect] if available.
  ///
  /// Any other error is logged and rethrown so unexpected programming errors
  /// are not silently discarded.
  void _onHeartbeatError(Object error, StackTrace stack) {
    if (error is FatalGatewayException) {
      shard.logger.error(
          'Fatal gateway error during heartbeat: ${error.message} (${error.code}). Cannot reconnect.');
      cancelHeartbeat();
      unawaited(shard.client.disconnect());
      unawaited(shard.wss.onFatalDisconnect?.call() ?? Future<void>.value());
      return; // handled — do not propagate
    }
    shard.logger.error('Unexpected heartbeat error: $error\n$stack');
    Error.throwWithStackTrace(error, stack);
  }

  void createHeartbeatTimer(int interval) {
    _heartbeatTimer?.cancel();
    final jitterDelay =
        Duration(milliseconds: (_random.nextDouble() * interval).toInt());
    _heartbeatTimer = Timer(jitterDelay, () {
      unawaited(
        Future.sync(heartbeat).catchError(_onHeartbeatError),
      );
      _heartbeatTimer =
          Timer.periodic(Duration(milliseconds: interval), (timer) {
        unawaited(
          Future.sync(heartbeat).catchError(_onHeartbeatError),
        );
      });
    });
  }

  @override
  Future<void> heartbeat() async {
    if (attempts >= 3) {
      shard.logger.error('Heartbeat failed 3 times');
      return resetConnection();
    }

    final message = ShardMessageBuilder()
      ..setOpCode(OpCode.heartbeat)
      ..setPayload(sequence);
    await shard.client.send(message.build());

    attempts++;
  }

  @override
  void ack() {
    shard.logger.trace('Received heartbeat ack');
    attempts = 0;
  }

  @override
  Future<void> connect() => shard.client.connect();

  void cancelHeartbeat() {
    _heartbeatTimer?.cancel();
  }

  Duration _backoffDelay() {
    final maxDelay = shard.wss.config.maxReconnectDelay;
    final baseSeconds =
        min(pow(2, _reconnectAttempts).toInt(), maxDelay.inSeconds);
    final jitter = Duration(milliseconds: _random.nextInt(1000));
    return Duration(seconds: baseSeconds) + jitter;
  }

  Future<void> _reconnectWithStrategy({
    required String action,
    bool resume = false,
    String? url,
  }) async {
    final logger = shard.logger;
    final maxAttempts = shard.wss.config.maxReconnectAttempts;

    cancelHeartbeat();
    if (resume) {
      _pendingResume = true;
    }
    attempts = 0;
    intentionalDisconnect = true;
    await shard.client.disconnect(code: _internalCloseCode);

    _reconnectAttempts++;

    if (_reconnectAttempts > maxAttempts) {
      logger.error(
          'Max reconnect attempts ($maxAttempts) reached for ${shard.shardName}');
      throw FatalGatewayException(
        'Max reconnect attempts ($maxAttempts) reached',
        -1,
      );
    }

    final delay = _backoffDelay();
    logger.warn(
        '$action ${shard.shardName} in ${delay.inSeconds}s (attempt $_reconnectAttempts/$maxAttempts)');
    await Future<void>.delayed(delay);

    await shard.init(url: url);
  }

  @override
  Future<void> reconnect() => _reconnectWithStrategy(action: 'Reconnecting');

  Future<void> resetConnection() =>
      _reconnectWithStrategy(action: 'Resetting connection for');

  @override
  Future<void> resume() =>
      _reconnectWithStrategy(action: 'Resuming', resume: true, url: resumeUrl);

  void resetReconnectAttempts() {
    _reconnectAttempts = 0;
  }

  void invalidateSession() {
    sessionId = null;
    resumeUrl = null;
  }

  @override
  void setupRequirements(Map<String, dynamic> payload) {
    _reconnectAttempts = 0;
    sessionId = payload['session_id'] as String?;
    resumeUrl = payload['resume_gateway_url'] as String?;
  }
}
