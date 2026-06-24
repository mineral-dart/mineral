/// Tests for TYPING_START and PRESENCE_UPDATE.
library;

import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/common/runtime_state.dart';
import 'package:mineral/src/domains/services/datastore/request_bucket_contract.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/presence_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/typing_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:test/test.dart';

import '../helpers/fake_cache_provider.dart';
import '../helpers/fake_logger.dart';
import '../helpers/fake_marshaller.dart';
import '../helpers/fake_websocket_orchestrator.dart';
import 'helpers/packet_test_helpers.dart';

// ── IDs ───────────────────────────────────────────────────────────────────────

const _guildId = '123456789012345678';
const _userId = '111222333444555666';
const _channelId = '777888999000111222';

ShardMessage<dynamic> _msg(String type, Map<String, dynamic> payload) =>
    ShardMessage(
      type: type,
      opCode: OpCode.dispatch,
      sequence: 1,
      payload: payload,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeWebsocketOrchestrator wss;
  late FakeCacheProvider cache;
  late FakeMarshaller marshaller;
  late EntityContext ctx;

  setUp(() async {
    wss = FakeWebsocketOrchestrator();
    cache = FakeCacheProvider();

    late _FakeMemberDataStore dsFinal;
    marshaller = FakeMarshaller(
      cache: cache,
      entityContext: EntityContext(
        datastore: LazyDataStore(() => dsFinal),
        wss: wss,
        logger: FakeLogger(),
        runtimeState: RuntimeState(),
      ),
    );

    ctx = EntityContext(
      datastore: LazyDataStore(() => dsFinal),
      wss: wss,
      logger: FakeLogger(),
      runtimeState: RuntimeState(),
    );

    final fakeGuild = buildMinimalGuild(_guildId, ctx);
    final fakeMember = await marshaller.serializers.member.serialize(
      await marshaller.serializers.member.normalize({
        'guild_id': _guildId,
        'user': {
          'id': _userId,
          'username': 'TypingUser',
          'discriminator': '0000',
          'avatar': null,
          'bot': false,
          'global_name': null,
          'public_flags': 0,
        },
        'nick': null,
        'roles': <String>[],
        'joined_at': '2024-01-01T00:00:00.000Z',
        'deaf': false,
        'mute': false,
        'flags': 0,
        'pending': false,
      }),
    );

    dsFinal = _FakeMemberDataStore(
      guildPart: FakeGuildPart(fakeGuild),
      memberPart: _FakeMemberPart(fakeMember),
    );
  });

  // ── TYPING_START ───────────────────────────────────────────────────────────

  group('TypingPacket', () {
    test('packetType is PacketType.typingStart', () {
      final packet = TypingPacket(ctx: ctx);
      expect(packet.packetType, equals(PacketType.typingStart));
      expect(packet.packetType.name, equals('TYPING_START'));
    });

    test('dispatches Event.typing', () async {
      final packet = TypingPacket(ctx: ctx);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(
          _msg('TYPING_START', {
            'channel_id': _channelId,
            'guild_id': _guildId,
            'user_id': _userId,
            'timestamp': 1700000000,
          }),
          dispatch);

      expect(capturedEvent, equals(Event.typing));
    });

    test('payload is TypingArgs with correct Typing object', () async {
      final packet = TypingPacket(ctx: ctx);
      TypingArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.typing) {
          args = payload as TypingArgs;
        }
      }

      await packet.listen(
          _msg('TYPING_START', {
            'channel_id': _channelId,
            'guild_id': _guildId,
            'user_id': _userId,
            'timestamp': 1700000000,
          }),
          dispatch);

      expect(args, isNotNull);
      final typing = args!.typing;
      expect(typing.channelId, equals(Snowflake.parse(_channelId)));
      expect(typing.userId, equals(Snowflake.parse(_userId)));
      expect(typing.guildId, equals(Snowflake.parse(_guildId)));
    });

    test('typing has no guild for DM typing', () async {
      final packet = TypingPacket(ctx: ctx);
      TypingArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.typing) {
          args = payload as TypingArgs;
        }
      }

      await packet.listen(
          _msg('TYPING_START', {
            'channel_id': _channelId,
            'user_id': _userId,
            'timestamp': 1700000000,
            // no guild_id
          }),
          dispatch);

      expect(args, isNotNull);
      expect(args!.typing.guildId, isNull);
    });
  });

  // ── PRESENCE_UPDATE ────────────────────────────────────────────────────────

  group('PresenceUpdatePacket', () {
    late _FakeMemberDataStore presenceDs;

    setUp(() async {
      final wss2 = FakeWebsocketOrchestrator();
      final cache2 = FakeCacheProvider();

      late _FakeMemberDataStore dsFinal2;
      final marshaller2 = FakeMarshaller(
        cache: cache2,
        entityContext: EntityContext(
          datastore: LazyDataStore(() => dsFinal2),
          wss: wss2,
          logger: FakeLogger(),
          runtimeState: RuntimeState(),
        ),
      );

      final ctx2 = EntityContext(
        datastore: LazyDataStore(() => dsFinal2),
        wss: wss2,
        logger: FakeLogger(),
        runtimeState: RuntimeState(),
      );

      final guild = buildMinimalGuild(_guildId, ctx2);
      final member = await marshaller2.serializers.member.serialize(
        await marshaller2.serializers.member.normalize({
          'guild_id': _guildId,
          'user': {
            'id': _userId,
            'username': 'PresenceUser',
            'discriminator': '0000',
            'avatar': null,
            'bot': false,
            'global_name': null,
            'public_flags': 0,
          },
          'nick': null,
          'roles': <String>[],
          'joined_at': '2024-01-01T00:00:00.000Z',
          'deaf': false,
          'mute': false,
          'flags': 0,
          'pending': false,
        }),
      );

      dsFinal2 = _FakeMemberDataStore(
        guildPart: FakeGuildPart(guild),
        memberPart: _FakeMemberPart(member),
      );
      presenceDs = dsFinal2;
    });

    test('packetType is PacketType.presenceUpdate', () {
      final packet = PresenceUpdatePacket(dataStore: presenceDs);
      expect(packet.packetType, equals(PacketType.presenceUpdate));
      expect(packet.packetType.name, equals('PRESENCE_UPDATE'));
    });

    test('dispatches Event.guildPresenceUpdate', () async {
      final packet = PresenceUpdatePacket(dataStore: presenceDs);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(
          _msg('PRESENCE_UPDATE', {
            'guild_id': _guildId,
            'user': {'id': _userId},
            'status': 'online',
            'activities': <dynamic>[],
            'client_status': {
              'desktop': 'online',
              'mobile': null,
              'web': null,
            },
          }),
          dispatch);

      expect(capturedEvent, equals(Event.guildPresenceUpdate));
    });

    test('payload is GuildPresenceUpdateArgs with member and presence',
        () async {
      final packet = PresenceUpdatePacket(dataStore: presenceDs);
      GuildPresenceUpdateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildPresenceUpdate) {
          args = payload as GuildPresenceUpdateArgs;
        }
      }

      await packet.listen(
          _msg('PRESENCE_UPDATE', {
            'guild_id': _guildId,
            'user': {'id': _userId},
            'status': 'online',
            'activities': <dynamic>[],
            'client_status': {
              'desktop': 'online',
              'mobile': null,
              'web': null,
            },
          }),
          dispatch);

      expect(args, isNotNull);
      expect(args!.member.id, equals(Snowflake.parse(_userId)));
      expect(args!.presence, isNotNull);
    });
  });
}

// ── Fake DataStore ────────────────────────────────────────────────────────────

final class _FakeMemberPart implements MemberPartContract {
  final Member _member;
  _FakeMemberPart(this._member);

  @override
  Future<Member?> get(Object guildId, Object memberId, bool force) async =>
      _member;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

final class _FakeMemberDataStore implements DataStoreContract {
  final GuildPartContract _guildPart;
  final MemberPartContract _memberPart;

  _FakeMemberDataStore({
    required GuildPartContract guildPart,
    required MemberPartContract memberPart,
  })  : _guildPart = guildPart,
        _memberPart = memberPart;

  @override
  GuildPartContract get guild => _guildPart;
  @override
  MemberPartContract get member => _memberPart;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());

  @override
  ChannelPartContract get channel => throw UnimplementedError();
  @override
  MessagePartContract get message => throw UnimplementedError();
  @override
  UserPartContract get user => throw UnimplementedError();
  @override
  RolePartContract get role => throw UnimplementedError();
  @override
  InteractionPartContract get interaction => throw UnimplementedError();
  @override
  StickerPartContract get sticker => throw UnimplementedError();
  @override
  EmojiPartContract get emoji => throw UnimplementedError();
  @override
  RulesPartContract get rules => throw UnimplementedError();
  @override
  ReactionPartContract get reaction => throw UnimplementedError();
  @override
  ThreadPartContract get thread => throw UnimplementedError();
  @override
  InvitePartContract get invite => throw UnimplementedError();
  @override
  WebhookPartContract get webhook => throw UnimplementedError();
  @override
  GuildScheduledEventPartContract get scheduledEvent =>
      throw UnimplementedError();
  @override
  ApplicationEmojiPartContract get applicationEmoji =>
      throw UnimplementedError();
  @override
  WelcomeScreenPartContract get welcomeScreen => throw UnimplementedError();
  @override
  OnboardingPartContract get onboarding => throw UnimplementedError();
  @override
  TemplatePartContract get template => throw UnimplementedError();
  @override
  StageInstancePartContract get stageInstance => throw UnimplementedError();
  @override
  MonetizationPartContract get monetization => throw UnimplementedError();
  @override
  SoundboardPartContract get soundboard => throw UnimplementedError();
  @override
  RequestBucketContract get requestBucket => throw UnimplementedError();
  @override
  HttpClientContract get client => throw UnimplementedError();
}
