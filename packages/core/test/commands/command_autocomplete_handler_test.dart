import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/common/runtime_state.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/thread_part.dart';
import 'package:mineral/src/infrastructure/internals/datastore/request_bucket.dart';
import 'package:test/test.dart';

import '../helpers/fake_logger.dart';
import '../helpers/fake_marshaller.dart';
import '../helpers/fake_websocket_orchestrator.dart';
import '../helpers/ioc_test_helper.dart';

// ── Fake interaction part that captures sendAutocompleteResult calls ──────────

final class _FakeInteractionPart implements InteractionPartContract {
  final List<({Snowflake id, String token, List<Choice> choices})> autocompleteResults = [];

  @override
  Future<void> sendAutocompleteResult(
      Snowflake id, String token, List<Choice> choices) async {
    autocompleteResults.add((id: id, token: token, choices: choices));
  }

  // All other methods are not exercised in these tests.
  @override
  Future<void> replyInteraction(
          Snowflake id, String token, MessageBuilder builder, bool ephemeral) async =>
      throw UnimplementedError();
  @override
  Future<void> editInteraction(
          Snowflake botId, String token, MessageBuilder builder, bool ephemeral) async =>
      throw UnimplementedError();
  @override
  Future<void> deleteInteraction(Snowflake botId, String token) async =>
      throw UnimplementedError();
  @override
  Future<void> noReplyInteraction(
          Snowflake id, String token, bool ephemeral) async =>
      throw UnimplementedError();
  @override
  Future<void> createFollowup(Snowflake botId, String token,
          MessageBuilder builder, bool ephemeral) async =>
      throw UnimplementedError();
  @override
  Future<void> editFollowup(Snowflake botId, String token, Snowflake messageId,
          MessageBuilder builder, bool ephemeral) async =>
      throw UnimplementedError();
  @override
  Future<void> deleteFollowup(
          Snowflake botId, String token, Snowflake messageId) async =>
      throw UnimplementedError();
  @override
  Future<void> waitInteraction(Snowflake id, String token) async =>
      throw UnimplementedError();
  @override
  Future<void> sendModal(Snowflake id, String token, ModalBuilder modal) async =>
      throw UnimplementedError();
}

// ── Minimal DataStore that routes interaction to the fake part ────────────────

final class _FakeDataStore implements DataStoreContract {
  final _FakeInteractionPart _interaction;

  _FakeDataStore(this._interaction);

  @override
  InteractionPartContract get interaction => _interaction;

  @override
  RequestBucket get requestBucket => throw UnimplementedError();
  @override
  HttpClientContract get client => throw UnimplementedError();
  @override
  ChannelPartContract get channel => throw UnimplementedError();
  @override
  ServerPartContract get server => throw UnimplementedError();
  @override
  MemberPartContract get member => throw UnimplementedError();
  @override
  UserPartContract get user => throw UnimplementedError();
  @override
  RolePartContract get role => throw UnimplementedError();
  @override
  MessagePartContract get message => throw UnimplementedError();
  @override
  StickerPartContract get sticker => throw UnimplementedError();
  @override
  EmojiPartContract get emoji => throw UnimplementedError();
  @override
  RulesPartContract get rules => throw UnimplementedError();
  @override
  ReactionPartContract get reaction => throw UnimplementedError();
  @override
  ThreadPart get thread => throw UnimplementedError();
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
}

// ── Helpers ───────────────────────────────────────────────────────────────────

CommandInteractionManager _buildManager({
  required _FakeDataStore dataStore,
  required MarshallerContract marshaller,
}) {
  return CommandInteractionManager(
    dataStore: dataStore,
    marshaller: marshaller,
    ctx: EntityContext(
      datastore: dataStore,
      wss: FakeWebsocketOrchestrator(),
      logger: marshaller.logger,
      runtimeState: RuntimeState(),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('CommandInteractionManager.handleAutocomplete', () {
    late _FakeInteractionPart fakePart;
    late _FakeDataStore fakeDataStore;
    late FakeLogger logger;
    late FakeMarshaller marshaller;
    late CommandInteractionManager manager;
    late void Function() restoreIoc;

    setUp(() {
      fakePart = _FakeInteractionPart();
      fakeDataStore = _FakeDataStore(fakePart);
      logger = FakeLogger();
      marshaller = FakeMarshaller(logger: logger);

      final testIoc = createTestIoc(marshaller: marshaller);
      restoreIoc = testIoc.restore;

      manager = _buildManager(dataStore: fakeDataStore, marshaller: marshaller);
    });

    tearDown(() {
      restoreIoc();
    });

    // ── Registration tests ──────────────────────────────────────────────────

    group('handler registration via addCommand', () {
      test('registers autocomplete handler for top-level option', () async {
        String? capturedValue;

        final command = CommandDeclarationBuilder()
          ..setName('search')
          ..setDescription('Search something')
          ..addOption(Option.string(
            name: 'query',
            description: 'The search query',
            autocomplete: true,
            onAutocomplete: (ctx) {
              capturedValue = ctx.value;
              return [Choice('Result', 'result')];
            },
          ))
          ..setHandle((ctx, opts) {});

        manager.addCommand(command);

        await manager.handleAutocomplete({
          'id': '111111111111111111',
          'token': 'test-token',
          'data': {
            'name': 'search',
            'options': [
              {'name': 'query', 'type': 3, 'value': 'hello', 'focused': true},
            ],
          },
        });

        expect(capturedValue, 'hello');
        expect(fakePart.autocompleteResults, hasLength(1));
      });

      test('sends choices to correct interaction endpoint', () async {
        final command = CommandDeclarationBuilder()
          ..setName('pick')
          ..setDescription('Pick an item')
          ..addOption(Option.string(
            name: 'item',
            description: 'An item',
            autocomplete: true,
            onAutocomplete: (ctx) => [
              Choice('Alpha', 'alpha'),
              Choice('Beta', 'beta'),
            ],
          ))
          ..setHandle((ctx, opts) {});

        manager.addCommand(command);

        await manager.handleAutocomplete({
          'id': '222222222222222222',
          'token': 'my-token',
          'data': {
            'name': 'pick',
            'options': [
              {'name': 'item', 'type': 3, 'value': 'al', 'focused': true},
            ],
          },
        });

        expect(fakePart.autocompleteResults, hasLength(1));
        final result = fakePart.autocompleteResults.first;
        expect(result.token, 'my-token');
        expect(result.id.value, '222222222222222222');
        expect(result.choices, hasLength(2));
        expect(result.choices[0].name, 'Alpha');
        expect(result.choices[1].name, 'Beta');
      });
    });

    // ── Context correctness ─────────────────────────────────────────────────

    group('AutocompleteContext values', () {
      test('focused name and value are passed correctly', () async {
        AutocompleteContext? capturedCtx;

        final command = CommandDeclarationBuilder()
          ..setName('greet')
          ..setDescription('Greet someone')
          ..addOption(Option.string(
            name: 'username',
            description: 'User to greet',
            autocomplete: true,
            onAutocomplete: (ctx) {
              capturedCtx = ctx;
              return [];
            },
          ))
          ..setHandle((ctx, opts) {});

        manager.addCommand(command);

        await manager.handleAutocomplete({
          'id': '333333333333333333',
          'token': 'tok',
          'data': {
            'name': 'greet',
            'options': [
              {
                'name': 'username',
                'type': 3,
                'value': 'ali',
                'focused': true,
              },
            ],
          },
        });

        expect(capturedCtx, isNotNull);
        expect(capturedCtx!.name, 'username');
        expect(capturedCtx!.value, 'ali');
      });

      test('non-focused options are collected into context.options', () async {
        AutocompleteContext? capturedCtx;

        final command = CommandDeclarationBuilder()
          ..setName('filter')
          ..setDescription('Filter results')
          ..addOption(Option.string(
            name: 'query',
            description: 'Search query',
            autocomplete: true,
            onAutocomplete: (ctx) {
              capturedCtx = ctx;
              return [];
            },
          ))
          ..addOption(Option.integer(
            name: 'limit',
            description: 'Max results',
          ))
          ..setHandle((ctx, opts) {});

        manager.addCommand(command);

        await manager.handleAutocomplete({
          'id': '444444444444444444',
          'token': 'tok',
          'data': {
            'name': 'filter',
            'options': [
              {'name': 'query', 'type': 3, 'value': 'foo', 'focused': true},
              {'name': 'limit', 'type': 4, 'value': 10},
            ],
          },
        });

        expect(capturedCtx, isNotNull);
        expect(capturedCtx!.options['limit'], 10);
        // focused option itself should not be in options map
        expect(capturedCtx!.options.containsKey('query'), isFalse);
      });
    });

    // ── Edge cases ──────────────────────────────────────────────────────────

    group('edge cases', () {
      test('logs warning when no handler registered for command', () async {
        await manager.handleAutocomplete({
          'id': '111111111111111111',
          'token': 'tok',
          'data': {
            'name': 'unknown',
            'options': [
              {'name': 'q', 'type': 3, 'value': 'x', 'focused': true},
            ],
          },
        });

        expect(fakePart.autocompleteResults, isEmpty);
        expect(
            logger.warnings,
            contains(contains(
                'No autocomplete handler for command "unknown" option "q"')));
      });

      test('caps choices at 25', () async {
        final command = CommandDeclarationBuilder()
          ..setName('big')
          ..setDescription('Lots of choices')
          ..addOption(Option.string(
            name: 'item',
            description: 'An item',
            autocomplete: true,
            onAutocomplete: (ctx) =>
                List.generate(30, (i) => Choice('Item $i', 'item_$i')),
          ))
          ..setHandle((ctx, opts) {});

        manager.addCommand(command);

        await manager.handleAutocomplete({
          'id': '555555555555555555',
          'token': 'tok',
          'data': {
            'name': 'big',
            'options': [
              {'name': 'item', 'type': 3, 'value': '', 'focused': true},
            ],
          },
        });

        expect(fakePart.autocompleteResults, hasLength(1));
        expect(fakePart.autocompleteResults.first.choices, hasLength(25));
      });

      test('logs warning when no focused option in payload', () async {
        final command = CommandDeclarationBuilder()
          ..setName('nofocus')
          ..setDescription('No focused option')
          ..addOption(Option.string(
            name: 'q',
            description: 'A query',
            autocomplete: true,
            onAutocomplete: (ctx) => [],
          ))
          ..setHandle((ctx, opts) {});

        manager.addCommand(command);

        await manager.handleAutocomplete({
          'id': '666666666666666666',
          'token': 'tok',
          'data': {
            'name': 'nofocus',
            'options': [
              // No focused: true
              {'name': 'q', 'type': 3, 'value': 'x'},
            ],
          },
        });

        expect(fakePart.autocompleteResults, isEmpty);
        expect(
            logger.warnings,
            contains(contains('No focused option found')));
      });

      test('does not break when a non-autocomplete option exists alongside autocomplete one',
          () async {
        bool handlerCalled = false;

        final command = CommandDeclarationBuilder()
          ..setName('mixed')
          ..setDescription('Mixed options')
          ..addOption(Option.string(
            name: 'ac',
            description: 'Autocomplete option',
            autocomplete: true,
            onAutocomplete: (ctx) {
              handlerCalled = true;
              return [Choice('X', 'x')];
            },
          ))
          ..addOption(Option.boolean(
            name: 'flag',
            description: 'A flag',
          ))
          ..setHandle((ctx, opts) {});

        manager.addCommand(command);

        await manager.handleAutocomplete({
          'id': '777777777777777777',
          'token': 'tok',
          'data': {
            'name': 'mixed',
            'options': [
              {'name': 'ac', 'type': 3, 'value': 'x', 'focused': true},
              {'name': 'flag', 'type': 5, 'value': true},
            ],
          },
        });

        expect(handlerCalled, isTrue);
        expect(fakePart.autocompleteResults, hasLength(1));
      });
    });
  });
}
