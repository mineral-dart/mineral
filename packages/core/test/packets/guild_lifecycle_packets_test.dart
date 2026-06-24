/// Tests for GUILD_UPDATE and GUILD_DELETE.
library;

import 'package:mineral/api.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_delete_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/guild_update_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:test/test.dart';

import '../helpers/fake_cache_provider.dart';
import '../helpers/fake_marshaller.dart';
import '../helpers/fake_websocket_orchestrator.dart';
import '../helpers/mocks.dart';
import 'helpers/packet_test_helpers.dart';

// ── IDs ───────────────────────────────────────────────────────────────────────

const _guildId = '123456789012345678';

// ── Minimal guild payload ──────────────────────────────────────────────────────

Map<String, dynamic> _guildPayload({String name = 'Test Guild'}) => {
  'id': _guildId,
  'name': name,
  'owner_id': '000000000000000001',
  'description': null,
  'application_id': null,
  'icon': null,
  'icon_hash': null,
  'splash': null,
  'discovery_splash': null,
  'banner': null,
  'afk_channel_id': null,
  'afk_timeout': 300,
  'widget_enabled': false,
  'verification_level': 0,
  'default_message_notifications': 0,
  'explicit_content_filter': 0,
  'features': <String>[],
  'mfa_level': 0,
  'system_channel_id': null,
  'system_channel_flags': 0,
  'rules_channel_id': null,
  'public_updates_channel_id': null,
  'safety_alerts_channel_id': null,
  'vanity_url_code': null,
  'premium_tier': 0,
  'premium_subscription_count': null,
  'premium_progress_bar_enabled': false,
  'preferred_locale': 'en-US',
  'max_video_channel_users': null,
  'nsfw_level': 0,
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

  setUp(() {
    final wss = FakeWebsocketOrchestrator();
    cache = FakeCacheProvider();

    marshaller = FakeMarshaller(
      cache: cache,
      entityContext: buildCtx(dataStore: MockDataStore(), wss: wss),
    );
  });

  // ── GUILD_UPDATE ───────────────────────────────────────────────────────────

  group('GuildUpdatePacket', () {
    test('packetType is PacketType.guildUpdate', () {
      final packet = GuildUpdatePacket(marshaller: marshaller);
      expect(packet.packetType, equals(PacketType.guildUpdate));
      expect(packet.packetType.name, equals('GUILD_UPDATE'));
    });

    test('dispatches Event.guildUpdate', () async {
      final packet = GuildUpdatePacket(marshaller: marshaller);
      Event? capturedEvent;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        capturedEvent = event;
      }

      await packet.listen(_msg('GUILD_UPDATE', _guildPayload()), dispatch);

      expect(capturedEvent, equals(Event.guildUpdate));
    });

    test('before is null when guild not in cache', () async {
      final packet = GuildUpdatePacket(marshaller: marshaller);
      GuildUpdateArgs? args;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        if (event == Event.guildUpdate) {
          args = payload as GuildUpdateArgs;
        }
      }

      await packet.listen(_msg('GUILD_UPDATE', _guildPayload()), dispatch);

      expect(args, isNotNull);
      expect(args!.before, isNull);
      expect(args!.after.id, equals(Snowflake.parse(_guildId)));
    });

    test('before is populated when guild is in cache', () async {
      // Pre-seed old guild data in cache.
      final guildCacheKey = marshaller.cacheKey.guild(_guildId);
      final oldPayload = await marshaller.serializers.guild.normalize(
        _guildPayload(name: 'Old Guild Name'),
      );
      await cache.put(guildCacheKey, oldPayload);

      final packet = GuildUpdatePacket(marshaller: marshaller);
      GuildUpdateArgs? args;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        if (event == Event.guildUpdate) {
          args = payload as GuildUpdateArgs;
        }
      }

      await packet.listen(
        _msg('GUILD_UPDATE', _guildPayload(name: 'New Guild Name')),
        dispatch,
      );

      expect(args, isNotNull);
      expect(args!.before, isNotNull);
      expect(args!.before!.name, equals('Old Guild Name'));
      expect(args!.after.name, equals('New Guild Name'));
    });

    test('guild cache is updated after dispatch', () async {
      final packet = GuildUpdatePacket(marshaller: marshaller);

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {}

      await packet.listen(_msg('GUILD_UPDATE', _guildPayload()), dispatch);

      final guildCacheKey = marshaller.cacheKey.guild(_guildId);
      final cached = await cache.get(guildCacheKey);
      expect(cached, isNotNull);
      expect(cached!['name'], equals('Test Guild'));
    });
  });

  // ── GUILD_DELETE ───────────────────────────────────────────────────────────

  group('GuildDeletePacket', () {
    test('packetType is PacketType.guildDelete', () {
      final packet = GuildDeletePacket(marshaller: marshaller);
      expect(packet.packetType, equals(PacketType.guildDelete));
      expect(packet.packetType.name, equals('GUILD_DELETE'));
    });

    test('dispatches Event.guildDelete', () async {
      final packet = GuildDeletePacket(marshaller: marshaller);
      Event? capturedEvent;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        capturedEvent = event;
      }

      await packet.listen(
        _msg('GUILD_DELETE', {'id': _guildId, 'unavailable': true}),
        dispatch,
      );

      expect(capturedEvent, equals(Event.guildDelete));
    });

    test('guild is null in payload when not cached', () async {
      final packet = GuildDeletePacket(marshaller: marshaller);
      GuildDeleteArgs? args;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        if (event == Event.guildDelete) {
          args = payload as GuildDeleteArgs;
        }
      }

      await packet.listen(
        _msg('GUILD_DELETE', {'id': _guildId, 'unavailable': true}),
        dispatch,
      );

      expect(args, isNotNull);
      expect(args!.guild, isNull);
    });

    test('guild is populated from cache when present', () async {
      // Pre-seed guild in cache.
      final guildCacheKey = marshaller.cacheKey.guild(_guildId);
      final normalized = await marshaller.serializers.guild.normalize(
        _guildPayload(),
      );
      await cache.put(guildCacheKey, normalized);

      final packet = GuildDeletePacket(marshaller: marshaller);
      GuildDeleteArgs? args;

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {
        if (event == Event.guildDelete) {
          args = payload as GuildDeleteArgs;
        }
      }

      await packet.listen(
        _msg('GUILD_DELETE', {'id': _guildId, 'unavailable': false}),
        dispatch,
      );

      expect(args, isNotNull);
      expect(args!.guild, isNotNull);
      expect(args!.guild!.id, equals(Snowflake.parse(_guildId)));
    });

    test('guild is invalidated from cache on delete', () async {
      final guildCacheKey = marshaller.cacheKey.guild(_guildId);
      final normalized = await marshaller.serializers.guild.normalize(
        _guildPayload(),
      );
      await cache.put(guildCacheKey, normalized);

      final packet = GuildDeletePacket(marshaller: marshaller);

      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {}

      await packet.listen(_msg('GUILD_DELETE', {'id': _guildId}), dispatch);

      final cached = await cache.get(guildCacheKey);
      expect(cached, isNull);
    });
  });
}
