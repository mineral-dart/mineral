import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/domains/commands/command_interaction_dispatcher.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/thread_part.dart';
import 'package:mineral/src/infrastructure/internals/datastore/request_bucket.dart';
import 'package:test/test.dart';

import '../helpers/fake_logger.dart';
import '../helpers/fake_marshaller.dart';
import '../helpers/ioc_test_helper.dart';
import '../helpers/mocks.dart';

final class _FakeUserPart implements UserPartContract {
  @override
  Future<User?> get(Object id, bool force) async {
    return User(
      id: Snowflake.parse(id.toString()),
      username: 'TestUser',
      discriminator: '0001',
      avatar: null,
      bot: false,
      system: false,
      mfaEnabled: false,
      locale: 'en-US',
      verified: true,
      email: null,
      flags: 0,
      premiumType: PremiumTier.none,
      publicFlags: 0,
      assets: UserAssets(avatar: null, avatarDecoration: null, banner: null),
      createdAt: DateTime.now(),
      presence: null,
    );
  }
}

final class _FakeChannelPart implements ChannelPartContract {
  @override
  Future<T?> get<T extends Channel>(Object id, bool force) async => null;
  @override
  Future<Map<Snowflake, T>> fetch<T extends Channel>(
          Object serverId, bool force) async =>
      {};
  @override
  Future<T> create<T extends Channel>(
          Object? serverId, ChannelBuilderContract builder,
          {String? reason}) =>
      throw UnimplementedError();
  @override
  Future<PrivateChannel?> createPrivateChannel(
          Object id, String recipientId) async =>
      null;
  @override
  Future<T?> update<T extends Channel>(
          Object id, ChannelBuilderContract builder,
          {Object? serverId, String? reason}) =>
      throw UnimplementedError();
  @override
  Future<void> delete(Object id, String? reason) async {}
}

final class _FakeDataStore implements DataStoreContract {
  @override
  RequestBucket get requestBucket => throw UnimplementedError();
  @override
  HttpClient get client => throw UnimplementedError();
  @override
  ChannelPartContract get channel => _FakeChannelPart();
  @override
  ServerPartContract get server => throw UnimplementedError();
  @override
  MemberPartContract get member => throw UnimplementedError();
  @override
  UserPartContract get user => _FakeUserPart();
  @override
  RolePartContract get role => throw UnimplementedError();
  @override
  MessagePartContract get message => throw UnimplementedError();
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
  ThreadPart get thread => throw UnimplementedError();
  @override
  InvitePartContract get invite => throw UnimplementedError();
  @override
  WebhookPartContract get webhook => throw UnimplementedError();
  @override
  GuildScheduledEventPartContract get scheduledEvent =>
      throw UnimplementedError();
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('CommandInteractionDispatcher', () {
    late CommandInteractionDispatcher dispatcher;
    late FakeCommandInteractionManager manager;
    late FakeLogger logger;
    late void Function() restoreIoc;

    setUp(() {
      final testIoc = createTestIoc();
      logger = testIoc.logger;
      restoreIoc = testIoc.restore;

      manager = FakeCommandInteractionManager();
      dispatcher = CommandInteractionDispatcher(manager);

      final fakeBot = Bot.fromJson({
        'user': {
          'id': '999999999999999999',
          'username': 'TestBot',
          'discriminator': '0000',
          'mfa_enabled': false,
          'global_name': null,
          'flags': 0,
          'avatar': null,
        },
        'v': 10,
        'session_type': 'normal',
        'private_channels': [],
        'presences': [],
        'guilds': [],
        'application': {'id': '999999999999999999', 'flags': 0},
      });

      testIoc.container
        ..bind<MarshallerContract>(() => FakeMarshaller(logger: logger))
        ..bind<DataStoreContract>(_FakeDataStore.new)
        ..bind<Bot>(() => fakeBot);
    });

    tearDown(() {
      restoreIoc();
    });

    group('unknown command', () {
      test('logs warning when no handler matches', () async {
        await dispatcher.dispatch({
          'data': {
            'name': 'nonexistent',
            'options': null,
            'guild_id': null,
          },
        });

        expect(logger.warnings,
            contains(contains('Unknown command received: "nonexistent"')));
      });

      test('does not throw when command is unknown', () async {
        await expectLater(
            dispatcher.dispatch({
              'data': {
                'name': 'nonexistent',
                'options': null,
                'guild_id': null,
              },
            }),
            completes);
      });
    });

    group('sub-command routing', () {
      test('logs unknown for unregistered sub-command "admin.kick"', () async {
        await dispatcher.dispatch({
          'data': {
            'name': 'admin',
            'options': [
              {
                'name': 'kick',
                'type': 1, // SUB_COMMAND
                'options': null,
              }
            ],
            'guild_id': null,
          },
        });

        expect(logger.warnings,
            contains(contains('Unknown command received: "admin.kick"')));
      });

      test('builds "parent.group.subcommand" for SUB_COMMAND_GROUP', () async {
        await dispatcher.dispatch({
          'data': {
            'name': 'settings',
            'options': [
              {
                'name': 'role',
                'type': 2, // SUB_COMMAND_GROUP
                'options': [
                  {
                    'name': 'add',
                    'type': 1, // SUB_COMMAND
                    'options': null,
                  }
                ],
              }
            ],
            'guild_id': null,
          },
        });

        expect(
            logger.warnings,
            contains(
                contains('Unknown command received: "settings.role.add"')));
      });

      test('found sub-command does not log unknown warning', () async {
        manager.commandsHandler.add(CommandRegistration(
          name: 'settings.color',
          handler: (ctx, opts) {},
          declaredOptions: [],
        ));

        await dispatcher.dispatch({
          'id': '111111111111111111',
          'application_id': '222222222222222222',
          'token': 'fake-token',
          'version': 1,
          'channel_id': '333333333333333333',
          'member': {
            'user': {'id': '444444444444444444'}
          },
          'data': {
            'name': 'settings',
            'options': [
              {
                'name': 'color',
                'type': 1, // SUB_COMMAND
                'options': null,
              }
            ],
            'guild_id': null,
          },
        });

        expect(logger.warnings.where((w) => w.contains('Unknown command')),
            isEmpty);
      });
    });

    group('handler invocation', () {
      test('invokes handler with correct options for global command', () async {
        String? receivedValue;

        manager.commandsHandler.add(CommandRegistration(
          name: 'greet',
          handler: (ctx, opts) {
            receivedValue = (opts as CommandOptions).get<String>('name');
          },
          declaredOptions: [],
        ));

        await dispatcher.dispatch({
          'id': '111111111111111111',
          'application_id': '222222222222222222',
          'token': 'fake-token',
          'version': 1,
          'channel_id': '333333333333333333',
          'member': {
            'user': {'id': '444444444444444444'}
          },
          'data': {
            'name': 'greet',
            'options': [
              {'name': 'name', 'type': 3, 'value': 'World'},
            ],
            'guild_id': null,
          },
        });

        expect(receivedValue, equals('World'));
      });

      test('invokes handler with no options', () async {
        bool handlerCalled = false;

        manager.commandsHandler.add(CommandRegistration(
          name: 'ping',
          handler: (ctx, opts) {
            handlerCalled = true;
          },
          declaredOptions: [],
        ));

        await dispatcher.dispatch({
          'id': '111111111111111111',
          'application_id': '222222222222222222',
          'token': 'fake-token',
          'version': 1,
          'channel_id': '333333333333333333',
          'member': {
            'user': {'id': '444444444444444444'}
          },
          'data': {
            'name': 'ping',
            'options': null,
            'guild_id': null,
          },
        });

        expect(handlerCalled, isTrue);
      });
    });

    group('error handling', () {
      test('calls onCommandError when handler throws an Exception', () async {
        CommandFailure? capturedFailure;
        manager.onCommandError = (failure) {
          capturedFailure = failure;
        };

        manager.commandsHandler.add(CommandRegistration(
          name: 'fail',
          handler: (ctx, opts) {
            throw Exception('handler error');
          },
          declaredOptions: [],
        ));

        await dispatcher.dispatch({
          'id': '111111111111111111',
          'application_id': '222222222222222222',
          'token': 'fake-token',
          'version': 1,
          'channel_id': '333333333333333333',
          'member': {
            'user': {'id': '444444444444444444'}
          },
          'data': {
            'name': 'fail',
            'options': null,
            'guild_id': null,
          },
        });

        expect(capturedFailure, isNotNull);
        expect(capturedFailure!.commandName, equals('fail'));
        expect(capturedFailure!.error, isA<Exception>());
        expect(logger.errors,
            contains(contains('Failed to execute command handler "fail"')));
      });

      test('does not propagate exception when handler throws', () async {
        manager.onCommandError = (failure) {};

        manager.commandsHandler.add(CommandRegistration(
          name: 'boom',
          handler: (ctx, opts) {
            throw Exception('unexpected');
          },
          declaredOptions: [],
        ));

        await expectLater(
            dispatcher.dispatch({
              'id': '111111111111111111',
              'application_id': '222222222222222222',
              'token': 'fake-token',
              'version': 1,
              'channel_id': '333333333333333333',
              'member': {
                'user': {'id': '444444444444444444'}
              },
              'data': {
                'name': 'boom',
                'options': null,
                'guild_id': null,
              },
            }),
            completes);
      });
    });

    group('context menu routing', () {
      test('routes type=2 (USER) and logs unknown when no handler matches',
          () async {
        await dispatcher.dispatch({
          'data': {
            'name': 'Get user info',
            'type': 2,
            'target_id': '444444444444444444',
            'resolved': {
              'users': {
                '444444444444444444': {'id': '444444444444444444'},
              },
            },
          },
        });

        expect(
            logger.warnings,
            contains(contains(
                'Unknown user context command received: "Get user info"')));
      });

      test('routes type=3 (MESSAGE) and logs unknown when no handler matches',
          () async {
        await dispatcher.dispatch({
          'data': {
            'name': 'Report message',
            'type': 3,
            'target_id': '555555555555555555',
            'resolved': {
              'messages': {
                '555555555555555555': {'id': '555555555555555555'},
              },
            },
          },
        });

        expect(
            logger.warnings,
            contains(contains(
                'Unknown message context command received: "Report message"')));
      });

      test('does not treat type=2 as chat_input sub-command path', () async {
        await dispatcher.dispatch({
          'data': {
            'name': 'Get user info',
            'type': 2,
            'target_id': '444444444444444444',
            'resolved': {
              'users': {
                '444444444444444444': {'id': '444444444444444444'},
              },
            },
          },
        });

        expect(logger.warnings.where((w) => w.contains('Unknown command received')),
            isEmpty);
      });
    });

    group('required options validation', () {
      test('logs error when required option is missing', () async {
        manager.commandsHandler.add(CommandRegistration(
          name: 'greet',
          handler: (ctx, opts) {
            fail('handler should not be called');
          },
          declaredOptions: [
            Option.string(
              name: 'username',
              description: 'The user to greet',
              required: true,
            ),
          ],
        ));

        await dispatcher.dispatch({
          'id': '111111111111111111',
          'application_id': '222222222222222222',
          'token': 'fake-token',
          'version': 1,
          'channel_id': '333333333333333333',
          'member': {
            'user': {'id': '444444444444444444'}
          },
          'data': {
            'name': 'greet',
            'options': null,
            'guild_id': null,
          },
        });

        expect(
            logger.errors,
            contains(contains(
                'requires option "username" but it was not provided')));
      });

      test('proceeds when required option is present', () async {
        String? receivedValue;

        manager.commandsHandler.add(CommandRegistration(
          name: 'greet',
          handler: (ctx, opts) {
            receivedValue = (opts as CommandOptions).get<String>('username');
          },
          declaredOptions: [
            Option.string(
              name: 'username',
              description: 'The user to greet',
              required: true,
            ),
          ],
        ));

        await dispatcher.dispatch({
          'id': '111111111111111111',
          'application_id': '222222222222222222',
          'token': 'fake-token',
          'version': 1,
          'channel_id': '333333333333333333',
          'member': {
            'user': {'id': '444444444444444444'}
          },
          'data': {
            'name': 'greet',
            'options': [
              {'name': 'username', 'type': 3, 'value': 'Alice'},
            ],
            'guild_id': null,
          },
        });

        expect(receivedValue, equals('Alice'));
      });
    });
  });
}
