import 'dart:async';
import 'dart:convert';

import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/domains/services/wss/running_strategy.dart';
import 'package:mineral/src/infrastructure/internals/wss/builders/discord_message_builder.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard.dart';
import 'package:mineral/src/infrastructure/internals/wss/websocket_isolate_message_transfert.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();
const _requestQueueTtl = Duration(seconds: 30);

final class WebsocketOrchestrator implements WebsocketOrchestratorContract {
  final List<RequestQueueEntry> _requestQueue = [];

  @override
  List<RequestQueueEntry> get requestQueue => List.unmodifiable(_requestQueue);

  @override
  void addToRequestQueue(RequestQueueEntry entry) {
    _requestQueue.add(entry);
  }

  @override
  RequestQueueEntry? findInRequestQueue(String uid) {
    for (final entry in _requestQueue) {
      if (entry.uid == uid) {
        return entry;
      }
    }
    return null;
  }

  @override
  void removeFromRequestQueue(RequestQueueEntry entry) {
    _requestQueue.remove(entry);
  }

  void _addToRequestQueueWithTtl(RequestQueueEntry entry) {
    addToRequestQueue(entry);
    Future.delayed(_requestQueueTtl, () {
      final stale = findInRequestQueue(entry.uid);
      if (stale != null) {
        removeFromRequestQueue(stale);
        if (!stale.completer.isCompleted) {
          stale.completer.completeError(
            TimeoutException(
              'Request queue entry ${stale.uid} timed out',
              _requestQueueTtl,
            ),
          );
        }
      }
    });
  }

  final HttpClientContract _httpClient;

  final LoggerContract _logger;

  @override
  final ShardingConfigContract config;

  @override
  final Map<int, Shard> shards = {};

  /// Callback invoked by [Shard] when the gateway closes with a fatal code.
  /// Set by [Kernel] after construction to break the otherwise-circular
  /// dependency between the orchestrator (built first) and the kernel
  /// (built later, owns dispose).
  @override
  Future<void> Function()? onFatalDisconnect;

  WebsocketOrchestrator(
    this.config, {
    required LoggerContract logger,
    required HttpClientContract httpClient,
  }) : _logger = logger,
       _httpClient = httpClient;

  @override
  void send(WebsocketIsolateMessageTransfert message) {
    _logger.trace('Sending message to all shards ${message.toJson()}');

    return switch (message.type) {
      MessageTransfertType.send => _sendToShards(message),
      MessageTransfertType.request => _requestMessage(message),
      _ => _logger.warn('Unknown message transfert type ${message.type}'),
    };
  }

  void _sendToShards(WebsocketIsolateMessageTransfert message) {
    shards.forEach(
      (_, shard) => shard.client.send(json.encode(message.payload)),
    );
  }

  void _requestMessage(WebsocketIsolateMessageTransfert message) {
    _addToRequestQueueWithTtl((
      uid: message.uid!,
      targetKeys: message.targetKeys,
      completer: message.completer!,
    ));

    _sendToShards(message);
  }

  @override
  void setBotPresence(
    List<BotActivity>? activities,
    StatusType? status,
    bool? afk,
  ) {
    final message = ShardMessageBuilder()
      ..setOpCode(OpCode.presenceUpdate)
      ..append(
        'since',
        afk == true ? DateTime.now().millisecondsSinceEpoch : null,
      )
      ..append(
        'activities',
        activities != null
            ? activities.map((element) => element.toJson()).toList()
            : [],
      )
      ..append(
        'status',
        status != null ? status.toString() : StatusType.online.toString(),
      )
      ..append('afk', afk ?? false);

    send(WebsocketIsolateMessageTransfert.send(message.toJson()));
  }

  /// Returns the shard index responsible for a given guild.
  /// Formula: shard_id = (guild_id >> 22) % num_shards
  int _shardForGuild(String guildId) {
    final id = BigInt.parse(guildId);
    if (shards.isEmpty) {
      return 0;
    }
    return ((id >> 22) % BigInt.from(shards.length)).toInt();
  }

  @override
  Future<Presence> getMemberPresence(String guildId, String id) {
    final completer = Completer<Presence>();
    final uid = _uuid.v4();
    final message = ShardMessageBuilder()
      ..setOpCode(OpCode.requestGuildMember)
      ..append('guild_id', guildId)
      ..append('user_ids', [id])
      ..append('limit', 0)
      ..append('presences', true)
      ..append('nonce', uid);

    final targetIndex = _shardForGuild(guildId);
    final targetShard = shards[targetIndex];

    if (targetShard != null) {
      _addToRequestQueueWithTtl((
        uid: uid,
        targetKeys: ['presences'],
        completer: completer,
      ));
      targetShard.client.send(json.encode(message.toJson()));
    } else {
      _logger.warn(
        'Shard $targetIndex not found for guild $guildId, broadcasting',
      );
      send(
        WebsocketIsolateMessageTransfert.request(
          payload: message.toJson(),
          uid: uid,
          completer: completer,
          targetKeys: ['presences'],
        ),
      );
    }

    return completer.future;
  }

  @override
  Future<Map<String, dynamic>> getWebsocketEndpoint() async {
    final request = Request.json(endpoint: '/gateway/bot');
    final response = await _httpClient.get(request);

    return switch (response.statusCode) {
      int() when _httpClient.status.isSuccess(response.statusCode) =>
        response.body as Map<String, dynamic>,
      int() when _httpClient.status.isError(response.statusCode) =>
        throw TokenException('This token is invalid or expired'),
      _ => throw HttpStatusException(response.statusCode, response.bodyString),
    };
  }

  @override
  Future<void> createShards(RunningStrategy strategy) async {
    final response = await getWebsocketEndpoint();

    final endpoint = response['url'];
    if (endpoint is! String) {
      throw StateError('Gateway response missing valid "url" field: $response');
    }
    final shardCount = response['shards'];
    if (shardCount is! int) {
      throw StateError(
        'Gateway response missing valid "shards" field: $response',
      );
    }

    final sessionLimit =
        response['session_start_limit'] as Map<String, dynamic>?;
    final int remaining = (sessionLimit?['remaining'] as int?) ?? 1;
    final int resetAfter = (sessionLimit?['reset_after'] as int?) ?? 0;
    final int maxConcurrency = (sessionLimit?['max_concurrency'] as int?) ?? 1;

    _logger.trace(
      'Gateway session_start_limit: remaining=$remaining, '
      'reset_after=${resetAfter}ms, max_concurrency=$maxConcurrency',
    );

    if (remaining <= 0) {
      throw StateError(
        'No remaining gateway sessions. Reset after ${resetAfter}ms.',
      );
    }

    final totalShards = config.shardCount ?? shardCount;

    for (int bucket = 0; bucket < totalShards; bucket += maxConcurrency) {
      if (bucket > 0) {
        await Future<void>.delayed(const Duration(seconds: 5));
      }

      final end = (bucket + maxConcurrency).clamp(0, totalShards);
      for (int i = bucket; i < end; i++) {
        final url =
            '$endpoint/?v=${config.version}&encoding=${config.encoding.encoder.value}';

        final shard = Shard(
          shardName: 'shard #$i',
          shardIndex: i,
          shardCount: totalShards,
          url: url,
          wss: this,
          logger: _logger,
          strategy: strategy,
        );

        shards.putIfAbsent(i, () => shard);

        await shard.init();
      }
    }
  }
}
