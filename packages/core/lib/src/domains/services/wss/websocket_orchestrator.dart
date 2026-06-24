import 'dart:async';

import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/services/wss/running_strategy.dart';
import 'package:mineral/src/infrastructure/internals/wss/websocket_isolate_message_transfert.dart';

typedef RequestQueueEntry = ({
  String uid,
  List<String> targetKeys,
  Completer completer
});

abstract class WebsocketOrchestratorContract {
  List<RequestQueueEntry> get requestQueue;

  void addToRequestQueue(RequestQueueEntry entry);

  RequestQueueEntry? findInRequestQueue(String uid);

  void removeFromRequestQueue(RequestQueueEntry entry);

  ShardingConfigContract get config;

  Map<int, ShardContract> get shards;

  void send(WebsocketIsolateMessageTransfert message);

  void setBotPresence(
      List<BotActivity>? activity, StatusType? status, bool? afk);

  Future<Presence> getMemberPresence(String guildId, String id);

  Future<Map<String, dynamic>> getWebsocketEndpoint();

  Future<void> createShards(RunningStrategy strategy);
}
