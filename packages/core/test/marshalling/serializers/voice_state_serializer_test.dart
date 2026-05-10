import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/api/server/voice_state.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/cache_key.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/voice_state_serializer.dart';
import 'package:test/test.dart';

import '../../helpers/fake_cache_provider.dart';
import '../../helpers/fake_entity_context.dart';
import '../../helpers/fake_marshaller.dart';

void main() {
  group('VoiceStateSerializer', () {
    late VoiceStateSerializer serializer;
    late FakeCacheProvider cache;

    setUp(() {
      cache = FakeCacheProvider();
      serializer = VoiceStateSerializer(
        FakeMarshaller(cache: cache),
        fakeEntityContext(),
      );
    });

    Map<String, dynamic> normalizedPayload() => {
          'server_id': '987654321',
          'channel_id': '111222333',
          'user_id': '444555666',
          'session_id': 'sess_abc123',
          'deaf': false,
          'mute': false,
          'self_deaf': true,
          'self_mute': true,
          'self_video': false,
          'suppress': false,
          'request_to_speak_timestamp': null,
          'discoverable': true,
        };

    Map<String, dynamic> rawDiscordPayload() => {
          'guild_id': '987654321',
          'channel_id': '111222333',
          'user_id': '444555666',
          'session_id': 'sess_abc123',
          'deaf': false,
          'mute': false,
          'self_deaf': true,
          'self_mute': true,
          'self_video': false,
          'suppress': false,
          'request_to_speak_timestamp': null,
          'discoverable': true,
        };

    group('serialize()', () {
      test('maps all fields correctly', () async {
        final state = await serializer.serialize(normalizedPayload());

        expect(state, isA<VoiceState>());
        expect(state.serverId, equals(Snowflake('987654321')));
        expect(state.channelId, equals(Snowflake('111222333')));
        expect(state.userId, equals(Snowflake('444555666')));
        expect(state.sessionId, equals('sess_abc123'));
        expect(state.isDeaf, isFalse);
        expect(state.isMute, isFalse);
        expect(state.isSelfDeaf, isTrue);
        expect(state.isSelfMute, isTrue);
        expect(state.hasSelfVideo, isFalse);
        expect(state.isSuppress, isFalse);
        expect(state.requestToSpeakTimestamp, isNull);
        expect(state.isDiscoverable, isTrue);
      });

      test('handles nullable channelId', () async {
        final payload = normalizedPayload()..['channel_id'] = null;
        final state = await serializer.serialize(payload);

        expect(state.channelId, isNull);
      });

      test('parses requestToSpeakTimestamp when present', () async {
        final ts = '2024-01-15T10:30:00.000Z';
        final payload = normalizedPayload()
          ..['request_to_speak_timestamp'] = ts;
        final state = await serializer.serialize(payload);

        expect(state.requestToSpeakTimestamp, isA<DateTime>());
        expect(state.requestToSpeakTimestamp, equals(DateTime.parse(ts)));
      });
    });

    group('deserialize()', () {
      test('produces map with expected keys', () async {
        final state = await serializer.serialize(normalizedPayload());
        final result = serializer.deserialize(state);

        expect(result['server_id'], equals(Snowflake('987654321').value));
        expect(result['channel_id'], equals(Snowflake('111222333').value));
        expect(result['user_id'], equals(Snowflake('444555666').value));
        expect(result['session_id'], equals('sess_abc123'));
        expect(result['deaf'], isFalse);
        expect(result['mute'], isFalse);
        expect(result['self_deaf'], isTrue);
        expect(result['self_mute'], isTrue);
        expect(result['suppress'], isFalse);
        expect(result['discoverable'], isTrue);
      });

      test('serializes nullable channelId as null', () async {
        final payload = normalizedPayload()..['channel_id'] = null;
        final state = await serializer.serialize(payload);
        final result = serializer.deserialize(state);

        expect(result['channel_id'], isNull);
      });

      // Anomaly: deserialize writes 'self_stream' but serialize reads 'self_video'
      test('writes self_stream key instead of self_video', () async {
        final state = await serializer.serialize(normalizedPayload());
        final result = serializer.deserialize(state);

        expect(result.containsKey('self_stream'), isTrue);
        expect(result.containsKey('self_video'), isFalse);
      });
    });

    group('normalize()', () {
      test('writes to cache with voiceState key', () async {
        await serializer.normalize(rawDiscordPayload());

        final expectedKey = CacheKey().voiceState('987654321', '444555666');
        expect(cache.store.containsKey(expectedKey), isTrue);
      });

      test('renames guild_id to server_id', () async {
        final result = await serializer.normalize(rawDiscordPayload());

        expect(result, containsPair('server_id', '987654321'));
        expect(result.containsKey('guild_id'), isFalse);
      });
    });
  });
}
