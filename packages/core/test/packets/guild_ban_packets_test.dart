import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/common/runtime_state.dart';
import 'package:mineral/src/domains/services/datastore/request_bucket_contract.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_ban_add_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_ban_remove_packet.dart';
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

// ── Payload helpers ───────────────────────────────────────────────────────────

Map<String, dynamic> _banPayload() => {
      'guild_id': _guildId,
      'user': {
        'id': _userId,
        'username': 'BannedUser',
        'discriminator': '0001',
        'avatar': null,
        'bot': false,
        'global_name': null,
        'public_flags': 0,
      },
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
  late Guild fakeGuild;
  late User fakeUser;
  late _FakeDataStore dataStore;

  setUp(() async {
    final wss = FakeWebsocketOrchestrator();
    cache = FakeCacheProvider();

    late _FakeDataStore dsFinal;
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

    fakeGuild = buildMinimalGuild(_guildId, ctx);
    fakeUser = await marshaller.serializers.user.serialize(
      await marshaller.serializers.user.normalize({
        'id': _userId,
        'username': 'BannedUser',
        'discriminator': '0001',
        'avatar': null,
        'bot': false,
        'global_name': null,
        'public_flags': 0,
      }),
    );

    dsFinal = _FakeDataStore(
      guildPart: FakeGuildPart(fakeGuild),
      userPart: FakeUserPart(fakeUser),
    );
    dataStore = dsFinal;
  });

  // ── GUILD_BAN_ADD ──────────────────────────────────────────────────────────

  group('GuildBanAddPacket', () {
    test('packetType is PacketType.guildBanAdd', () {
      final packet =
          GuildBanAddPacket(marshaller: marshaller, dataStore: dataStore);
      expect(packet.packetType, equals(PacketType.guildBanAdd));
      expect(packet.packetType.name, equals('GUILD_BAN_ADD'));
    });

    test('dispatches Event.guildBanAdd', () async {
      final packet =
          GuildBanAddPacket(marshaller: marshaller, dataStore: dataStore);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_msg('GUILD_BAN_ADD', _banPayload()), dispatch);

      expect(capturedEvent, equals(Event.guildBanAdd));
    });

    test('payload carries guild and user', () async {
      final packet =
          GuildBanAddPacket(marshaller: marshaller, dataStore: dataStore);
      GuildBanAddArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildBanAdd) {
          args = payload as GuildBanAddArgs;
        }
      }

      await packet.listen(_msg('GUILD_BAN_ADD', _banPayload()), dispatch);

      expect(args, isNotNull);
      expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
      expect(args!.user.id, equals(Snowflake.parse(_userId)));
    });

    test('member cache entry is invalidated on ban add', () async {
      final memberKey = marshaller.cacheKey.member(_guildId, _userId);
      await cache.put(memberKey, {'id': _userId});

      final packet =
          GuildBanAddPacket(marshaller: marshaller, dataStore: dataStore);

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {}

      await packet.listen(_msg('GUILD_BAN_ADD', _banPayload()), dispatch);

      final cached = await cache.get(memberKey);
      expect(cached, isNull);
    });
  });

  // ── GUILD_BAN_REMOVE ───────────────────────────────────────────────────────

  group('GuildBanRemovePacket', () {
    test('packetType is PacketType.guildBanRemove', () {
      final packet =
          GuildBanRemovePacket(marshaller: marshaller, dataStore: dataStore);
      expect(packet.packetType, equals(PacketType.guildBanRemove));
      expect(packet.packetType.name, equals('GUILD_BAN_REMOVE'));
    });

    test('dispatches Event.guildBanRemove', () async {
      final packet =
          GuildBanRemovePacket(marshaller: marshaller, dataStore: dataStore);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(_msg('GUILD_BAN_REMOVE', _banPayload()), dispatch);

      expect(capturedEvent, equals(Event.guildBanRemove));
    });

    test('payload carries guild and user', () async {
      final packet =
          GuildBanRemovePacket(marshaller: marshaller, dataStore: dataStore);
      GuildBanRemoveArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildBanRemove) {
          args = payload as GuildBanRemoveArgs;
        }
      }

      await packet.listen(_msg('GUILD_BAN_REMOVE', _banPayload()), dispatch);

      expect(args, isNotNull);
      expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
      expect(args!.user.id, equals(Snowflake.parse(_userId)));
    });
  });
}

// ── Fake DataStore ────────────────────────────────────────────────────────────

final class _FakeDataStore implements DataStoreContract {
  final GuildPartContract _guildPart;
  final UserPartContract _userPart;

  _FakeDataStore({
    required GuildPartContract guildPart,
    required UserPartContract userPart,
  })  : _guildPart = guildPart,
        _userPart = userPart;

  @override
  GuildPartContract get guild => _guildPart;
  @override
  UserPartContract get user => _userPart;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());

  @override
  ChannelPartContract get channel => throw UnimplementedError();
  @override
  MessagePartContract get message => throw UnimplementedError();
  @override
  MemberPartContract get member => throw UnimplementedError();
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
