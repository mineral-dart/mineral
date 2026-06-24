import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/api/common/permissions.dart';
import 'package:mineral/src/api/guild/managers/threads_manager.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/common/runtime_state.dart';
import 'package:mineral/src/testing/fake_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../helpers/fake_websocket_orchestrator.dart';

// ── Fakes & Mocks ──────────────────────────────────────────────────────────

/// Minimal no-op [ChannelBuilderContract] needed as a mocktail fallback value.
final class _FakeChannelBuilder extends Fake implements ChannelBuilderContract {}

class _MockMemberPart extends Mock implements MemberPartContract {}

class _MockRolePart extends Mock implements RolePartContract {}

class _MockChannelPart extends Mock implements ChannelPartContract {}

class _MockMessagePart extends Mock implements MessagePartContract {}

// ── Minimal DataStoreContract implementations ──────────────────────────────
//
// Because DataStoreContract is an abstract interface (not final), we can
// implement it directly and override only the parts we need.

final class _MemberRoleDataStore implements DataStoreContract {
  final MemberPartContract _member;
  final RolePartContract _role;

  _MemberRoleDataStore(this._member, this._role);

  @override
  MemberPartContract get member => _member;

  @override
  RolePartContract get role => _role;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

final class _ChannelMessageDataStore implements DataStoreContract {
  final ChannelPartContract _channel;
  final MessagePartContract _message;

  _ChannelMessageDataStore(this._channel, this._message);

  @override
  ChannelPartContract get channel => _channel;

  @override
  MessagePartContract get message => _message;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

final class _MessageOnlyDataStore implements DataStoreContract {
  final MessagePartContract _message;

  _MessageOnlyDataStore(this._message);

  @override
  MessagePartContract get message => _message;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

final class _RoleDataStore implements DataStoreContract {
  final RolePartContract _role;

  _RoleDataStore(this._role);

  @override
  RolePartContract get role => _role;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

// ── Helpers ────────────────────────────────────────────────────────────────

EntityContext _ctx(DataStoreContract dataStore) => EntityContext(
      datastore: dataStore,
      wss: FakeWebsocketOrchestrator(),
      logger: FakeLogger(),
      runtimeState: RuntimeState(),
    );

Member _buildMember(EntityContext ctx) => Member(
      ctx: ctx,
      id: Snowflake('111000111000111000'),
      username: 'testuser',
      nickname: null,
      globalName: 'TestUser',
      discriminator: '0',
      assets: MemberAssets(avatar: null, avatarDecoration: null, banner: null),
      flags: MemberFlagsManager([], ctx: ctx),
      premiumSince: null,
      publicFlags: 0,
      roles: MemberRoleManager(
        [Snowflake('333000333000333000')],
        Snowflake('222000222000222000'),
        Snowflake('111000111000111000'),
        ctx: ctx,
      ),
      isBot: false,
      isPending: false,
      timeout: MemberTimeout(duration: null),
      mfaEnabled: false,
      locale: 'en-US',
      premiumType: PremiumTier.none,
      joinedAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
      permissions: Permissions.fromInt(0),
      accentColor: null,
      guildId: Snowflake('222000222000222000'),
    );

Role _buildRole(EntityContext ctx) => Role(
      ctx: ctx,
      id: Snowflake('444000444000444000'),
      name: 'moderator',
      color: Color.amber_500,
      hoist: false,
      position: 3,
      permissions: Permissions.fromInt(0),
      managed: false,
      mentionable: true,
      flags: 0,
      icon: null,
      unicodeEmoji: null,
      guildId: Snowflake('222000222000222000'),
    );

ChannelProperties _buildTextProps(EntityContext ctx) => ChannelProperties(
      ctx: ctx,
      id: Snowflake('555000555000555000'),
      type: ChannelType.guildText,
      name: 'general',
      description: null,
      guildId: Snowflake('222000222000222000'),
      categoryId: null,
      position: 1,
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
        Snowflake('222000222000222000'),
        Snowflake('555000555000555000'),
        ctx: ctx,
      ),
    );

ChannelProperties _buildVoiceProps(EntityContext ctx) => ChannelProperties(
      ctx: ctx,
      id: Snowflake('666000666000666000'),
      type: ChannelType.guildVoice,
      name: 'voice-chat',
      description: null,
      guildId: Snowflake('222000222000222000'),
      categoryId: null,
      position: 2,
      nsfw: false,
      lastMessageId: null,
      bitrate: 64000,
      userLimit: 5,
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
        Snowflake('222000222000222000'),
        Snowflake('666000666000666000'),
        ctx: ctx,
      ),
    );

MessageProperties _buildMessageProps() => MessageProperties(
      id: Snowflake('777000777000777000'),
      content: 'hello world',
      channelId: Snowflake('555000555000555000'),
      authorId: Snowflake('111000111000111000'),
      guildId: Snowflake('222000222000222000'),
      authorIsBot: false,
      embeds: [],
      createdAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
      updatedAt: null,
    );

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    registerFallbackValue(Duration.zero);
    registerFallbackValue(MessageBuilder());
    registerFallbackValue(Snowflake('0'));
    registerFallbackValue(_FakeChannelBuilder());
  });

  // ── Member.ban / kick / setNickname / exclude / unExclude ───────────────

  group('Member behavioural methods', () {
    late _MockMemberPart mockMember;
    late _MockRolePart mockRole;
    late Member member;

    setUp(() {
      mockMember = _MockMemberPart();
      mockRole = _MockRolePart();
      final ctx = _ctx(_MemberRoleDataStore(mockMember, mockRole));
      member = _buildMember(ctx);
    });

    group('ban', () {
      test('delegates to member.ban with correct guildId and memberId',
          () async {
        when(() => mockMember.ban(
              guildId: any(named: 'guildId'),
              memberId: any(named: 'memberId'),
              deleteSince: any(named: 'deleteSince'),
              reason: any(named: 'reason'),
            )).thenAnswer((_) async {});

        await member.ban();

        verify(() => mockMember.ban(
              guildId: '222000222000222000',
              memberId: '111000111000111000',
              deleteSince: null,
              reason: null,
            )).called(1);
      });

      test('forwards deleteSince duration', () async {
        when(() => mockMember.ban(
              guildId: any(named: 'guildId'),
              memberId: any(named: 'memberId'),
              deleteSince: any(named: 'deleteSince'),
              reason: any(named: 'reason'),
            )).thenAnswer((_) async {});

        await member.ban(deleteSince: const Duration(days: 7));

        final captured = verify(() => mockMember.ban(
              guildId: '222000222000222000',
              memberId: '111000111000111000',
              deleteSince: captureAny(named: 'deleteSince'),
              reason: null,
            )).captured;

        expect(captured.single, equals(const Duration(days: 7)));
      });
    });

    group('kick', () {
      test('delegates to member.kick with correct ids', () async {
        when(() => mockMember.kick(
              guildId: any(named: 'guildId'),
              memberId: any(named: 'memberId'),
              reason: any(named: 'reason'),
            )).thenAnswer((_) async {});

        await member.kick();

        verify(() => mockMember.kick(
              guildId: '222000222000222000',
              memberId: '111000111000111000',
              reason: null,
            )).called(1);
      });

      test('forwards reason', () async {
        when(() => mockMember.kick(
              guildId: any(named: 'guildId'),
              memberId: any(named: 'memberId'),
              reason: any(named: 'reason'),
            )).thenAnswer((_) async {});

        await member.kick(reason: 'spamming');

        verify(() => mockMember.kick(
              guildId: '222000222000222000',
              memberId: '111000111000111000',
              reason: 'spamming',
            )).called(1);
      });
    });

    group('setNickname', () {
      test('calls member.update with nick payload', () async {
        when(() => mockMember.update(
              guildId: any(named: 'guildId'),
              memberId: any(named: 'memberId'),
              payload: any(named: 'payload'),
              reason: any(named: 'reason'),
            )).thenAnswer((_) async => member);

        await member.setNickname('newNick', 'Testing');

        final captured = verify(() => mockMember.update(
              guildId: '222000222000222000',
              memberId: '111000111000111000',
              payload: captureAny(named: 'payload'),
              reason: 'Testing',
            )).captured;

        expect((captured.single as Map<String, dynamic>)['nick'],
            equals('newNick'));
      });
    });

    group('exclude (timeout)', () {
      test('calls member.update with communication_disabled_until', () async {
        when(() => mockMember.update(
              guildId: any(named: 'guildId'),
              memberId: any(named: 'memberId'),
              payload: any(named: 'payload'),
              reason: any(named: 'reason'),
            )).thenAnswer((_) async => member);

        await member.exclude(duration: const Duration(hours: 1));

        final captured = verify(() => mockMember.update(
              guildId: '222000222000222000',
              memberId: '111000111000111000',
              payload: captureAny(named: 'payload'),
              reason: null,
            )).captured;

        final payload = captured.single as Map<String, dynamic>;
        expect(payload.containsKey('communication_disabled_until'), isTrue);
        expect(payload['communication_disabled_until'], isNotNull);
      });
    });

    group('unExclude', () {
      test('calls member.update with null communication_disabled_until',
          () async {
        when(() => mockMember.update(
              guildId: any(named: 'guildId'),
              memberId: any(named: 'memberId'),
              payload: any(named: 'payload'),
              reason: any(named: 'reason'),
            )).thenAnswer((_) async => member);

        await member.unExclude();

        final captured = verify(() => mockMember.update(
              guildId: '222000222000222000',
              memberId: '111000111000111000',
              payload: captureAny(named: 'payload'),
              reason: null,
            )).captured;

        final payload = captured.single as Map<String, dynamic>;
        expect(payload['communication_disabled_until'], isNull);
      });
    });
  });

  // ── MemberRoleManager ───────────────────────────────────────────────────

  group('MemberRoleManager behavioural methods', () {
    late _MockMemberPart mockMember;
    late _MockRolePart mockRole;
    late Member member;

    setUp(() {
      mockMember = _MockMemberPart();
      mockRole = _MockRolePart();
      final ctx = _ctx(_MemberRoleDataStore(mockMember, mockRole));
      member = _buildMember(ctx);
    });

    test('add delegates to role.add with correct ids', () async {
      when(() => mockRole.add(
            memberId: any(named: 'memberId'),
            guildId: any(named: 'guildId'),
            roleId: any(named: 'roleId'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async {});

      await member.roles.add('444000444000444000');

      verify(() => mockRole.add(
            memberId: '111000111000111000',
            guildId: '222000222000222000',
            roleId: '444000444000444000',
            reason: null,
          )).called(1);
    });

    test('remove delegates to role.remove with correct ids', () async {
      when(() => mockRole.remove(
            memberId: any(named: 'memberId'),
            guildId: any(named: 'guildId'),
            roleId: any(named: 'roleId'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async {});

      await member.roles.remove('444000444000444000', reason: 'cleanup');

      verify(() => mockRole.remove(
            memberId: '111000111000111000',
            guildId: '222000222000222000',
            roleId: '444000444000444000',
            reason: 'cleanup',
          )).called(1);
    });

    test('sync delegates to role.sync with full list', () async {
      when(() => mockRole.sync(
            memberId: any(named: 'memberId'),
            guildId: any(named: 'guildId'),
            roleIds: any(named: 'roleIds'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async {});

      await member.roles.sync(['444000444000444000', '555000555000555000']);

      final captured = verify(() => mockRole.sync(
            memberId: '111000111000111000',
            guildId: '222000222000222000',
            roleIds: captureAny(named: 'roleIds'),
            reason: null,
          )).captured;

      expect(captured.single as List,
          containsAll(['444000444000444000', '555000555000555000']));
    });

    test('clear delegates to role.sync with empty list', () async {
      when(() => mockRole.sync(
            memberId: any(named: 'memberId'),
            guildId: any(named: 'guildId'),
            roleIds: any(named: 'roleIds'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async {});

      await member.roles.clear();

      final captured = verify(() => mockRole.sync(
            memberId: '111000111000111000',
            guildId: '222000222000222000',
            roleIds: captureAny(named: 'roleIds'),
            reason: null,
          )).captured;

      expect(captured.single, isEmpty);
    });
  });

  // ── Role ────────────────────────────────────────────────────────────────

  group('Role behavioural methods', () {
    late _MockRolePart mockRole;
    late Role role;

    setUp(() {
      mockRole = _MockRolePart();
      final ctx = _ctx(_RoleDataStore(mockRole));
      role = _buildRole(ctx);
    });

    test('setName calls role.update with name payload', () async {
      when(() => mockRole.update(
            id: any(named: 'id'),
            guildId: any(named: 'guildId'),
            payload: any(named: 'payload'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async => null);

      await role.setName('admin', 'rename reason');

      final captured = verify(() => mockRole.update(
            id: '444000444000444000',
            guildId: '222000222000222000',
            payload: captureAny(named: 'payload'),
            reason: 'rename reason',
          )).captured;

      expect(
          (captured.single as Map<String, dynamic>)['name'], equals('admin'));
    });

    test('setColor calls role.update with color int payload', () async {
      when(() => mockRole.update(
            id: any(named: 'id'),
            guildId: any(named: 'guildId'),
            payload: any(named: 'payload'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async => null);

      await role.setColor(Color.blue_500, null);

      final captured = verify(() => mockRole.update(
            id: '444000444000444000',
            guildId: '222000222000222000',
            payload: captureAny(named: 'payload'),
            reason: null,
          )).captured;

      final payload = captured.single as Map<String, dynamic>;
      expect(payload.containsKey('color'), isTrue);
      expect(payload['color'], isA<int>());
    });

    test('setMentionable calls role.update with mentionable payload', () async {
      when(() => mockRole.update(
            id: any(named: 'id'),
            guildId: any(named: 'guildId'),
            payload: any(named: 'payload'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async => null);

      await role.setMentionable(false, 'no-mention');

      final captured = verify(() => mockRole.update(
            id: '444000444000444000',
            guildId: '222000222000222000',
            payload: captureAny(named: 'payload'),
            reason: 'no-mention',
          )).captured;

      expect(
          (captured.single as Map<String, dynamic>)['mentionable'], isFalse);
    });

    test('delete calls role.delete with correct ids', () async {
      when(() => mockRole.delete(
            id: any(named: 'id'),
            guildId: any(named: 'guildId'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async {});

      await role.delete(reason: 'cleanup');

      verify(() => mockRole.delete(
            id: '444000444000444000',
            guildId: '222000222000222000',
            reason: 'cleanup',
          )).called(1);
    });

    test('update with multiple fields calls role.update', () async {
      when(() => mockRole.update(
            id: any(named: 'id'),
            guildId: any(named: 'guildId'),
            payload: any(named: 'payload'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async => null);

      await role.update(name: 'senior', hoist: true, mentionable: false);

      final captured = verify(() => mockRole.update(
            id: '444000444000444000',
            guildId: '222000222000222000',
            payload: captureAny(named: 'payload'),
            reason: null,
          )).captured;

      final payload = captured.single as Map<String, dynamic>;
      expect(payload['name'], equals('senior'));
      expect(payload['hoist'], isTrue);
      expect(payload['mentionable'], isFalse);
    });
  });

  // ── GuildTextChannel ────────────────────────────────────────────────────

  group('GuildTextChannel behavioural methods', () {
    late _MockChannelPart mockChannel;
    late _MockMessagePart mockMessage;
    late GuildTextChannel channel;

    setUp(() {
      mockChannel = _MockChannelPart();
      mockMessage = _MockMessagePart();
      final ctx = _ctx(_ChannelMessageDataStore(mockChannel, mockMessage));
      channel = GuildTextChannel(_buildTextProps(ctx));
    });

    test('setName calls channel.update', () async {
      when(() => mockChannel.update(
            any(),
            any(),
            guildId: any(named: 'guildId'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async => null);

      await channel.setName('announcements');

      verify(() => mockChannel.update(
            '555000555000555000',
            any(),
            guildId: '222000222000222000',
            reason: null,
          )).called(1);
    });

    test('delete without reason calls channel.delete', () async {
      when(() => mockChannel.delete(any(), any())).thenAnswer((_) async {});

      await channel.delete();

      verify(() => mockChannel.delete('555000555000555000', null)).called(1);
    });

    test('delete with reason forwards it', () async {
      when(() => mockChannel.delete(any(), any())).thenAnswer((_) async {});

      await channel.delete(reason: 'clean-up');

      verify(() => mockChannel.delete('555000555000555000', 'clean-up'))
          .called(1);
    });

    test('send delegates to message.send', () async {
      final builder = MessageBuilder.text('hello');
      when(() => mockMessage.send<Message>(any(), any(), any()))
          .thenAnswer((_) async => throw UnimplementedError());

      expect(() => channel.send(builder), throwsA(isA<UnimplementedError>()));

      verify(() => mockMessage.send<Message>(
            '222000222000222000',
            '555000555000555000',
            any(),
          )).called(1);
    });
  });

  // ── GuildVoiceChannel ───────────────────────────────────────────────────

  group('GuildVoiceChannel behavioural methods', () {
    late _MockChannelPart mockChannel;
    late GuildVoiceChannel voiceChannel;

    setUp(() {
      mockChannel = _MockChannelPart();
      final mockMessage = _MockMessagePart();
      final ctx = _ctx(_ChannelMessageDataStore(mockChannel, mockMessage));
      voiceChannel = GuildVoiceChannel(_buildVoiceProps(ctx))..members = [];
    });

    test('setBitrate calls channel.update', () async {
      when(() => mockChannel.update(
            any(),
            any(),
            guildId: any(named: 'guildId'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async => null);

      await voiceChannel.setBitrate(96000);

      verify(() => mockChannel.update(
            '666000666000666000',
            any(),
            guildId: '222000222000222000',
            reason: null,
          )).called(1);
    });

    test('setUserLimit calls channel.update', () async {
      when(() => mockChannel.update(
            any(),
            any(),
            guildId: any(named: 'guildId'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async => null);

      await voiceChannel.setUserLimit(10);

      verify(() => mockChannel.update(
            '666000666000666000',
            any(),
            guildId: '222000222000222000',
            reason: null,
          )).called(1);
    });

    test('setName calls channel.update', () async {
      when(() => mockChannel.update(
            any(),
            any(),
            guildId: any(named: 'guildId'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async => null);

      await voiceChannel.setName('stage');

      verify(() => mockChannel.update(
            '666000666000666000',
            any(),
            guildId: '222000222000222000',
            reason: null,
          )).called(1);
    });
  });

  // ── Message ─────────────────────────────────────────────────────────────

  group('Message behavioural methods', () {
    late _MockMessagePart mockMessage;
    late Message message;

    setUp(() {
      mockMessage = _MockMessagePart();
      final ctx = _ctx(_MessageOnlyDataStore(mockMessage));
      message = Message(_buildMessageProps(), ctx: ctx);
    });

    group('edit', () {
      test('calls message.update with correct id and channelId', () async {
        final builder = MessageBuilder.text('edited');
        when(() => mockMessage.update<Message>(
              id: any(named: 'id'),
              channelId: any(named: 'channelId'),
              builder: any(named: 'builder'),
            )).thenAnswer((_) async => throw UnimplementedError());

        expect(
            () => message.edit(builder), throwsA(isA<UnimplementedError>()));

        verify(() => mockMessage.update<Message>(
              id: '777000777000777000',
              channelId: '555000555000555000',
              builder: any(named: 'builder'),
            )).called(1);
      });
    });

    group('delete', () {
      test('calls message.delete with channelId and messageId', () async {
        when(() => mockMessage.delete(any(), any())).thenAnswer((_) async {});

        await message.delete();

        verify(() => mockMessage.delete(
              Snowflake('555000555000555000'),
              Snowflake('777000777000777000'),
            )).called(1);
      });
    });

    group('pin', () {
      test('calls message.pin with correct ids', () async {
        when(() => mockMessage.pin(any(), any())).thenAnswer((_) async {});

        await message.pin();

        verify(() => mockMessage.pin(
              Snowflake('555000555000555000'),
              Snowflake('777000777000777000'),
            )).called(1);
      });
    });

    group('unpin', () {
      test('calls message.unpin with correct ids', () async {
        when(() => mockMessage.unpin(any(), any())).thenAnswer((_) async {});

        await message.unpin();

        verify(() => mockMessage.unpin(
              Snowflake('555000555000555000'),
              Snowflake('777000777000777000'),
            )).called(1);
      });
    });

    group('reply', () {
      test('calls message.reply with message id and channelId', () async {
        final builder = MessageBuilder.text('reply!');
        when(() => mockMessage.reply<Channel, Message>(
              any(),
              any(),
              any(),
            )).thenAnswer((_) async => throw UnimplementedError());

        expect(
          () => message.reply<Message>(builder),
          throwsA(isA<UnimplementedError>()),
        );

        verify(() => mockMessage.reply<Channel, Message>(
              Snowflake('777000777000777000'),
              Snowflake('555000555000555000'),
              any(),
            )).called(1);
      });
    });

    group('forward', () {
      test('calls message.forward with target channelId', () async {
        final targetChannel = Snowflake('888000888000888000');
        when(() => mockMessage.forward<Message>(
              any(),
              messageId: any(named: 'messageId'),
              sourceChannelId: any(named: 'sourceChannelId'),
              guildId: any(named: 'guildId'),
            )).thenAnswer((_) async => throw UnimplementedError());

        expect(
          () => message.forward<Message>(targetChannel),
          throwsA(isA<UnimplementedError>()),
        );

        verify(() => mockMessage.forward<Message>(
              targetChannel,
              messageId: Snowflake('777000777000777000'),
              sourceChannelId: Snowflake('555000555000555000'),
              guildId: any(named: 'guildId'),
            )).called(1);
      });
    });
  });

  // ── ChannelMethods (shared) ──────────────────────────────────────────────

  group('ChannelMethods — shared behaviour', () {
    late _MockChannelPart mockChannel;
    late ChannelMethods methods;

    setUp(() {
      mockChannel = _MockChannelPart();
      final mockMessage = _MockMessagePart();
      final ctx = _ctx(_ChannelMessageDataStore(mockChannel, mockMessage));
      methods = ChannelMethods(
        Snowflake('222000222000222000'),
        Snowflake('555000555000555000'),
        ctx: ctx,
      );
    });

    test('setDescription calls channel.update', () async {
      when(() => mockChannel.update(
            any(),
            any(),
            guildId: any(named: 'guildId'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async => null);

      await methods.setDescription('A text channel', null);

      verify(() => mockChannel.update(
            '555000555000555000',
            any(),
            guildId: '222000222000222000',
            reason: null,
          )).called(1);
    });

    test('setPosition calls channel.update', () async {
      when(() => mockChannel.update(
            any(),
            any(),
            guildId: any(named: 'guildId'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async => null);

      await methods.setPosition(5, null);

      verify(() => mockChannel.update(
            '555000555000555000',
            any(),
            guildId: '222000222000222000',
            reason: null,
          )).called(1);
    });

    test('delete calls channel.delete with reason', () async {
      when(() => mockChannel.delete(any(), any())).thenAnswer((_) async {});

      await methods.delete('test-reason');

      verify(() => mockChannel.delete('555000555000555000', 'test-reason'))
          .called(1);
    });
  });
}
