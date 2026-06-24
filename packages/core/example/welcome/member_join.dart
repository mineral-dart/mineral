import 'package:mineral/api.dart';
import 'package:mineral/events.dart';

final class MemberJoin extends GuildMemberAddEvent {
  @override
  Future<void> handle(Member member, Guild guild) async {
    final systemChannel = await guild.channels.resolveSystemChannel();
    if (systemChannel == null) {
      return;
    }

    final displayName = member.nickname ?? member.globalName ?? member.username;

    final message =
        MessageBuilder.text('👋 Welcome to **${guild.name}**, $displayName!')
          ..addButton(
            Button.primary(
              'welcome:${member.id.value}',
              label: 'Say hello',
              emoji: PartialEmoji.fromUnicode('🎉'),
            ),
          );

    await systemChannel.send(message);
  }
}
