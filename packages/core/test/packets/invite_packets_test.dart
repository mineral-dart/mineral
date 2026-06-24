/// Tests for INVITE_CREATE and INVITE_DELETE.
library;

import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/api/guild/managers/threads_manager.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/common/runtime_state.dart';
import 'package:mineral/src/domains/services/datastore/request_bucket_contract.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/invite_create_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/invite_delete_packet.dart';
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
const _channelId = '777888999000111222';
const _inviterId = '987654321098765432';
const _inviteCode = 'abc123xyz';

// ── Payloads ──────────────────────────────────────────────────────────────────

Map<String, dynamic> _createPayload() => {
      'code': _inviteCode,
      'guild_id': _guildId,
      'channel_id': _channelId,
      'inviter': {
        'id': _inviterId,
        'username': 'Inviter',
        'discriminator': '0001',
        'avatar': null,
      },
      'max_age': 86400,
      'max_uses': 10,
      'temporary': false,
      'type': 0,
      'created_at': '2024-06-01T12:00:00.000Z',
    };

Map<String, dynamic> _deletePayload() => {
      'channel_id': _channelId,
      'guild_id': _guildId,
      'code': _inviteCode,
    };

ShardMessage<dynamic> _msg(String type, Map<String, dynamic> payload) =>
    ShardMessage(
      type: type,
      opCode: OpCode.dispatch,
      sequence: 1,
      payload: payload,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeCacheProvider cache;
  late FakeMarshaller marshaller;
  late GuildTextChannel fakeChannel;
  late _FakeChannelDataStore channelDataStore;

  setUp(() {
    final wss = FakeWebsocketOrchestrator();
    cache = FakeCacheProvider();

    late _FakeChannelDataStore dsFinal;
    marshaller = FakeMarshaller(
      cache: cache,
      entityContext: EntityContext(
        datastore: LazyDataStore(() => dsFinal),
        wss: wss,
        logger: FakeLogger(),
        runtimeState: RuntimeState(),
      ),
    );

    final ctx = EntityContext(
      datastore: LazyDataStore(() => dsFinal),
      wss: wss,
      logger: FakeLogger(),
      runtimeState: RuntimeState(),
    );

    fakeChannel = _buildGuildTextChannel(ctx);
    dsFinal = _FakeChannelDataStore(FakeChannelPart(fakeChannel));
    channelDataStore = dsFinal;
  });

  // ── INVITE_CREATE ──────────────────────────────────────────────────────────

  group('InviteCreatePacket', () {
    test('packetType is PacketType.inviteCreate', () {
      final packet = InviteCreatePacket(marshaller: marshaller);
      expect(packet.packetType, equals(PacketType.inviteCreate));
      expect(packet.packetType.name, equals('INVITE_CREATE'));
    });

    test('dispatches Event.inviteCreate', () async {
      final packet = InviteCreatePacket(marshaller: marshaller);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_msg('INVITE_CREATE', _createPayload()), dispatch);

      expect(capturedEvent, equals(Event.inviteCreate));
    });

    test('payload is InviteCreateArgs with correct invite', () async {
      final packet = InviteCreatePacket(marshaller: marshaller);
      InviteCreateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.inviteCreate) {
          args = payload as InviteCreateArgs;
        }
      }

      await packet.listen(_msg('INVITE_CREATE', _createPayload()), dispatch);

      expect(args, isNotNull);
      expect(args!.invite.code, equals(_inviteCode));
      expect(args!.invite.guildId, equals(Snowflake.parse(_guildId)));
    });
  });

  // ── INVITE_DELETE ──────────────────────────────────────────────────────────

  group('InviteDeletePacket', () {
    test('packetType is PacketType.inviteDelete', () {
      final packet = InviteDeletePacket(dataStore: channelDataStore);
      expect(packet.packetType, equals(PacketType.inviteDelete));
      expect(packet.packetType.name, equals('INVITE_DELETE'));
    });

    test('dispatches Event.inviteDelete', () async {
      final packet = InviteDeletePacket(dataStore: channelDataStore);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_msg('INVITE_DELETE', _deletePayload()), dispatch);

      expect(capturedEvent, equals(Event.inviteDelete));
    });

    test('payload carries the invite code', () async {
      final packet = InviteDeletePacket(dataStore: channelDataStore);
      InviteDeleteArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.inviteDelete) {
          args = payload as InviteDeleteArgs;
        }
      }

      await packet.listen(_msg('INVITE_DELETE', _deletePayload()), dispatch);

      expect(args, isNotNull);
      expect(args!.code, equals(_inviteCode));
      expect(args!.channel?.id, equals(Snowflake.parse(_channelId)));
    });
  });
}

// ── Domain helpers ────────────────────────────────────────────────────────────

GuildTextChannel _buildGuildTextChannel(EntityContext ctx) => GuildTextChannel(
      ChannelProperties(
        ctx: ctx,
        id: Snowflake.parse(_channelId),
        type: ChannelType.guildText,
        name: 'general',
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

// ── Fake DataStore ────────────────────────────────────────────────────────────

final class _FakeChannelDataStore implements DataStoreContract {
  final ChannelPartContract _channelPart;
  _FakeChannelDataStore(this._channelPart);

  @override
  ChannelPartContract get channel => _channelPart;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());

  @override
  GuildPartContract get guild => throw UnimplementedError();
  @override
  MessagePartContract get message => throw UnimplementedError();
  @override
  MemberPartContract get member => throw UnimplementedError();
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
