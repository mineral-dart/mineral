import 'package:mineral/api.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/guild_scheduled_event_serializer.dart';
import 'package:test/test.dart';

import '../../helpers/fake_cache_provider.dart';
import '../../helpers/fake_entity_context.dart';
import '../../helpers/fake_marshaller.dart';

void main() {
  group('GuildScheduledEventSerializer', () {
    late GuildScheduledEventSerializer serializer;
    late FakeCacheProvider cache;

    setUp(() {
      cache = FakeCacheProvider();
      serializer = GuildScheduledEventSerializer(
        FakeMarshaller(cache: cache),
        fakeEntityContext(),
      );
    });

    Map<String, dynamic> discordPayload() => {
          'id': '111111111111111111',
          'guild_id': '222222222222222222',
          'channel_id': '333333333333333333',
          'creator_id': '444444444444444444',
          'name': 'Stage event',
          'description': 'A great event',
          'scheduled_start_time': '2026-06-01T18:00:00.000Z',
          'scheduled_end_time': '2026-06-01T20:00:00.000Z',
          'privacy_level': 2,
          'status': 1,
          'entity_type': 1,
          'entity_id': '555555555555555555',
          'entity_metadata': null,
          'user_count': 12,
          'image': null,
        };

    test('normalize maps Discord fields and writes cache', () async {
      final result = await serializer.normalize(discordPayload());
      expect(result['id'], equals('111111111111111111'));
      expect(result['guild_id'], equals('222222222222222222'));
      expect(result['creator_id'], equals('444444444444444444'));
      expect(result['name'], equals('Stage event'));
      expect(
          cache.store.containsKey(
              'server/222222222222222222/scheduled-events/111111111111111111'),
          isTrue);
    });

    test('normalize falls back to creator.id when creator_id absent', () async {
      final payload = discordPayload()
        ..remove('creator_id')
        ..['creator'] = {'id': '999999999999999999'};
      final result = await serializer.normalize(payload);
      expect(result['creator_id'], equals('999999999999999999'));
    });

    test('normalize captures entity_metadata.location for external events',
        () async {
      final payload = discordPayload()
        ..['entity_type'] = 3
        ..['entity_metadata'] = {'location': 'Paris'};
      final result = await serializer.normalize(payload);
      expect((result['entity_metadata'] as Map)['location'], equals('Paris'));
    });

    test('serialize builds a GuildScheduledEvent', () async {
      final raw = await serializer.normalize(discordPayload());
      final event = await serializer.serialize(raw);
      expect(event.id.value, equals('111111111111111111'));
      expect(event.serverId.value, equals('222222222222222222'));
      expect(event.name, equals('Stage event'));
      expect(event.status, equals(GuildScheduledEventStatus.scheduled));
      expect(event.entityType,
          equals(GuildScheduledEventEntityType.stageInstance));
      expect(event.privacyLevel,
          equals(GuildScheduledEventPrivacyLevel.guildOnly));
      expect(event.userCount, equals(12));
    });

    test('deserialize round-trips', () async {
      final raw = await serializer.normalize(discordPayload());
      final event = await serializer.serialize(raw);
      final back = serializer.deserialize(event);
      expect(back['id'], equals('111111111111111111'));
      expect(back['guild_id'], equals('222222222222222222'));
      expect(back['name'], equals('Stage event'));
      expect(back['status'], equals(1));
      expect(back['entity_type'], equals(1));
    });
  });
}
