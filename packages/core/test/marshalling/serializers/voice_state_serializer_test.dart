import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/api/guild/voice_state.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/cache_key.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/voice_state_serializer.dart';
import 'package:test/test.dart';

import '../../helpers/fake_cache_provider.dart';
import '../../helpers/fake_entity_context.dart';
import '../../helpers/fake_marshaller.dart';
import '../../helpers/serializer_round_trip.dart';

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

    // Mirrors the raw Voice State object Discord sends over the gateway
    // (VOICE_STATE_UPDATE) and REST (GET /guilds/{guild.id}/voice-states/{user.id}).
    // Must not be adjusted to match what the serializer currently expects —
    // see test/helpers/serializer_round_trip.dart. Notably, `discoverable`
    // is NOT a field Discord ever sends and must not appear here.
    Map<String, dynamic> rawDiscordPayload() => {
      'guild_id': '987654321',
      'channel_id': '111222333',
      'user_id': '444555666',
      'member': {
        'user': {'id': '444555666', 'username': 'voice_user'},
        'roles': <String>[],
        'joined_at': '2023-01-01T00:00:00.000000+00:00',
        'deaf': false,
        'mute': false,
      },
      'session_id': 'sess_abc123',
      'deaf': false,
      'mute': false,
      'self_deaf': true,
      'self_mute': true,
      'self_stream': true,
      'self_video': false,
      'suppress': false,
      'request_to_speak_timestamp': null,
    };

    group('serialize()', () {
      test('maps all fields correctly', () async {
        final state = await serializer.serialize(normalizedPayload());

        expect(state, isA<VoiceState>());
        expect(state.guildId, equals(Snowflake('987654321')));
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

        expect(result['guild_id'], equals(Snowflake('987654321').value));
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

      test('renames guild_id to guild_id', () async {
        final result = await serializer.normalize(rawDiscordPayload());

        expect(result, containsPair('guild_id', '987654321'));
      });
    });

    group('round-trip (normalize -> serialize)', () {
      test('produces a VoiceState from a live Discord payload', () async {
        await expectRoundTrip<VoiceState>(serializer, rawDiscordPayload(), {
          'VoiceState.guildId': (state) =>
              expect(state.guildId, equals(Snowflake('987654321'))),
          'VoiceState.channelId': (state) =>
              expect(state.channelId, equals(Snowflake('111222333'))),
          'VoiceState.userId': (state) =>
              expect(state.userId, equals(Snowflake('444555666'))),
          'VoiceState.sessionId': (state) =>
              expect(state.sessionId, equals('sess_abc123')),
          'VoiceState.isDeaf': (state) => expect(state.isDeaf, isFalse),
          'VoiceState.isMute': (state) => expect(state.isMute, isFalse),
          'VoiceState.isSelfDeaf': (state) => expect(state.isSelfDeaf, isTrue),
          'VoiceState.isSelfMute': (state) => expect(state.isSelfMute, isTrue),
          'VoiceState.hasSelfVideo': (state) =>
              expect(state.hasSelfVideo, isFalse),
          'VoiceState.isSuppress': (state) => expect(state.isSuppress, isFalse),
        });
      });

      test('handles a user who just disconnected '
          '(channelId and requestToSpeakTimestamp both null)', () async {
        final raw = rawDiscordPayload()
          ..['channel_id'] = null
          ..['request_to_speak_timestamp'] = null;

        await expectRoundTrip<VoiceState>(serializer, raw, {
          'VoiceState.channelId': (state) => expect(state.channelId, isNull),
          'VoiceState.requestToSpeakTimestamp': (state) =>
              expect(state.requestToSpeakTimestamp, isNull),
        });
      });
    });
  });
}
