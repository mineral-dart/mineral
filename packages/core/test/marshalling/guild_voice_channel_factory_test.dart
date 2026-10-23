import 'package:mineral/api.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/channel_serializer.dart';
import 'package:test/test.dart';

import '../helpers/fake_cache_provider.dart';
import '../helpers/fake_entity_context.dart';
import '../helpers/fake_marshaller.dart';

Map<String, dynamic> _voiceState(String guildId, String userId) => {
  'guild_id': guildId,
  'channel_id': '100',
  'user_id': userId,
  'session_id': 'session',
  'deaf': false,
  'mute': false,
  'self_deaf': false,
  'self_mute': false,
  'self_video': false,
  'suppress': false,
  'request_to_speak_timestamp': null,
};

void main() {
  group('GuildVoiceChannelFactory', () {
    test(
      'serialize ignores voice states of guilds sharing an id prefix',
      () async {
        final cache = FakeCacheProvider();
        final marshaller = FakeMarshaller(cache: cache);
        final serializer = ChannelSerializer(marshaller, fakeEntityContext());

        final index = marshaller.serializers.voiceStateIndex;
        final voice = marshaller.serializers.voice;
        await voice.normalize(_voiceState('123', '1'));
        await voice.normalize(_voiceState('1234', '2'));
        await index.add('123', 'ghost');

        final channel =
            await serializer.serialize({
                  'id': '100',
                  'type': 2,
                  'name': 'voice',
                  'position': 1,
                  'guild_id': '123',
                  'parent_id': null,
                  'permission_overwrites': [],
                })
                as GuildVoiceChannel;

        expect(channel.members, hasLength(1));
        expect(channel.members.single.userId, equals(Snowflake('1')));
      },
    );

    test('serialize skips members on another channel', () async {
      final cache = FakeCacheProvider();
      final marshaller = FakeMarshaller(cache: cache);
      final serializer = ChannelSerializer(marshaller, fakeEntityContext());
      await marshaller.serializers.voice.normalize({
        ..._voiceState('123', '1'),
        'channel_id': '200',
      });

      final channel =
          await serializer.serialize({
                'id': '100',
                'type': 2,
                'name': 'voice',
                'position': 1,
                'guild_id': '123',
                'parent_id': null,
                'permission_overwrites': [],
              })
              as GuildVoiceChannel;

      expect(channel.members, isEmpty);
    });
  });
}
