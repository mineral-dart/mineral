import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/services/cache/cache_invalidation.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class GuildEmojisUpdatePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.guildEmojisUpdate;

  final MarshallerContract _marshaller;
  final DataStoreContract _dataStore;

  GuildEmojisUpdatePacket({
    required MarshallerContract marshaller,
    required DataStoreContract dataStore,
  })  : _marshaller = marshaller,
        _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final server =
        await _dataStore.server.get(message.payload['guild_id'] as Object, false);

    final emojis =
        await List.from(message.payload['emojis'] as Iterable<dynamic>).map((element) async {
      final raw = await _marshaller.serializers.emojis.normalize({
        ...(element as Map<String, dynamic>),
        'guild_id': server.id.value,
      });
      return _marshaller.serializers.emojis.serialize(raw);
    }).wait;

    final freshKeys = emojis
        .map((e) =>
            _marshaller.cacheKey.serverEmoji(server.id.value, e.id!.value))
        .toSet();
    final cachedKeys = (await _marshaller.cache
                ?.whereKeyStartsWith('${_marshaller.cacheKey.server(server.id.value)}/emojis/'))
            ?.keys
            .toSet() ??
        const <String>{};
    for (final key in cachedKeys.difference(freshKeys)) {
      await _marshaller.cache.invalidate(key);
    }

    dispatch<ServerEmojisUpdateArgs>(event: Event.serverEmojisUpdate, payload: (
      emojis: Map.fromEntries(emojis.map((e) => MapEntry(e.id!, e))),
      server: server,
    ));
  }
}
