import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/api/common/permissions.dart';
import 'package:mineral/src/domains/commands/command_interaction_dispatcher.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../helpers/fake_entity_context.dart';
import '../helpers/fake_logger.dart';
import '../helpers/fake_marshaller.dart';
import '../helpers/fake_websocket_orchestrator.dart';
import '../helpers/ioc_test_helper.dart';
import '../helpers/mocks.dart';
import '../packets/helpers/packet_test_helpers.dart';

/// Builds a [MockDataStore] pre-stubbed with channel (returns null) and user
/// (returns a minimal User) — the only parts exercised by the dispatcher tests.
MockDataStore _buildFakeDataStore() {
  final ds = MockDataStore();

  // channel part: always returns null (no active DM / guild channel lookup)
  final channelPart = MockChannelPart();
  when(
    () => channelPart.get<Channel>(any(), any()),
  ).thenAnswer((_) async => null);
  when(() => ds.channel).thenReturn(channelPart);

  // user part: returns a minimal User for any id
  final ctx = fakeEntityContext();
  final userPart = _FakeUserPart(ctx);
  when(() => ds.user).thenReturn(userPart);

  return ds;
}

final class _FakeUserPart implements UserPartContract {
  final EntityContext _ctx;
  _FakeUserPart(this._ctx);

  @override
  Future<User?> get(Object id, bool force) async {
    return User(
      ctx: _ctx,
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

const _guildId = '123456789012345678';
const _memberId = '444444444444444444';

final class _RecordingMemberPart extends Mock implements MemberPartContract {
  final Member _member;
  final List<String> calls = [];
  _RecordingMemberPart(this._member);

  @override
  Future<Member?> get(Object guildId, Object id, bool force) async {
    calls.add('$guildId/$id');
    return _member;
  }
}

final class _RecordingUserPart implements UserPartContract {
  final UserPartContract _inner;
  final List<String> calls = [];
  _RecordingUserPart(this._inner);

  @override
  Future<User?> get(Object id, bool force) {
    calls.add(id.toString());
    return _inner.get(id, force);
  }
}

Member _buildMember(EntityContext ctx) {
  final memberId = Snowflake.parse(_memberId);
  final guildId = Snowflake.parse(_guildId);
  return Member(
    ctx: ctx,
    id: memberId,
    username: 'testuser',
    nickname: null,
    globalName: null,
    discriminator: null,
    assets: MemberAssets(avatar: null, avatarDecoration: null, banner: null),
    flags: MemberFlagsManager([], ctx: ctx),
    premiumSince: null,
    publicFlags: null,
    roles: MemberRoleManager([], guildId, memberId, ctx: ctx),
    isBot: false,
    isPending: false,
    timeout: MemberTimeout(duration: null),
    mfaEnabled: false,
    locale: null,
    premiumType: PremiumTier.none,
    joinedAt: null,
    permissions: Permissions.fromInt(0),
    accentColor: null,
    guildId: guildId,
  );
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

      final fakeMarshaller = FakeMarshaller(logger: logger);
      final fakeDataStore = _buildFakeDataStore();

      dispatcher = CommandInteractionDispatcher(
        manager,
        marshaller: fakeMarshaller,
        dataStore: fakeDataStore,
        ctx: fakeEntityContext(),
      );

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
      }, wss: FakeWebsocketOrchestrator());

      testIoc.container
        ..bind<MarshallerContract>(() => fakeMarshaller)
        ..bind<DataStoreContract>(() => fakeDataStore)
        ..bind<Bot>(() => fakeBot);
    });

    tearDown(() {
      restoreIoc();
    });

    group('unknown command', () {
      test('logs warning when no handler matches', () async {
        await dispatcher.dispatch({
          'data': {'name': 'nonexistent', 'options': null, 'guild_id': null},
        });

        expect(
          logger.warnings,
          contains(contains('Unknown command received: "nonexistent"')),
        );
      });

      test('does not throw when command is unknown', () async {
        await expectLater(
          dispatcher.dispatch({
            'data': {'name': 'nonexistent', 'options': null, 'guild_id': null},
          }),
          completes,
        );
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
              },
            ],
            'guild_id': null,
          },
        });

        expect(
          logger.warnings,
          contains(contains('Unknown command received: "admin.kick"')),
        );
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
                  },
                ],
              },
            ],
            'guild_id': null,
          },
        });

        expect(
          logger.warnings,
          contains(contains('Unknown command received: "settings.role.add"')),
        );
      });

      test('found sub-command does not log unknown warning', () async {
        manager.commandsHandler.add(
          CommandRegistration(
            name: 'settings.color',
            handler: (ctx, opts) {},
            declaredOptions: [],
          ),
        );

        await dispatcher.dispatch({
          'id': '111111111111111111',
          'application_id': '222222222222222222',
          'token': 'fake-token',
          'version': 1,
          'channel_id': '333333333333333333',
          'member': {
            'user': {'id': '444444444444444444'},
          },
          'data': {
            'name': 'settings',
            'options': [
              {
                'name': 'color',
                'type': 1, // SUB_COMMAND
                'options': null,
              },
            ],
            'guild_id': null,
          },
        });

        expect(
          logger.warnings.where((w) => w.contains('Unknown command')),
          isEmpty,
        );
      });
    });

    group('handler invocation', () {
      test('invokes handler with correct options for global command', () async {
        String? receivedValue;

        manager.commandsHandler.add(
          CommandRegistration(
            name: 'greet',
            handler: (ctx, opts) {
              receivedValue = (opts as CommandOptions).get<String>('name');
            },
            declaredOptions: [],
          ),
        );

        await dispatcher.dispatch({
          'id': '111111111111111111',
          'application_id': '222222222222222222',
          'token': 'fake-token',
          'version': 1,
          'channel_id': '333333333333333333',
          'member': {
            'user': {'id': '444444444444444444'},
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

        manager.commandsHandler.add(
          CommandRegistration(
            name: 'ping',
            handler: (ctx, opts) {
              handlerCalled = true;
            },
            declaredOptions: [],
          ),
        );

        await dispatcher.dispatch({
          'id': '111111111111111111',
          'application_id': '222222222222222222',
          'token': 'fake-token',
          'version': 1,
          'channel_id': '333333333333333333',
          'member': {
            'user': {'id': '444444444444444444'},
          },
          'data': {'name': 'ping', 'options': null, 'guild_id': null},
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

        manager.commandsHandler.add(
          CommandRegistration(
            name: 'fail',
            handler: (ctx, opts) {
              throw Exception('handler error');
            },
            declaredOptions: [],
          ),
        );

        await dispatcher.dispatch({
          'id': '111111111111111111',
          'application_id': '222222222222222222',
          'token': 'fake-token',
          'version': 1,
          'channel_id': '333333333333333333',
          'member': {
            'user': {'id': '444444444444444444'},
          },
          'data': {'name': 'fail', 'options': null, 'guild_id': null},
        });

        expect(capturedFailure, isNotNull);
        expect(capturedFailure!.commandName, equals('fail'));
        expect(capturedFailure!.error, isA<Exception>());
        expect(
          logger.errors,
          contains(contains('Failed to execute command handler "fail"')),
        );
      });

      test('does not propagate exception when handler throws', () async {
        manager.onCommandError = (failure) {};

        manager.commandsHandler.add(
          CommandRegistration(
            name: 'boom',
            handler: (ctx, opts) {
              throw Exception('unexpected');
            },
            declaredOptions: [],
          ),
        );

        await expectLater(
          dispatcher.dispatch({
            'id': '111111111111111111',
            'application_id': '222222222222222222',
            'token': 'fake-token',
            'version': 1,
            'channel_id': '333333333333333333',
            'member': {
              'user': {'id': '444444444444444444'},
            },
            'data': {'name': 'boom', 'options': null, 'guild_id': null},
          }),
          completes,
        );
      });
    });

    group('context menu routing', () {
      test(
        'routes type=2 (USER) and logs unknown when no handler matches',
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
            contains(
              contains(
                'Unknown user context command received: "Get user info"',
              ),
            ),
          );
        },
      );

      test(
        'routes type=3 (MESSAGE) and logs unknown when no handler matches',
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
            contains(
              contains(
                'Unknown message context command received: "Report message"',
              ),
            ),
          );
        },
      );

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

        expect(
          logger.warnings.where((w) => w.contains('Unknown command received')),
          isEmpty,
        );
      });
    });

    group('required options validation', () {
      test('logs error when required option is missing', () async {
        manager.commandsHandler.add(
          CommandRegistration(
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
          ),
        );

        await dispatcher.dispatch({
          'id': '111111111111111111',
          'application_id': '222222222222222222',
          'token': 'fake-token',
          'version': 1,
          'channel_id': '333333333333333333',
          'member': {
            'user': {'id': '444444444444444444'},
          },
          'data': {'name': 'greet', 'options': null, 'guild_id': null},
        });

        expect(
          logger.errors,
          contains(
            contains('requires option "username" but it was not provided'),
          ),
        );
      });

      test('proceeds when required option is present', () async {
        String? receivedValue;

        manager.commandsHandler.add(
          CommandRegistration(
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
          ),
        );

        await dispatcher.dispatch({
          'id': '111111111111111111',
          'application_id': '222222222222222222',
          'token': 'fake-token',
          'version': 1,
          'channel_id': '333333333333333333',
          'member': {
            'user': {'id': '444444444444444444'},
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

    group('context selection', () {
      late _RecordingMemberPart memberPart;
      late _RecordingUserPart userPart;
      late CommandInteractionDispatcher scoped;

      setUp(() {
        final ds = MockDataStore();
        final ctx = buildCtx(dataStore: ds);
        final channelPart = MockChannelPart();
        when(
          () => channelPart.get<Channel>(any(), any()),
        ).thenAnswer((_) async => null);
        memberPart = _RecordingMemberPart(_buildMember(ctx));
        userPart = _RecordingUserPart(_FakeUserPart(ctx));
        when(() => ds.channel).thenReturn(channelPart);
        when(() => ds.member).thenReturn(memberPart);
        when(() => ds.user).thenReturn(userPart);
        when(
          () => ds.guild,
        ).thenReturn(FakeGuildPart(buildMinimalGuild(_guildId, ctx)));

        scoped = CommandInteractionDispatcher(
          manager,
          marshaller: FakeMarshaller(logger: logger),
          dataStore: ds,
          ctx: ctx,
        );
      });

      Map<String, dynamic> payload({required bool inGuild}) => {
        'id': '111111111111111111',
        'application_id': '222222222222222222',
        'token': 'fake-token',
        'version': 1,
        'channel_id': '333333333333333333',
        if (inGuild) 'guild_id': _guildId,
        'member': {
          'user': {'id': _memberId},
        },
        'data': {
          'name': 'whois',
          'options': [
            {'name': 'target', 'type': 6, 'value': '555555555555555555'},
          ],
        },
      };

      test('global command used in a guild yields GuildCommandContext and '
          'resolves user options as members', () async {
        Object? received;
        Object? target;
        manager.commandsHandler.add(
          CommandRegistration(
            name: 'whois',
            handler: (ctx, opts) {
              received = ctx;
              target = (opts as CommandOptions).get<Object>('target');
            },
            declaredOptions: [],
          ),
        );

        await scoped.dispatch(payload(inGuild: true));

        expect(received, isA<GuildCommandContext>());
        expect(target, isA<Member>());
        expect(memberPart.calls, contains('$_guildId/555555555555555555'));
        expect(userPart.calls, isEmpty);
      });

      test('command without top-level guild_id yields GlobalCommandContext '
          'and resolves user options as users', () async {
        Object? received;
        Object? target;
        manager.commandsHandler.add(
          CommandRegistration(
            name: 'whois',
            handler: (ctx, opts) {
              received = ctx;
              target = (opts as CommandOptions).get<Object>('target');
            },
            declaredOptions: [],
          ),
        );

        await scoped.dispatch(payload(inGuild: false));

        expect(received, isA<GlobalCommandContext>());
        expect(target, isA<User>());
        expect(userPart.calls, contains('555555555555555555'));
      });
    });
  });
}
