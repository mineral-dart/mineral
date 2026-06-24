import 'package:mineral/contracts.dart';

final class FakeShardingConfig implements ShardingConfigContract {
  final int _maxReconnectAttempts;

  FakeShardingConfig({int maxReconnectAttempts = 3})
    : _maxReconnectAttempts = maxReconnectAttempts;

  @override
  String get token => 'fake-token';
  @override
  int get intent => 513;
  @override
  bool get compress => false;
  @override
  int get version => 10;
  @override
  EncodingStrategy get encoding => throw UnimplementedError();
  @override
  int get largeThreshold => 50;
  @override
  int? get shardCount => 1;
  @override
  int get maxReconnectAttempts => _maxReconnectAttempts;
  @override
  Duration get maxReconnectDelay => Duration.zero;
}
