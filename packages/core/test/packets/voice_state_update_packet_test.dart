import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/voice_state_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../helpers/fake_cache_provider.dart';
import '../helpers/fake_marshaller.dart';
import '../helpers/fake_websocket_orchestrator.dart';
import '../helpers/mocks.dart';
import 'helpers/packet_test_helpers.dart';

const _guildId = '123456789012345678';
const _userId = '111222333444555666';
const _channelA = '900000000000000001';
const _channelB = '900000000000000002';

final class _SpyCache extends Mock implements CacheProviderContract {}

Map<String, dynamic> _state(String? channelId, {bool mute = false}) => {
  'guild_id': _guildId,
  'channel_id': channelId,
  'user_id': _userId,
  'session_id': 'session',
  'deaf': false,
  'mute': mute,
  'self_deaf': false,
  'self_mute': false,
  'self_video': false,
  'suppress': false,
  'request_to_speak_timestamp': null,
};

ShardMessage<dynamic> _msg(Map<String, dynamic> payload) => ShardMessage(
  type: 'VOICE_STATE_UPDATE',
  opCode: OpCode.dispatch,
  sequence: 1,
  payload: payload,
);

void main() {
  late FakeCacheProvider fake;
  late _SpyCache cache;
  late FakeMarshaller marshaller;
  late VoiceStateUpdatePacket packet;
  late String key;
  late List<(Event, Object)> events;

  void dispatch<T extends Object>({
    required Event event,
    required T payload,
    bool Function(String?)? constraint,
  }) {
    events.add((event, payload));
  }

  List<Event> names() => events.map((e) => e.$1).toList();

  setUp(() {
    final wss = FakeWebsocketOrchestrator();
    fake = FakeCacheProvider();
    cache = _SpyCache();
    when(() => cache.config).thenReturn(fake.config);
    when(
      () => cache.get(any()),
    ).thenAnswer((i) => fake.get(i.positionalArguments[0] as String?));
    when(() => cache.put<Map<String, dynamic>>(any(), any())).thenAnswer(
      (i) => fake.put(
        i.positionalArguments[0] as String,
        i.positionalArguments[1],
      ),
    );
    when(
      () => cache.remove(any()),
    ).thenAnswer((i) => fake.remove(i.positionalArguments[0] as String));
    final dataStore = MockDataStore();
    marshaller = FakeMarshaller(
      cache: cache,
      entityContext: buildCtx(dataStore: dataStore, wss: wss),
    );
    packet = VoiceStateUpdatePacket(marshaller: marshaller);
    key = marshaller.cacheKey.voiceState(_guildId, _userId);
    events = [];
  });

  test('packetType is PacketType.voiceStateUpdate', () {
    expect(packet.packetType, equals(PacketType.voiceStateUpdate));
  });

  test(
    'connect: fires connect, join and stateUpdate and caches state',
    () async {
      await packet.listen(_msg(_state(_channelA)), dispatch);

      expect(
        names(),
        equals([Event.voiceConnect, Event.voiceJoin, Event.voiceStateUpdate]),
      );
      final connect = events.first.$2 as VoiceConnectArgs;
      expect(connect.state.channelId!.value, equals(_channelA));
      expect(fake.store[key], isNotNull);
    },
  );

  test(
    'move: fires join, move, stateUpdate, leave with before/after',
    () async {
      fake.store[key] = _state(_channelA);

      await packet.listen(_msg(_state(_channelB)), dispatch);

      expect(
        names(),
        equals([
          Event.voiceJoin,
          Event.voiceMove,
          Event.voiceStateUpdate,
          Event.voiceLeave,
        ]),
      );
      final move = events[1].$2 as VoiceMoveArgs;
      expect(move.before!.channelId!.value, equals(_channelA));
      expect(move.after.channelId!.value, equals(_channelB));
      final leave = events[3].$2 as VoiceLeaveArgs;
      expect(leave.state.channelId!.value, equals(_channelA));
    },
  );

  test('move keeps the new state in the cache', () async {
    fake.store[key] = _state(_channelA);

    await packet.listen(_msg(_state(_channelB)), dispatch);

    expect(fake.store[key]['channel_id'], equals(_channelB));
  });

  test('same channel update: move and stateUpdate only', () async {
    fake.store[key] = _state(_channelA);

    await packet.listen(_msg(_state(_channelA, mute: true)), dispatch);

    expect(names(), equals([Event.voiceMove, Event.voiceStateUpdate]));
    expect(fake.store[key]['mute'], isTrue);
  });

  test(
    'disconnect: fires disconnect, leave, stateUpdate and invalidates',
    () async {
      fake.store[key] = _state(_channelA);

      await packet.listen(_msg(_state(null)), dispatch);

      expect(
        names(),
        equals([
          Event.voiceDisconnect,
          Event.voiceLeave,
          Event.voiceStateUpdate,
        ]),
      );
      final disconnect = events.first.$2 as VoiceDisconnectArgs;
      expect(disconnect.state.channelId!.value, equals(_channelA));
      expect(fake.store.containsKey(key), isFalse);
      verifyNever(() => cache.put<Map<String, dynamic>>(key, any()));
    },
  );

  test('disconnect without cached state only fires stateUpdate', () async {
    await packet.listen(_msg(_state(null)), dispatch);

    expect(names(), equals([Event.voiceStateUpdate]));
  });

  test('reads the cache once and writes at most once per event', () async {
    fake.store[key] = _state(_channelA);
    await packet.listen(_msg(_state(_channelB)), dispatch);
    verify(() => cache.get(key)).called(1);
    verify(() => cache.put<Map<String, dynamic>>(key, any())).called(1);

    clearInteractions(cache);
    await packet.listen(_msg(_state(null)), dispatch);
    verify(() => cache.get(key)).called(1);
    verifyNever(() => cache.put<Map<String, dynamic>>(key, any()));
  });

  test('connect adds the member to the guild index', () async {
    await packet.listen(_msg(_state(_channelA)), dispatch);

    final indexKey = marshaller.cacheKey.voiceStateIndex(_guildId);
    expect(fake.store[indexKey]['members'], equals([_userId]));
  });

  test('disconnect removes the member from the guild index', () async {
    await packet.listen(_msg(_state(_channelA)), dispatch);
    await packet.listen(_msg(_state(null)), dispatch);

    final indexKey = marshaller.cacheKey.voiceStateIndex(_guildId);
    expect(fake.store[indexKey]['members'], isEmpty);
  });
}
