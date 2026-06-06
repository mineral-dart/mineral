import 'package:env_guard/env_guard.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';

enum WebsocketEncoder implements Enumerable {
  json('json', JsonEncoderStrategy.new),
  etf('etf', EtfEncoderStrategy.new);

  @override
  final String value;

  final EncodingStrategy Function({required LoggerContract logger}) strategy;

  const WebsocketEncoder(this.value, this.strategy);
}
