import 'package:mineral/events.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/user_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:test/test.dart';

import '../helpers/fake_cache_provider.dart';
import '../helpers/fake_marshaller.dart';

void main() {
  group('UserUpdatePacket', () {
    late FakeCacheProvider cache;
    late FakeMarshaller marshaller;
    late UserUpdatePacket packet;

    /// A minimal raw Discord USER_UPDATE payload.
    Map<String, dynamic> rawPayload() => {
          'id': '123456789',
          'username': 'updated_user',
          'discriminator': '0042',
          'flags': 0,
          'public_flags': 0,
          'avatar': null,
          'bot': false,
          'system': false,
          'mfa_enabled': false,
          'locale': null,
          'verified': false,
          'email': null,
          'premium_type': null,
          'avatar_decoration_data': null,
          'banner': null,
        };

    ShardMessage<dynamic> buildMessage(Map<String, dynamic> payload) =>
        ShardMessage(
          type: 'USER_UPDATE',
          opCode: OpCode.dispatch,
          sequence: 1,
          payload: payload,
        );

    setUp(() {
      cache = FakeCacheProvider();
      marshaller = FakeMarshaller(cache: cache);
      packet = UserUpdatePacket(marshaller: marshaller);
    });

    test('packetType is PacketType.userUpdate', () {
      expect(packet.packetType.name, equals('USER_UPDATE'));
    });

    test('dispatches Event.userUpdate with a correctly-deserialized after user',
        () async {
      Event? capturedEvent;
      Object? capturedPayload;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
        capturedPayload = payload;
      }

      await packet.listen(buildMessage(rawPayload()), dispatch);

      expect(capturedEvent, equals(Event.userUpdate));

      final args = capturedPayload as UserUpdateArgs;
      expect(args.after.id, equals('123456789'));
      expect(args.after.username, equals('updated_user'));
      expect(args.after.discriminator, equals('0042'));
    });

    test('before is null when user is not in cache', () async {
      UserUpdateArgs? capturedArgs;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedArgs = payload as UserUpdateArgs;
      }

      await packet.listen(buildMessage(rawPayload()), dispatch);

      expect(capturedArgs, isNotNull);
      expect(capturedArgs!.before, isNull);
    });

    test('before is populated when user is already in cache', () async {
      // Pre-populate the cache with the old user state.
      final userCacheKey = marshaller.cacheKey.user('123456789');
      await cache.put(userCacheKey, {
        'id': '123456789',
        'username': 'old_user',
        'discriminator': '0001',
        'flags': 0,
        'public_flags': 0,
        'avatar': null,
        'is_bot': false,
        'system': false,
        'mfa_enabled': false,
        'locale': null,
        'verified': false,
        'email': null,
        'premium_type': null,
        'assets': {
          'user_id': '123456789',
          'avatar': null,
          'avatar_decoration': null,
          'banner': null,
        },
      });

      UserUpdateArgs? capturedArgs;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedArgs = payload as UserUpdateArgs;
      }

      await packet.listen(buildMessage(rawPayload()), dispatch);

      expect(capturedArgs, isNotNull);
      expect(capturedArgs!.before, isNotNull);
      expect(capturedArgs!.before!.username, equals('old_user'));
      expect(capturedArgs!.after.username, equals('updated_user'));
    });

    test('updates cache with new user data after dispatch', () async {
      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {}

      await packet.listen(buildMessage(rawPayload()), dispatch);

      final userCacheKey = marshaller.cacheKey.user('123456789');
      final cached = await cache.get(userCacheKey);

      expect(cached, isNotNull);
      expect(cached!['username'], equals('updated_user'));
    });
  });
}
