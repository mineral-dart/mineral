import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/api/common/permissions.dart';
import 'package:mineral/src/api/guild/managers/threads_manager.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/voice_channel_effect_send_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../helpers/fake_websocket_orchestrator.dart';
import '../helpers/mocks.dart';
import 'helpers/packet_test_helpers.dart';

// ── Test IDs ─────────────────────────────────────────────────────────────────

const _guildId = '123456789012345678';
const _channelId = '234567890123456789';
const _userId = '345678901234567890';
const _emojiId = '999888777666555444';
const _soundId = '111222333444555666';

// ── Domain object builders ────────────────────────────────────────────────────

GuildVoiceChannel _buildVoiceChannel(EntityContext ctx) => GuildVoiceChannel(
      ChannelProperties(
        ctx: ctx,
        id: Snowflake.parse(_channelId),
        type: ChannelType.guildVoice,
        name: 'general-voice',
        description: null,
        guildId: Snowflake.parse(_guildId),
        categoryId: null,
        position: null,
        nsfw: false,
        lastMessageId: null,
        bitrate: null,
        userLimit: null,
        rateLimitPerUser: null,
        recipients: [],
        icon: null,
        ownerId: null,
        applicationId: null,
        lastPinTimestamp: null,
        rtcRegion: null,
        videoQualityMode: null,
        messageCount: null,
        memberCount: null,
        defaultAutoArchiveDuration: null,
        permissions: [],
        flags: null,
        totalMessageSent: null,
        available: null,
        appliedTags: [],
        defaultReactions: null,
        defaultSortOrder: null,
        defaultForumLayout: null,
        threads: ThreadsManager(
          Snowflake.parse(_guildId),
          Snowflake.parse(_channelId),
          ctx: ctx,
        ),
      ),
    );

Member _buildMember(EntityContext ctx) {
  final memberId = Snowflake.parse(_userId);
  final guildId = Snowflake.parse(_guildId);
  return Member(
    ctx: ctx,
    id: memberId,
    username: 'testuser',
    nickname: null,
    globalName: null,
    discriminator: null,
    assets: MemberAssets(
      avatar: null,
      avatarDecoration: null,
      banner: null,
    ),
    flags: MemberFlagsManager([], ctx: ctx),
    premiumSince: null,
    publicFlags: null,
    roles: MemberRoleManager([], guildId, memberId, ctx: ctx),
    isBot: false,
    isPending: false,
    timeout: MemberTimeout(duration: null),
    mfaEnabled: false,
    locale: null,
    premiumType: PremiumTier.none,
    joinedAt: null,
    permissions: Permissions.fromInt(0),
    accentColor: null,
    guildId: guildId,
  );
}

// ── Helper: build a wired MockDataStore ───────────────────────────────────────

MockDataStore _buildWiredDs() {
  final ds = MockDataStore();
  final ctx = buildCtx(dataStore: ds, wss: FakeWebsocketOrchestrator());
  final guild = buildMinimalGuild(_guildId, ctx);
  final channel = _buildVoiceChannel(ctx);
  final member = _buildMember(ctx);
  when(() => ds.guild).thenReturn(FakeGuildPart(guild));
  when(() => ds.channel).thenReturn(FakeChannelPart(channel));
  when(() => ds.member).thenReturn(_FakeMemberPart(member));
  return ds;
}

// ── Fake member part ──────────────────────────────────────────────────────────

class _FakeMemberPart extends Mock implements MemberPartContract {
  final Member _member;
  _FakeMemberPart(this._member);

  @override
  Future<Member?> get(Object guildId, Object id, bool force) async => _member;
}

// ── Shard message factories ───────────────────────────────────────────────────

ShardMessage<dynamic> _shardMessage(Map<String, dynamic> payload) =>
    ShardMessage(
      type: 'VOICE_CHANNEL_EFFECT_SEND',
      opCode: OpCode.dispatch,
      sequence: 1,
      payload: {
        'channel_id': _channelId,
        'guild_id': _guildId,
        'user_id': _userId,
        ...payload,
      },
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('VoiceChannelEffectSendPacket', () {
    // ── packetType identity ─────────────────────────────────────────────────

    test('packetType is voiceChannelEffectSend', () {
      final packet = VoiceChannelEffectSendPacket(dataStore: _buildWiredDs());

      expect(packet.packetType, equals(PacketType.voiceChannelEffectSend));
      expect(packet.packetType.name, equals('VOICE_CHANNEL_EFFECT_SEND'));
    });

    // ── emoji effect dispatch ───────────────────────────────────────────────

    group('emoji effect (animation_type set, no sound)', () {
      late VoiceChannelEffectSendPacket packet;

      setUp(() {
        packet = VoiceChannelEffectSendPacket(dataStore: _buildWiredDs());
      });

      test('dispatches Event.guildVoiceChannelEffectSend', () async {
        Event? capturedEvent;
        Object? capturedPayload;

        void dispatch<T extends Object>(
            {required Event event,
            required T payload,
            bool Function(String?)? constraint}) {
          capturedEvent = event;
          capturedPayload = payload;
        }

        await packet.listen(
          _shardMessage({
            'emoji': {'id': _emojiId, 'name': 'cool_emoji', 'animated': true},
            'animation_type': 0,
            'animation_id': 42,
          }),
          dispatch,
        );

        expect(capturedEvent, equals(Event.guildVoiceChannelEffectSend));
        expect(capturedPayload, isA<GuildVoiceChannelEffectSendArgs>());
      });

      test('payload carries emoji, animationType=premium, animationId', () async {
        GuildVoiceChannelEffectSendArgs? args;

        void dispatch<T extends Object>(
            {required Event event,
            required T payload,
            bool Function(String?)? constraint}) {
          if (event == Event.guildVoiceChannelEffectSend) {
            args = payload as GuildVoiceChannelEffectSendArgs;
          }
        }

        await packet.listen(
          _shardMessage({
            'emoji': {'id': _emojiId, 'name': 'cool_emoji', 'animated': true},
            'animation_type': 0,
            'animation_id': 42,
          }),
          dispatch,
        );

        expect(args, isNotNull);
        expect(args!.emoji, isNotNull);
        expect(args!.emoji!.name, equals('cool_emoji'));
        expect(args!.emoji!.id, equals(Snowflake.parse(_emojiId)));
        expect(args!.emoji!.animated, isTrue);
        expect(args!.animationType,
            equals(VoiceChannelEffectAnimationType.premium));
        expect(args!.animationId, equals(42));
        expect(args!.soundId, isNull);
        expect(args!.soundVolume, isNull);
      });

      test('payload carries unicode emoji and basic animationType', () async {
        GuildVoiceChannelEffectSendArgs? args;

        void dispatch<T extends Object>(
            {required Event event,
            required T payload,
            bool Function(String?)? constraint}) {
          if (event == Event.guildVoiceChannelEffectSend) {
            args = payload as GuildVoiceChannelEffectSendArgs;
          }
        }

        await packet.listen(
          _shardMessage({
            'emoji': {'id': null, 'name': '🔥', 'animated': false},
            'animation_type': 1,
            'animation_id': 7,
          }),
          dispatch,
        );

        expect(args, isNotNull);
        expect(args!.emoji!.name, equals('🔥'));
        expect(args!.emoji!.id, isNull);
        expect(args!.animationType,
            equals(VoiceChannelEffectAnimationType.basic));
      });

      test('channel is GuildVoiceChannel (GuildChannel subtype)', () async {
        GuildVoiceChannelEffectSendArgs? args;

        void dispatch<T extends Object>(
            {required Event event,
            required T payload,
            bool Function(String?)? constraint}) {
          if (event == Event.guildVoiceChannelEffectSend) {
            args = payload as GuildVoiceChannelEffectSendArgs;
          }
        }

        await packet.listen(
          _shardMessage({
            'emoji': {'id': null, 'name': '👍', 'animated': false},
            'animation_type': 1,
            'animation_id': 1,
          }),
          dispatch,
        );

        expect(args!.channel, isA<GuildVoiceChannel>());
        expect(args!.member, isA<Member>());
        expect(args!.guild, isA<Guild>());
      });
    });

    // ── soundboard effect dispatch ──────────────────────────────────────────

    group('soundboard effect (sound_id set, no emoji)', () {
      late VoiceChannelEffectSendPacket packet;

      setUp(() {
        packet = VoiceChannelEffectSendPacket(dataStore: _buildWiredDs());
      });

      test('dispatches Event.guildVoiceChannelEffectSend with sound payload',
          () async {
        GuildVoiceChannelEffectSendArgs? args;

        void dispatch<T extends Object>(
            {required Event event,
            required T payload,
            bool Function(String?)? constraint}) {
          if (event == Event.guildVoiceChannelEffectSend) {
            args = payload as GuildVoiceChannelEffectSendArgs;
          }
        }

        await packet.listen(
          _shardMessage({
            'sound_id': _soundId,
            'sound_volume': 0.5,
          }),
          dispatch,
        );

        expect(args, isNotNull);
        expect(args!.soundId, equals(Snowflake.parse(_soundId)));
        expect(args!.soundVolume, equals(0.5));
        expect(args!.emoji, isNull);
        expect(args!.animationType, isNull);
        expect(args!.animationId, isNull);
      });
    });

    // ── null/absent optional fields ─────────────────────────────────────────

    group('null/absent optional fields', () {
      late VoiceChannelEffectSendPacket packet;

      setUp(() {
        packet = VoiceChannelEffectSendPacket(dataStore: _buildWiredDs());
      });

      test('all optional fields null when absent from payload', () async {
        GuildVoiceChannelEffectSendArgs? args;

        void dispatch<T extends Object>(
            {required Event event,
            required T payload,
            bool Function(String?)? constraint}) {
          if (event == Event.guildVoiceChannelEffectSend) {
            args = payload as GuildVoiceChannelEffectSendArgs;
          }
        }

        await packet.listen(_shardMessage({}), dispatch);

        expect(args, isNotNull);
        expect(args!.emoji, isNull);
        expect(args!.animationType, isNull);
        expect(args!.animationId, isNull);
        expect(args!.soundId, isNull);
        expect(args!.soundVolume, isNull);
      });
    });
  });
}
