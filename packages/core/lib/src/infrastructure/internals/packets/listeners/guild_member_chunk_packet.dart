import 'dart:async';

import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/api/common/presence.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class GuildMemberChunkPacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.guildMemberChunk;

  final MarshallerContract _marshaller;
  final DataStoreContract _dataStore;
  final WebsocketOrchestratorContract _wss;

  GuildMemberChunkPacket({
    required MarshallerContract marshaller,
    required DataStoreContract dataStore,
    required WebsocketOrchestratorContract wss,
  }) : _marshaller = marshaller,
       _dataStore = dataStore,
       _wss = wss;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final payload = message.payload as Map<String, dynamic>;
    final guild = await _dataStore.guild.get(
      payload['guild_id'] as String,
      false,
    );

    final members = await List.from(payload['members'] as Iterable<dynamic>)
        .map((element) async {
          final raw = await _marshaller.serializers.member.normalize({
            ...(element as Map<String, dynamic>),
            'guild_id': guild.id.value,
          });

          return _marshaller.serializers.member.serialize(raw);
        })
        .wait;

    final presences = List<Map<String, dynamic>>.from(
      payload['presences'] as Iterable<dynamic>,
    ).map(Presence.fromJson).toList();

    final resolver = _wss.findInRequestQueue(payload['nonce'] as String);
    if (resolver != null && !resolver.completer.isCompleted) {
      if (resolver.targetKeys.length == 1 &&
          resolver.targetKeys.contains('presences')) {
        resolver.completer.complete(presences.first);
      }

      if (resolver.targetKeys.length == 1 &&
          resolver.targetKeys.contains('members')) {
        resolver.completer.complete(presences.first);
      }

      if (resolver.targetKeys.contains('members') &&
          resolver.targetKeys.contains('presences')) {
        resolver.completer.complete({
          'members': members,
          'presences': presences,
        });
      }

      _wss.removeFromRequestQueue(resolver);
    }

    dispatch<GuildMemberChunkArgs>(
      event: Event.guildMemberChunk,
      payload: (guild: guild, members: members),
    );
  }
}
