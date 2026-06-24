enum DisconnectAction { resume, reconnect, fatal }

enum ShardDisconnectError {
  // Standard WebSocket close codes -> reconnect
  normal(1000, 'Normal', DisconnectAction.reconnect),
  goingAway(1001, 'Going away', DisconnectAction.reconnect),
  disconnect(1002, 'Disconnect', DisconnectAction.reconnect),
  invalidData(1003, 'Invalid contracts', DisconnectAction.reconnect),
  noStatusReceived(1005, 'No status received', DisconnectAction.reconnect),
  abnormalClosure(1006, 'Abnormal closure', DisconnectAction.reconnect),
  policyViolation(1008, 'Policy violation', DisconnectAction.reconnect),
  tooBig(1009, 'Message too big', DisconnectAction.reconnect),
  extensionRequired(1010, 'Extension required', DisconnectAction.reconnect),
  unexpectedCondition(1011, 'Unexpected condition', DisconnectAction.reconnect),
  serviceRestart(1012, 'Service restart', DisconnectAction.reconnect),
  tryAgainLater(1013, 'Try again later', DisconnectAction.reconnect),
  invalidTls(1015, 'Invalid TLS', DisconnectAction.reconnect),

  // Discord resumable codes -> resume
  unknownError(4000, 'Unknown error', DisconnectAction.resume),
  unknownOpCode(4001, 'Unknown opcode', DisconnectAction.resume),
  decodeError(4002, 'Decode error', DisconnectAction.resume),
  notAuthenticated(4003, 'Not authenticated', DisconnectAction.resume),
  alreadyAuthenticated(
    4005,
    'Already authenticated',
    DisconnectAction.reconnect,
  ),
  invalidSequence(4007, 'Invalid sequence', DisconnectAction.resume),
  rateLimited(4008, 'Rate limited', DisconnectAction.resume),
  sessionTimeout(4009, 'Session timed out', DisconnectAction.resume),

  // Discord fatal codes -> fatal
  authenticationFailed(4004, 'Authentication failed', DisconnectAction.fatal),
  invalidShard(4010, 'Invalid shard', DisconnectAction.fatal),
  shardingRequired(4011, 'Sharding required', DisconnectAction.fatal),
  invalidApiVersion(4012, 'Invalid API version', DisconnectAction.fatal),
  invalidIntents(4013, 'Invalid intent(s)', DisconnectAction.fatal),
  disallowedIntents(4014, 'Disallowed intent(s)', DisconnectAction.fatal);

  final int code;
  final String message;
  final DisconnectAction action;

  const ShardDisconnectError(this.code, this.message, this.action);
}
