/// Tests for GUILD_EMOJIS_UPDATE and GUILD_STICKERS_UPDATE.
library;

import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/common/runtime_state.dart';
import 'package:mineral/src/domains/services/datastore/request_bucket_contract.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_emojis_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_stickers_update_packet.dart';
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
const _emojiId = '111222333444555666';
const _stickerId = '999888777666555444';

// ── Payloads ──────────────────────────────────────────────────────────────────

Map<String, dynamic> _emojiUpdatePayload() => {
      'guild_id': _guildId,
      'emojis': [
        {
          'id': _emojiId,
          'name': 'test_emoji',
          'roles': <String>[],
          'require_colons': true,
          'managed': false,
          'animated': false,
          'available': true,
        }
      ],
    };

Map<String, dynamic> _stickerUpdatePayload() => {
      'guild_id': _guildId,
      'stickers': [
        {
          'id': _stickerId,
          'name': 'test_sticker',
          'type': 2, // GUILD sticker
          'format_type': 1, // PNG
          'description': 'A test sticker',
          'tags': 'test',
          'guild_id': _guildId,
          'available': true,
          'sort_value': 0,
          'pack_id': null,
        }
      ],
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
  late FakeWebsocketOrchestrator wss;
  late FakeCacheProvider cache;
  late FakeMarshaller marshaller;
  late Guild fakeGuild;
  late _FakeGuildDataStore dataStore;

  setUp(() {
    wss = FakeWebsocketOrchestrator();
    cache = FakeCacheProvider();

    late _FakeGuildDataStore dsFinal;
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
    dsFinal = _FakeGuildDataStore(FakeGuildPart(fakeGuild));
    dataStore = dsFinal;
  });

  // ── GUILD_EMOJIS_UPDATE ────────────────────────────────────────────────────

  group('GuildEmojisUpdatePacket', () {
    test('packetType is PacketType.guildEmojisUpdate', () {
      final packet =
          GuildEmojisUpdatePacket(marshaller: marshaller, dataStore: dataStore);
      expect(packet.packetType, equals(PacketType.guildEmojisUpdate));
      expect(packet.packetType.name, equals('GUILD_EMOJIS_UPDATE'));
    });

    test('dispatches Event.guildEmojisUpdate', () async {
      final packet =
          GuildEmojisUpdatePacket(marshaller: marshaller, dataStore: dataStore);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(
          _msg('GUILD_EMOJIS_UPDATE', _emojiUpdatePayload()), dispatch);

      expect(capturedEvent, equals(Event.guildEmojisUpdate));
    });

    test('payload carries guild and emojis map', () async {
      final packet =
          GuildEmojisUpdatePacket(marshaller: marshaller, dataStore: dataStore);
      GuildEmojisUpdateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildEmojisUpdate) {
          args = payload as GuildEmojisUpdateArgs;
        }
      }

      await packet.listen(
          _msg('GUILD_EMOJIS_UPDATE', _emojiUpdatePayload()), dispatch);

      expect(args, isNotNull);
      expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
      expect(args!.emojis, hasLength(1));
      expect(args!.emojis.values.first.name, equals('test_emoji'));
    });
  });

  // ── GUILD_STICKERS_UPDATE ──────────────────────────────────────────────────

  group('GuildStickersUpdatePacket', () {
    test('packetType is PacketType.guildStickersUpdate', () {
      final packet = GuildStickersUpdatePacket(
          marshaller: marshaller, dataStore: dataStore);
      expect(packet.packetType, equals(PacketType.guildStickersUpdate));
      expect(packet.packetType.name, equals('GUILD_STICKERS_UPDATE'));
    });

    test('dispatches Event.guildStickersUpdate', () async {
      final packet = GuildStickersUpdatePacket(
          marshaller: marshaller, dataStore: dataStore);
      Event? capturedEvent;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        capturedEvent = event;
      }

      await packet.listen(
          _msg('GUILD_STICKERS_UPDATE', _stickerUpdatePayload()), dispatch);

      expect(capturedEvent, equals(Event.guildStickersUpdate));
    });

    test('payload carries guild and stickers map', () async {
      final packet = GuildStickersUpdatePacket(
          marshaller: marshaller, dataStore: dataStore);
      GuildStickersUpdateArgs? args;

      void dispatch<T extends Object>(
          {required Event event,
          required T payload,
          bool Function(String?)? constraint}) {
        if (event == Event.guildStickersUpdate) {
          args = payload as GuildStickersUpdateArgs;
        }
      }

      await packet.listen(
          _msg('GUILD_STICKERS_UPDATE', _stickerUpdatePayload()), dispatch);

      expect(args, isNotNull);
      expect(args!.guild.id, equals(Snowflake.parse(_guildId)));
      expect(args!.stickers, hasLength(1));
      expect(args!.stickers.values.first.name, equals('test_sticker'));
    });
  });
}

// ── Fake DataStore ────────────────────────────────────────────────────────────

final class _FakeGuildDataStore implements DataStoreContract {
  final GuildPartContract _guildPart;
  _FakeGuildDataStore(this._guildPart);

  @override
  GuildPartContract get guild => _guildPart;

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
