import 'package:mineral/api.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/onboarding_part.dart';
import 'package:test/test.dart';

import '../../helpers/fake_datastore.dart';
import '../../helpers/fake_http_client.dart';
import '../../helpers/fake_marshaller.dart';
import '../../helpers/fake_response.dart';
import '../../helpers/ioc_test_helper.dart';

const _guildId = '123456789012345678';

Map<String, dynamic> _onboardingPayload({
  bool enabled = true,
  int mode = 0,
  List<Map<String, dynamic>>? prompts,
  List<String>? defaultChannelIds,
}) => {
  'guild_id': _guildId,
  'prompts':
      prompts ??
      [
        {
          'id': '111222333444555666',
          'type': 0,
          'options': [
            {
              'id': '999888777666555444',
              'channel_ids': ['111111111111111111'],
              'role_ids': ['222222222222222222'],
              'emoji': {
                'id': '333333333333333333',
                'name': 'wave',
                'animated': false,
              },
              'title': 'Option A',
              'description': 'First option',
            },
          ],
          'title': 'What are you here for?',
          'single_select': false,
          'required': true,
          'in_onboarding': true,
        },
      ],
  'default_channel_ids': defaultChannelIds ?? ['444444444444444444'],
  'enabled': enabled,
  'mode': mode,
};

(OnboardingPart, void Function() restore) _buildPart(FakeHttpClient client) {
  final ds = FakeDataStore(client);
  final ioc = createTestIoc(dataStore: ds);
  return (OnboardingPart(FakeMarshaller(), ds), ioc.restore);
}

void main() {
  group('OnboardingPart', () {
    late void Function() restoreIoc;

    setUp(() {
      final http = FakeHttpClient();
      final dataStore = FakeDataStore(http);
      final iocResult = createTestIoc(dataStore: dataStore);
      restoreIoc = iocResult.restore;
    });

    tearDown(() => restoreIoc());

    // ── fetch ─────────────────────────────────────────────────────────────────

    group('fetch()', () {
      test('sends GET to /guilds/:id/onboarding', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _onboardingPayload()),
        ]);
        final (p, restore) = _buildPart(client);

        await p.fetch(_guildId);
        restore();

        expect(client.calls, hasLength(1));
        expect(client.calls.single.method, equals('GET'));
        expect(
          client.calls.single.path,
          equals('/guilds/$_guildId/onboarding'),
        );
      });

      test('parses guild_id correctly', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _onboardingPayload()),
        ]);
        final (p, restore) = _buildPart(client);

        final onboarding = await p.fetch(_guildId);
        restore();

        expect(onboarding.guildId, equals(Snowflake.parse(_guildId)));
      });

      test('parses enabled correctly', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(
            200,
            _onboardingPayload(enabled: false),
          ),
        ]);
        final (p, restore) = _buildPart(client);

        final onboarding = await p.fetch(_guildId);
        restore();

        expect(onboarding.enabled, isFalse);
      });

      test('parses mode correctly as ONBOARDING_DEFAULT', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _onboardingPayload(mode: 0)),
        ]);
        final (p, restore) = _buildPart(client);

        final onboarding = await p.fetch(_guildId);
        restore();

        expect(onboarding.mode, equals(OnboardingMode.default_));
      });

      test('parses mode correctly as ONBOARDING_ADVANCED', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _onboardingPayload(mode: 1)),
        ]);
        final (p, restore) = _buildPart(client);

        final onboarding = await p.fetch(_guildId);
        restore();

        expect(onboarding.mode, equals(OnboardingMode.advanced));
      });

      test('parses prompts correctly', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _onboardingPayload()),
        ]);
        final (p, restore) = _buildPart(client);

        final onboarding = await p.fetch(_guildId);
        restore();

        expect(onboarding.prompts, hasLength(1));

        final prompt = onboarding.prompts.first;
        expect(prompt.id, equals(Snowflake.parse('111222333444555666')));
        expect(prompt.type, equals(OnboardingPromptType.multipleChoice));
        expect(prompt.title, equals('What are you here for?'));
        expect(prompt.singleSelect, isFalse);
        expect(prompt.required, isTrue);
        expect(prompt.inOnboarding, isTrue);
      });

      test('parses prompt options correctly', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _onboardingPayload()),
        ]);
        final (p, restore) = _buildPart(client);

        final onboarding = await p.fetch(_guildId);
        restore();

        final option = onboarding.prompts.first.options.first;
        expect(option.id, equals(Snowflake.parse('999888777666555444')));
        expect(
          option.channelIds,
          equals([Snowflake.parse('111111111111111111')]),
        );
        expect(option.roleIds, equals([Snowflake.parse('222222222222222222')]));
        expect(option.emojiId, equals(Snowflake.parse('333333333333333333')));
        expect(option.emojiName, equals('wave'));
        expect(option.emojiAnimated, isFalse);
        expect(option.title, equals('Option A'));
        expect(option.description, equals('First option'));
      });

      test('parses defaultChannelIds correctly', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _onboardingPayload()),
        ]);
        final (p, restore) = _buildPart(client);

        final onboarding = await p.fetch(_guildId);
        restore();

        expect(
          onboarding.defaultChannelIds,
          equals([Snowflake.parse('444444444444444444')]),
        );
      });

      test('handles empty prompts list', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(
            200,
            _onboardingPayload(prompts: []),
          ),
        ]);
        final (p, restore) = _buildPart(client);

        final onboarding = await p.fetch(_guildId);
        restore();

        expect(onboarding.prompts, isEmpty);
      });

      test('handles empty defaultChannelIds', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(
            200,
            _onboardingPayload(defaultChannelIds: []),
          ),
        ]);
        final (p, restore) = _buildPart(client);

        final onboarding = await p.fetch(_guildId);
        restore();

        expect(onboarding.defaultChannelIds, isEmpty);
      });

      test('parses DROPDOWN prompt type correctly', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(
            200,
            _onboardingPayload(
              prompts: [
                {
                  'id': '111222333444555666',
                  'type': 1,
                  'options': [],
                  'title': 'Dropdown prompt',
                  'single_select': true,
                  'required': false,
                  'in_onboarding': false,
                },
              ],
            ),
          ),
        ]);
        final (p, restore) = _buildPart(client);

        final onboarding = await p.fetch(_guildId);
        restore();

        expect(
          onboarding.prompts.first.type,
          equals(OnboardingPromptType.dropdown),
        );
      });

      test('parses prompt option with no emoji', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(
            200,
            _onboardingPayload(
              prompts: [
                {
                  'id': '111222333444555666',
                  'type': 0,
                  'options': [
                    {
                      'id': '999888777666555444',
                      'channel_ids': [],
                      'role_ids': [],
                      'title': 'No emoji option',
                      'description': null,
                    },
                  ],
                  'title': 'Prompt',
                  'single_select': false,
                  'required': false,
                  'in_onboarding': true,
                },
              ],
            ),
          ),
        ]);
        final (p, restore) = _buildPart(client);

        final onboarding = await p.fetch(_guildId);
        restore();

        final option = onboarding.prompts.first.options.first;
        expect(option.emojiId, isNull);
        expect(option.emojiName, isNull);
        expect(option.emojiAnimated, isNull);
        expect(option.description, isNull);
      });
    });

    // ── update ────────────────────────────────────────────────────────────────

    group('update()', () {
      test('sends PUT to /guilds/:id/onboarding', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _onboardingPayload()),
        ]);
        final (p, restore) = _buildPart(client);

        await p.update(_guildId, enabled: true);
        restore();

        expect(client.calls, hasLength(1));
        expect(client.calls.single.method, equals('PUT'));
        expect(
          client.calls.single.path,
          equals('/guilds/$_guildId/onboarding'),
        );
      });

      test('returns parsed Onboarding from PUT response', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(
            200,
            _onboardingPayload(enabled: true, mode: 1),
          ),
        ]);
        final (p, restore) = _buildPart(client);

        final onboarding = await p.update(_guildId, enabled: true);
        restore();

        expect(onboarding, isA<Onboarding>());
        expect(onboarding.enabled, isTrue);
        expect(onboarding.mode, equals(OnboardingMode.advanced));
      });

      test('sends audit log reason header when reason is provided', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _onboardingPayload()),
        ]);
        final (p, restore) = _buildPart(client);

        await p.update(_guildId, reason: 'audit reason', enabled: true);
        restore();

        expect(client.calls.single.method, equals('PUT'));
        expect(
          client.calls.single.path,
          equals('/guilds/$_guildId/onboarding'),
        );
      });

      test('only-present fields are sent (enabled only)', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _onboardingPayload()),
        ]);
        final (p, restore) = _buildPart(client);

        final onboarding = await p.update(_guildId, enabled: false);
        restore();

        expect(onboarding, isA<Onboarding>());
        expect(client.calls, hasLength(1));
      });

      test('sends mode when provided', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _onboardingPayload(mode: 1)),
        ]);
        final (p, restore) = _buildPart(client);

        final onboarding = await p.update(
          _guildId,
          mode: OnboardingMode.advanced,
        );
        restore();

        expect(onboarding.mode, equals(OnboardingMode.advanced));
        expect(client.calls.single.method, equals('PUT'));
      });

      test('sends defaultChannelIds when provided', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(
            200,
            _onboardingPayload(defaultChannelIds: ['555555555555555555']),
          ),
        ]);
        final (p, restore) = _buildPart(client);

        final onboarding = await p.update(
          _guildId,
          defaultChannelIds: ['555555555555555555'],
        );
        restore();

        expect(
          onboarding.defaultChannelIds,
          equals([Snowflake.parse('555555555555555555')]),
        );
      });

      test('sends prompts when provided', () async {
        final client = FakeHttpClient([
          FakeResponse<Map<String, dynamic>>(200, _onboardingPayload()),
        ]);
        final (p, restore) = _buildPart(client);

        final onboarding = await p.update(_guildId, prompts: []);
        restore();

        expect(onboarding, isA<Onboarding>());
        expect(client.calls, hasLength(1));
      });
    });
  });
}
