import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/api/guild/invite.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/cache_key.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/invite_serializer.dart';
import 'package:test/test.dart';

import '../../helpers/fake_cache_provider.dart';
import '../../helpers/fake_entity_context.dart';
import '../../helpers/fake_marshaller.dart';
import '../../helpers/serializer_round_trip.dart';

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

    // Mirrors Discord's actual Invite object wire format — see
    // https://discord.com/developers/docs/resources/invite#invite-object —
    // as returned by `GET /invites/{code}`, the payload InvitePart.get()
    // hands to normalize(). Discord nests `guild` and `channel` as (partial)
    // objects and never sends a flat `guild_id`/`channel_id` string; `guild`
    // is absent on group-DM invites and `inviter` is absent on vanity
    // invites. This must NOT be adjusted to match what
    // invite_serializer.dart reads — the fixture has to stay Discord's
    // shape so the test proves what the serializer does with real traffic,
    // not what the serializer wishes it received.
    Map<String, dynamic> rawDiscordPayload() => {
      'type': 0,
      'code': 'abc123',
      'guild': {
        'id': '987654321',
        'name': 'Test Guild',
        'splash': null,
        'banner': null,
        'description': null,
        'icon': null,
        'features': <String>[],
        'verification_level': 0,
        'vanity_url_code': null,
        'nsfw_level': 0,
      },
      'channel': {'id': '111222333', 'name': 'general', 'type': 0},
      'inviter': {
        'id': '444555666',
        'username': 'inviter_user',
        'discriminator': '0',
        'avatar': null,
      },
      'approximate_presence_count': 5,
      'approximate_member_count': 42,
      'expires_at': '2024-01-16T10:30:00.000Z',
    };

    // Mirrors Discord's INVITE_CREATE gateway event payload — see
    // https://discord.com/developers/docs/events/gateway-events#invite-create
    // — which is what InviteCreatePacket (invite_create_packet.dart:18) hands
    // straight to normalize(). This is a genuinely different wire shape from
    // the REST Invite object above: it carries a flat, top-level `guild_id`
    // (optional — absent for group-DM invites) and `channel_id`, plus
    // `inviter` (optional), `max_age`, `max_uses`, `temporary` and `uses`.
    // Do not merge this with rawDiscordPayload() — the two payload shapes
    // are not interchangeable and invite_serializer.dart:31-33 behaves
    // differently against each.
    Map<String, dynamic> rawGatewayInviteCreatePayload() => {
      'channel_id': '111222333',
      'code': 'abc123',
      'created_at': '2024-01-15T10:30:00.000Z',
      'guild_id': '987654321',
      'inviter': {
        'id': '444555666',
        'username': 'inviter_user',
        'discriminator': '0',
        'avatar': null,
      },
      'max_age': 86400,
      'max_uses': 10,
      'temporary': false,
      'uses': 0,
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
        expect(
          invite.createdAt,
          equals(DateTime.parse('2024-01-15T10:30:00.000Z')),
        );
      });

      test('handles nullable expiresAt', () async {
        final payload = normalizedPayload()..['expiresAt'] = null;
        final invite = await serializer.serialize(payload);

        expect(invite.expiresAt, isNull);
      });

      test('parses expiresAt when present', () async {
        final invite = await serializer.serialize(normalizedPayload());

        expect(invite.expiresAt, isA<DateTime>());
        expect(
          invite.expiresAt,
          equals(DateTime.parse('2024-01-16T10:30:00.000Z')),
        );
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
      // Discord's real Invite object never carries a flat `guild_id` — only
      // `guild.id`. invite_serializer.dart:30-33 reads `json['guild_id']`
      // anyway, so this is expected to FAIL today: it currently lands under
      // `voice_states/guild/<gid>/members/<inviterId>` when it lands
      // anywhere at all (see the sibling test below for what actually
      // happens against a genuine payload).
      test(
        'caches the invite under CacheKey().invite(code), not voice_states',
        () async {
          await serializer.normalize(rawDiscordPayload());

          final expectedKey = CacheKey().invite('abc123');
          expect(
            cache.store.containsKey(expectedKey),
            isTrue,
            reason:
                'InvitePart.get() reads "$expectedKey" via '
                'marshaller.cacheKey.invite(code) — normalize() must write '
                'there or cached invites can never be found.',
          );
        },
      );

      // This is the test that documents the corruption described in the
      // audit: normalize() computes its cache key with
      // marshaller.cacheKey.voiceState(guildId, inviterId) — the exact same
      // namespace VoiceStateSerializer.normalize owns. Expected to FAIL
      // today.
      test('does not write into the voice-state cache namespace', () async {
        await serializer.normalize(rawDiscordPayload());

        final pollutedKeys = cache.store.keys.where(
          (key) => key.startsWith('voice_states/'),
        );

        expect(
          pollutedKeys,
          isEmpty,
          reason:
              'normalize() must never touch the voice-state namespace owned '
              'by VoiceStateSerializer.normalize — a bot fetching an invite '
              "must not corrupt the inviter's voice state.",
        );
      });

      // Vanity invites have no inviter. invite_serializer.dart:32 hard-casts
      // `inviter?['id'] as String`, so this is expected to FAIL today.
      test('vanity invite without an inviter does not throw', () async {
        await expectRoundTripWithoutOptionals(serializer, rawDiscordPayload(), {
          'inviter',
        });
      });

      // Group-DM invites have no guild. invite_serializer.dart:31 hard-casts
      // `json['guild_id'] as String`, so this is expected to FAIL today.
      test('group-DM invite without a guild does not throw', () async {
        await expectRoundTripWithoutOptionals(serializer, rawDiscordPayload(), {
          'guild',
        });
      });
    });

    group('normalize() — gateway INVITE_CREATE payload', () {
      // Unlike the REST shape above, the gateway INVITE_CREATE event
      // genuinely carries a flat `guild_id`, so
      // invite_serializer.dart:31-33's cache-key cast succeeds here instead
      // of throwing. Expected to FAIL today: the invite lands under
      // voice_states/guild/<gid>/members/<inviterId>, not invites/<code>.
      test(
        'caches the invite under CacheKey().invite(code), not voice_states',
        () async {
          await serializer.normalize(rawGatewayInviteCreatePayload());

          final expectedKey = CacheKey().invite('abc123');
          expect(
            cache.store.containsKey(expectedKey),
            isTrue,
            reason:
                'InvitePart.get() reads "$expectedKey" via '
                'marshaller.cacheKey.invite(code) — normalize() must write '
                'there or cached invites can never be found.',
          );
        },
      );

      // This is the test that documents the LIVE corruption. On this path
      // the cache-key cast does not throw, so normalize() actually executes
      // cache.put() against the voice-state namespace owned by
      // VoiceStateSerializer.normalize — a real invite over the gateway
      // clobbers the inviter's cached voice state. Expected to FAIL today.
      test('does not clobber the voice-state cache namespace', () async {
        await serializer.normalize(rawGatewayInviteCreatePayload());

        final clobberedKey = CacheKey().voiceState('987654321', '444555666');
        final pollutedKeys = cache.store.keys.where(
          (key) => key.startsWith('voice_states/'),
        );

        expect(
          pollutedKeys,
          isEmpty,
          reason:
              'normalize() just wrote "$clobberedKey" — this is the live '
              'corruption: an invite received over the gateway overwrites '
              "the inviter's cached voice state with invite data, silently "
              "breaking any code that reads that member's voice state "
              'afterwards.',
        );
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
