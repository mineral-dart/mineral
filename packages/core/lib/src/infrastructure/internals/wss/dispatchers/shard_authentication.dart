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

  /// True only for the brief window in which [_reconnectWithStrategy] is
  /// closing the *current* socket to start a reconnect/resume attempt.
  /// It masks the close/error events that self-disconnect triggers so they
  /// are not mistaken for a fresh, externally-caused disconnect.
  ///
  /// It must NOT stay true for the duration of the whole reconnect attempt:
  /// if the *new* connection then fails (e.g. `WebsocketClientImpl.connect`
  /// swallowing a `SocketException` and reporting it as a close), that
  /// close needs to reach [ShardNetworkErrorContract.dispatch] so another
  /// reconnect gets scheduled — otherwise the shard goes silently dead
  /// after a single failed attempt (see chantier A5).
  bool intentionalDisconnect = false;

  /// True once the process has begun a deliberate, permanent teardown
  /// (e.g. `Kernel.dispose`). Distinct from [intentionalDisconnect] on
  /// purpose: that flag is transient and cleared automatically after every
  /// reconnect attempt, while this one is meant to stay true for good and
  /// suppress any further reconnect scheduling once set. Nothing in this
  /// file's scope currently sets it — wiring it from `Kernel.dispose` is a
  /// follow-up outside this chantier's file scope.
  bool shuttingDown = false;

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

  void createHeartbeatTimer(int interval) {
    _heartbeatTimer?.cancel();
    final jitterDelay = Duration(
      milliseconds: (_random.nextDouble() * interval).toInt(),
    );
    _heartbeatTimer = Timer(jitterDelay, () {
      unawaited(
        Future.sync(heartbeat).catchError(shard.networkError.onReconnectError),
      );
      _heartbeatTimer = Timer.periodic(Duration(milliseconds: interval), (
        timer,
      ) {
        unawaited(
          Future.sync(
            heartbeat,
          ).catchError(shard.networkError.onReconnectError),
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
    final baseSeconds = min(
      pow(2, _reconnectAttempts).toInt(),
      maxDelay.inSeconds,
    );
    final jitter = Duration(milliseconds: _random.nextInt(1000));
    return Duration(seconds: baseSeconds) + jitter;
  }

  /// Builds a full gateway URL (host + `?v=` + `encoding=`), mirroring the
  /// formula `WebsocketOrchestrator.createShards` uses for the initial
  /// connection. Discord's `resume_gateway_url` (unlike the `/gateway/bot`
  /// endpoint) is returned WITHOUT a query string, so [resume] must reapply
  /// these params itself or every reconnect after a resume silently loses
  /// version/encoding negotiation (chantier A6) — most visibly with
  /// `encoding=etf`, where Discord then falls back to JSON text frames that
  /// [EtfEncoderStrategy] cannot decode.
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

    // Only mask the close/error events caused by disconnecting the
    // *current* socket below — not the outcome of the new connection
    // attempt further down. See the `intentionalDisconnect` doc comment.
    intentionalDisconnect = true;
    try {
      await shard.client.disconnect(code: _internalCloseCode);
    } finally {
      intentionalDisconnect = false;
    }

    _reconnectAttempts++;

    if (_reconnectAttempts > maxAttempts) {
      logger.error(
        'Max reconnect attempts ($maxAttempts) reached for ${shard.shardName}',
      );
      throw FatalGatewayException(
        'Max reconnect attempts ($maxAttempts) reached',
        -1,
      );
    }

    final delay = _backoffDelay();
    logger.warn(
      '$action ${shard.shardName} in ${delay.inSeconds}s (attempt $_reconnectAttempts/$maxAttempts)',
    );
    await Future<void>.delayed(delay);

    // `url` is only ever passed explicitly by `resume()` (the bare
    // `resume_gateway_url`); `reconnect()`/`resetConnection()` pass none and
    // fall back to the shard's existing (already fully-qualified) `url`.
    await shard.init(
      url: url != null ? shard.wss.config.gatewayUrl(url) : null,
    );
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
