import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class VoiceChannelEffectSendPacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.voiceChannelEffectSend;

  final DataStoreContract _dataStore;

  VoiceChannelEffectSendPacket({required DataStoreContract dataStore})
    : _dataStore = dataStore;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final payload = message.payload as Map<String, dynamic>;

    final guildId = payload['guild_id'] as String;
    final channelId = payload['channel_id'] as String;
    final userId = payload['user_id'] as String;

    final guild = await _dataStore.guild.get(guildId, false);
    final channel = await _dataStore.channel.get<GuildChannel>(
      channelId,
      false,
    );
    final member = await _dataStore.member.get(guildId, userId, false);

    if (channel == null || member == null) {
      return;
    }

    final emojiPayload = payload['emoji'] as Map<String, dynamic>?;
    final PartialEmoji? emoji = emojiPayload != null
        ? PartialEmoji(
            Snowflake.nullable(emojiPayload['id']),
            (emojiPayload['name'] as String?) ?? '',
            (emojiPayload['animated'] as bool?) ?? false,
          )
        : null;

    final animationTypeRaw = payload['animation_type'] as int?;
    final VoiceChannelEffectAnimationType? animationType =
        animationTypeRaw != null
        ? VoiceChannelEffectAnimationType.values.firstWhere(
            (e) => e.value == animationTypeRaw,
            orElse: () => VoiceChannelEffectAnimationType.basic,
          )
        : null;

    final animationId = payload['animation_id'] as int?;

    final soundIdRaw = payload['sound_id'];
    final Snowflake? soundId = soundIdRaw != null
        ? Snowflake.parse(soundIdRaw)
        : null;

    final soundVolume = payload['sound_volume'] as double?;

    dispatch<GuildVoiceChannelEffectSendArgs>(
      event: Event.guildVoiceChannelEffectSend,
      payload: (
        guild: guild,
        channel: channel,
        member: member,
        emoji: emoji,
        animationType: animationType,
        animationId: animationId,
        soundId: soundId,
        soundVolume: soundVolume,
      ),
    );
  }
}
