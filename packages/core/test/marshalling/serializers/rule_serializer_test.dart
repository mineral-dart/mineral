import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/api/server/moderation/auto_moderation_rule.dart';
import 'package:mineral/src/api/server/moderation/enums/action_type.dart';
import 'package:mineral/src/api/server/moderation/enums/auto_moderation_event_type.dart';
import 'package:mineral/src/api/server/moderation/enums/trigger_type.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/cache_key.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/rule_serializer.dart';
import 'package:test/test.dart';

import '../../helpers/fake_cache_provider.dart';
import '../../helpers/fake_entity_context.dart';
import '../../helpers/fake_marshaller.dart';

void main() {
  group('RuleSerializer', () {
    late RuleSerializer serializer;
    late FakeCacheProvider cache;

    setUp(() {
      cache = FakeCacheProvider();
      serializer = RuleSerializer(
        FakeMarshaller(cache: cache),
        fakeEntityContext(),
      );
    });

    Map<String, dynamic> normalizedPayload() => {
          'id': '100200300',
          'serverId': '987654321',
          'name': 'No Profanity',
          'creatorId': '444555666',
          'eventType': 1,
          'triggerType': 1,
          'triggerMetadata': {
            'keyword_filter': ['badword'],
            'regex_patterns': <String>[],
            'presets': <int>[],
            'allow_list': <String>[],
            'mention_total_limit': null,
            'mention_raid_protection_enabled': null,
          },
          'actions': [
            {'type': 1},
          ],
          'enabled': true,
          'exemptRoles': ['111222333'],
          'exemptChannels': ['444555666'],
        };

    Map<String, dynamic> rawDiscordPayload() => {
          'id': '100200300',
          'guild_id': '987654321',
          'name': 'No Profanity',
          'creator_id': '444555666',
          'event_type': 1,
          'trigger_type': 1,
          'trigger_metadata': {
            'keyword_filter': ['badword'],
            'regex_patterns': <String>[],
            'presets': <int>[],
            'allow_list': <String>[],
            'mention_total_limit': null,
            'mention_raid_protection_enabled': null,
          },
          'actions': [
            {'type': 1},
          ],
          'enabled': true,
          'exempt_roles': ['111222333'],
          'exempt_channels': ['444555666'],
        };

    group('serialize()', () {
      test('maps all fields correctly', () async {
        final rule = await serializer.serialize(normalizedPayload());

        expect(rule, isA<AutoModerationRule>());
        expect(rule.id, equals(Snowflake('100200300')));
        expect(rule.serverId, equals(Snowflake('987654321')));
        expect(rule.name, equals('No Profanity'));
        expect(rule.creatorId, equals(Snowflake('444555666')));
        expect(rule.enabled, isTrue);
      });

      test('resolves AutoModerationEventType', () async {
        final rule = await serializer.serialize(normalizedPayload());

        expect(rule.eventTypes, equals(AutoModerationEventType.messageSend));
      });

      test('resolves TriggerType', () async {
        final rule = await serializer.serialize(normalizedPayload());

        expect(rule.triggerTypes, equals(TriggerType.keyword));
      });

      test('parses TriggerMetadata from sub-map', () async {
        final rule = await serializer.serialize(normalizedPayload());

        expect(rule.triggerMetadata.keywordFilter, contains('badword'));
        expect(rule.triggerMetadata.regexPatterns, isEmpty);
        expect(rule.triggerMetadata.presets, isEmpty);
      });

      test('parses actions list', () async {
        final rule = await serializer.serialize(normalizedPayload());

        expect(rule.action, hasLength(1));
        expect(rule.action.first.type, equals(ActionType.blockMessage));
      });

      test('parses exemptRoles as Snowflake list', () async {
        final rule = await serializer.serialize(normalizedPayload());

        expect(rule.exemptRoles, hasLength(1));
        expect(rule.exemptRoles.first, equals(Snowflake('111222333')));
      });

      test('parses exemptChannels as Snowflake list', () async {
        final rule = await serializer.serialize(normalizedPayload());

        expect(rule.exemptChannels, hasLength(1));
        expect(rule.exemptChannels.first, equals(Snowflake('444555666')));
      });
    });

    group('deserialize()', () {
      test('produces map with expected keys', () async {
        final rule = await serializer.serialize(normalizedPayload());
        final result = serializer.deserialize(rule);

        expect(result['name'], equals('No Profanity'));
        expect(result['event_type'],
            equals(AutoModerationEventType.messageSend.value));
        expect(result['trigger_type'], equals(TriggerType.keyword.value));
        expect(result['enabled'], isTrue);
      });

      test('trigger_metadata is a sub-map with expected keys', () async {
        final rule = await serializer.serialize(normalizedPayload());
        final result = serializer.deserialize(rule);

        expect(result['trigger_metadata'], isA<Map>());
        expect(
            result['trigger_metadata']['keyword_filter'], contains('badword'));
      });

      test('actions are serialized as list of maps', () async {
        final rule = await serializer.serialize(normalizedPayload());
        final result = serializer.deserialize(rule);

        expect(result['actions'], isA<List>());
        expect(result['actions'], hasLength(1));
        expect(result['actions'].first['type'],
            equals(ActionType.blockMessage.value));
      });
    });

    group('normalize()', () {
      test('writes to cache with serverRules key', () async {
        await serializer.normalize(rawDiscordPayload());

        final expectedKey = CacheKey().serverRules('987654321', '100200300');
        expect(cache.store.containsKey(expectedKey), isTrue);
      });

      test('renames guild_id to serverId', () async {
        final result = await serializer.normalize(rawDiscordPayload());

        expect(result, containsPair('serverId', '987654321'));
        expect(result.containsKey('guild_id'), isFalse);
      });

      test('renames creator_id to creatorId', () async {
        final result = await serializer.normalize(rawDiscordPayload());

        expect(result, containsPair('creatorId', '444555666'));
      });

      test('parses exempt_roles as Snowflake list', () async {
        final result = await serializer.normalize(rawDiscordPayload());

        expect(result['exemptRoles'], isA<List<Snowflake>>());
        expect(result['exemptRoles'], hasLength(1));
      });
    });

    group('round-trip', () {
      test('serialize then deserialize preserves key data', () async {
        final json = normalizedPayload();
        final rule = await serializer.serialize(json);
        final result = serializer.deserialize(rule);

        expect(result['name'], equals(json['name']));
        expect(result['enabled'], equals(json['enabled']));
        expect(result['event_type'], equals(json['eventType']));
        expect(result['trigger_type'], equals(json['triggerType']));
      });
    });
  });
}
