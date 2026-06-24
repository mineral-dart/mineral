import 'dart:async';

import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/services/wss/running_strategy.dart';
import 'package:mineral/src/infrastructure/internals/wss/websocket_isolate_message_transfert.dart';

import 'fake_sharding_config.dart';

final class FakeWebsocketOrchestrator extends WebsocketOrchestratorContract {
  final FakeShardingConfig _config;

  FakeWebsocketOrchestrator({int maxReconnectAttempts = 3})
      : _config =
            FakeShardingConfig(maxReconnectAttempts: maxReconnectAttempts);

  @override
  final List<RequestQueueEntry> requestQueue = [];
  @override
  void addToRequestQueue(RequestQueueEntry entry) => requestQueue.add(entry);
  @override
  RequestQueueEntry? findInRequestQueue(String uid) {
    for (final entry in requestQueue) {
      if (entry.uid == uid) {
        return entry;
      }
    }
    return null;
  }

  @override
  void removeFromRequestQueue(RequestQueueEntry entry) =>
      requestQueue.remove(entry);
  @override
  ShardingConfigContract get config => _config;
  @override
  Map<int, ShardContract> get shards => {};

  @override
  Future<void> Function()? onFatalDisconnect;

  @override
  void send(WebsocketIsolateMessageTransfert message) {}
  @override
  void setBotPresence(
      List<BotActivity>? activity, StatusType? status, bool? afk) {}
  @override
  Future<Map<String, dynamic>> getWebsocketEndpoint() async => {};
  @override
  Future<void> createShards(RunningStrategy strategy) async {}
  @override
  Future<Presence> getMemberPresence(String guildId, String id) =>
      throw UnimplementedError();
}
