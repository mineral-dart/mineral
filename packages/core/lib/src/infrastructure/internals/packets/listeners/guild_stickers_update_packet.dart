import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/services/cache/cache_invalidation.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class GuildStickersUpdatePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.guildStickersUpdate;

  final MarshallerContract _marshaller;
  final DataStoreContract _dataStore;

  GuildStickersUpdatePacket({
    required MarshallerContract marshaller,
    required DataStoreContract dataStore,
  })  : _marshaller = marshaller,
        _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final guild =
        await _dataStore.guild.get(message.payload['guild_id'] as Object, false);

    final stickers =
        await List.from(message.payload['stickers'] as Iterable<dynamic>).map((element) async {
      final raw = await _marshaller.serializers.sticker.normalize({
        'guild_id': guild.id,
        ...(element as Map<String, dynamic>),
      });

      return _marshaller.serializers.sticker.serialize(raw);
    }).wait;

    final freshKeys = stickers
        .map((s) =>
            _marshaller.cacheKey.sticker(guild.id.value, s.id.value))
        .toSet();
    final cachedKeys = (await _marshaller.cache
                ?.whereKeyStartsWith('${_marshaller.cacheKey.guild(guild.id.value)}/stickers/'))
            ?.keys
            .toSet() ??
        const <String>{};
    for (final key in cachedKeys.difference(freshKeys)) {
      await _marshaller.cache.invalidate(key);
    }

    dispatch<GuildStickersUpdateArgs>(event: Event.guildStickersUpdate, payload: (
      guild: guild,
      stickers: stickers.asMap().map((_, value) => MapEntry(value.id, value)),
    ));
  }
}
