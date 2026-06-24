import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/api/guild/invite.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/cache_key.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/invite_serializer.dart';
import 'package:test/test.dart';

import '../../helpers/fake_cache_provider.dart';
import '../../helpers/fake_entity_context.dart';
import '../../helpers/fake_marshaller.dart';

void main() {
  group('InviteSerializer', () {
    late InviteSerializer serializer;
    late FakeCacheProvider cache;

    setUp(() {
      cache = FakeCacheProvider();
      serializer = InviteSerializer(
        FakeMarshaller(cache: cache),
        fakeEntityContext(),
      );
    });

    Map<String, dynamic> normalizedPayload() => {
          'channelId': '111222333',
          'code': 'abc123',
          'createdAt': '2024-01-15T10:30:00.000Z',
          'expiresAt': '2024-01-16T10:30:00.000Z',
          'guildId': '987654321',
          'inviterId': '444555666',
          'maxAge': 86400,
          'maxUses': 10,
          'temporary': false,
          'type': 0,
        };

    Map<String, dynamic> rawDiscordPayload() => {
          'channel_id': '111222333',
          'code': 'abc123',
          'created_at': '2024-01-15T10:30:00.000Z',
          'expires_at': '2024-01-16T10:30:00.000Z',
          'guild_id': '987654321',
          'inviter': {'id': '444555666'},
          'max_age': 86400,
          'max_uses': 10,
          'temporary': false,
          'type': 0,
        };

    group('serialize()', () {
      test('maps all fields correctly', () async {
        final invite = await serializer.serialize(normalizedPayload());

        expect(invite, isA<Invite>());
        expect(invite.code, equals('abc123'));
        expect(invite.type, equals(InviteType.guild));
        expect(invite.channelId, equals(Snowflake('111222333')));
        expect(invite.guildId, equals(Snowflake('987654321')));
        expect(invite.inviterId, equals(Snowflake('444555666')));
        expect(invite.maxAge, equals(Duration(seconds: 86400)));
        expect(invite.maxUses, equals(10));
        expect(invite.isTemporary, isFalse);
        expect(invite.createdAt,
            equals(DateTime.parse('2024-01-15T10:30:00.000Z')));
      });

      test('handles nullable expiresAt', () async {
        final payload = normalizedPayload()..['expiresAt'] = null;
        final invite = await serializer.serialize(payload);

        expect(invite.expiresAt, isNull);
      });

      test('parses expiresAt when present', () async {
        final invite = await serializer.serialize(normalizedPayload());

        expect(invite.expiresAt, isA<DateTime>());
        expect(invite.expiresAt,
            equals(DateTime.parse('2024-01-16T10:30:00.000Z')));
      });
    });

    group('deserialize()', () {
      test('produces map with expected keys', () async {
        final invite = await serializer.serialize(normalizedPayload());
        final result = serializer.deserialize(invite);

        expect(result['code'], equals('abc123'));
        expect(result['type'], equals(InviteType.guild.value));
        expect(result['maxAge'], equals(86400));
        expect(result['maxUses'], equals(10));
        expect(result['temporary'], isFalse);
      });
    });

    group('normalize()', () {
      // Anomaly: normalize uses cacheKey.voiceState() instead of cacheKey.invite()
      test('writes to cache', () async {
        await serializer.normalize(rawDiscordPayload());

        final expectedKey = CacheKey().voiceState('987654321', '444555666');
        expect(cache.store.containsKey(expectedKey), isTrue);
      });

      test('renames Discord keys to internal keys', () async {
        final result = await serializer.normalize(rawDiscordPayload());

        expect(result['channelId'], equals('111222333'));
        expect(result['guildId'], equals('987654321'));
        expect(result['inviterId'], equals('444555666'));
        expect(result['code'], equals('abc123'));
        expect(result['maxAge'], equals(86400));
        expect(result['maxUses'], equals(10));
      });
    });

    group('round-trip', () {
      test('serialize then deserialize preserves key data', () async {
        final json = normalizedPayload();
        final invite = await serializer.serialize(json);
        final result = serializer.deserialize(invite);

        expect(result['code'], equals(json['code']));
        expect(result['maxUses'], equals(json['maxUses']));
        expect(result['temporary'], equals(json['temporary']));
        expect(result['type'], equals(json['type']));
      });
    });
  });
}
