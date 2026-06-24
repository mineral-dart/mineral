/// Common helpers shared across packet tests.
///
/// Provides:
/// - [buildMinimalGuild]: construct a Guild with managers wired.
/// - [buildMockDs]: create a [MockDataStore] with any combination of parts
///   pre-stubbed.  Any unstubbed part raises a MissingStubError on access,
///   which behaves exactly like the old UnimplementedError.
/// - [buildCtx]: create an [EntityContext] backed by a [MockDataStore].
/// - [FakeGuildPart], [FakeUserPart], [FakeChannelPart]: concrete part stubs
///   that return a fixed domain object.
library;

import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/api/guild/managers/rules_manager.dart';
import 'package:mineral/src/api/guild/managers/threads_manager.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/common/runtime_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fake_logger.dart';
import '../../helpers/fake_websocket_orchestrator.dart';
import '../../helpers/mocks.dart';

// ── Domain builders ───────────────────────────────────────────────────────────

Guild buildMinimalGuild(String guildId, EntityContext ctx) {
  final id = Snowflake.parse(guildId);
  return Guild(
    ctx: ctx,
    id: id,
    name: 'Test Guild',
    ownerId: Snowflake.parse('000000000000000001'),
    description: null,
    applicationId: null,
    members: MemberManager(id, ctx: ctx),
    settings: GuildSettings(
      bitfieldPermission: null,
      afkTimeout: null,
      hasWidgetEnabled: false,
      verificationLevel: VerificationLevel.none,
      defaultMessageNotifications: DefaultMessageNotification.allMessages,
      explicitContentFilter: ExplicitContentFilter.disabled,
      features: [],
      mfaLevel: MfaLevel.none,
      systemChannelFlags: [],
      vanityUrlCode: null,
      subscription: GuildSubscription(
        tier: PremiumTier.none,
        subscriptionCount: null,
        hasEnabledProgressBar: false,
      ),
      preferredLocale: 'en-US',
      maxVideoChannelUsers: null,
      nsfwLevel: NsfwLevel.none,
      rulesManager: RulesManager(id, ctx: ctx),
    ),
    roles: RoleManager(id, ctx: ctx),
    channels: ChannelManager(
      id,
      ctx: ctx,
      afkChannelId: null,
      systemChannelId: null,
      rulesChannelId: null,
      publicUpdatesChannelId: null,
      safetyAlertsChannelId: null,
    ),
    threads: ThreadsManager(id, null, ctx: ctx),
    assets: GuildAsset(
      id,
      ctx: ctx,
      emojis: EmojiManager(id, ctx: ctx),
      stickers: StickerManager(id, ctx: ctx),
      icon: null,
      splash: null,
      banner: null,
      discoverySplash: null,
    ),
  );
}

// ── MockDataStore factory ─────────────────────────────────────────────────────

/// Creates a [MockDataStore] with the requested parts pre-stubbed.
///
/// Any part not provided here will raise a [MissingStubError] if accessed —
/// which is the same failure mode as the old `UnimplementedError` stubs.
MockDataStore buildMockDs({
  GuildPartContract? guild,
  ChannelPartContract? channel,
  UserPartContract? user,
  MemberPartContract? member,
  MessagePartContract? message,
  RolePartContract? role,
  InteractionPartContract? interaction,
}) {
  final ds = MockDataStore();
  if (guild != null) {
    when(() => ds.guild).thenReturn(guild);
  }
  if (channel != null) {
    when(() => ds.channel).thenReturn(channel);
  }
  if (user != null) {
    when(() => ds.user).thenReturn(user);
  }
  if (member != null) {
    when(() => ds.member).thenReturn(member);
  }
  if (message != null) {
    when(() => ds.message).thenReturn(message);
  }
  if (role != null) {
    when(() => ds.role).thenReturn(role);
  }
  if (interaction != null) {
    when(() => ds.interaction).thenReturn(interaction);
  }
  return ds;
}

// ── Context builder ───────────────────────────────────────────────────────────

/// Creates a minimal [EntityContext] pointing at the provided datastore.
EntityContext buildCtx({
  required DataStoreContract dataStore,
  WebsocketOrchestratorContract? wss,
}) =>
    EntityContext(
      datastore: dataStore,
      wss: wss ?? FakeWebsocketOrchestrator(),
      logger: FakeLogger(),
      runtimeState: RuntimeState(),
    );

// ── Part stubs ────────────────────────────────────────────────────────────────

final class FakeGuildPart implements GuildPartContract {
  final Guild _guild;
  FakeGuildPart(this._guild);

  @override
  Future<Guild> get(Object id, bool force) async => _guild;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

final class FakeUserPart implements UserPartContract {
  final User? _user;
  FakeUserPart([this._user]);

  @override
  Future<User?> get(Object id, bool force) async => _user;
}

final class FakeChannelPart implements ChannelPartContract {
  final Channel? _channel;
  FakeChannelPart([this._channel]);

  @override
  Future<T?> get<T extends Channel>(Object id, bool force) async {
    if (_channel is T) {
      return _channel as T?;
    }
    return null;
  }

  @override
  Future<Map<Snowflake, T>> fetch<T extends Channel>(
          Object guildId, bool force) async =>
      {};

  @override
  Future<T> create<T extends Channel>(Object? guildId,
          ChannelBuilderContract builder,
          {String? reason}) =>
      throw UnimplementedError();

  @override
  Future<PrivateChannel?> createPrivateChannel(
          Object id, String recipientId) async =>
      null;

  @override
  Future<T?> update<T extends Channel>(Object id, ChannelBuilderContract builder,
          {Object? guildId, String? reason}) =>
      throw UnimplementedError();

  @override
  Future<void> delete(Object id, String? reason) async {}
}
