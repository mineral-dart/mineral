import 'package:mineral/contracts.dart';

enum WsEncoder {
  json('json'),
  etf('etf');

  final String value;
  const WsEncoder(this.value);
}

abstract interface class ShardingConfigContract {
  String get token;

  int get intent;

  bool get compress;

  int get version;

  EncodingStrategy get encoding;

  int get largeThreshold;

  int? get shardCount;

  int get maxReconnectAttempts;

  Duration get maxReconnectDelay;
}

/// Builds the gateway websocket URL for a given endpoint.
///
/// Lives here rather than at the call sites because both the initial connect
/// (`WebsocketOrchestrator.createShards`) and the resume path
/// (`ShardAuthentication`) need the identical query string. Discord returns
/// `resume_gateway_url` bare, so the resume path has to rebuild it — and when
/// the two formulas were written out separately, the resume copy silently
/// dropped `?v=` and `encoding=`. With `encoding=etf` that made Discord fall
/// back to JSON text frames the ETF decoder could not read, leaving the shard
/// permanently deaf.
extension GatewayUrlBuilder on ShardingConfigContract {
  String gatewayUrl(String endpoint) =>
      '$endpoint/?v=$version&encoding=${encoding.encoder.value}';
}
