import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/api/common/permissions.dart';
import 'package:mineral/src/api/common/user_client.dart';
import 'package:mineral/src/api/server/managers/member_voice_manager.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class Member implements UserClient {
  final EntityContext _ctx;

  DataStoreContract get _datastore => _ctx.datastore;
  WebsocketOrchestratorContract get _wss => _ctx.wss;

  final Snowflake id;
  final String username;
  final String? nickname;
  final String? globalName;
  final String? discriminator;
  final MemberAssets assets;
  final DateTime? premiumSince;
  final int? publicFlags;
  final MemberRoleManager roles;
  final bool isBot;
  final bool isPending;
  final MemberTimeout timeout;
  final bool mfaEnabled;
  final String? locale;
  final PremiumTier premiumType;
  final DateTime? joinedAt;
  final Permissions permissions;
  final int? accentColor;
  final MemberFlagsManager flags;
  final Snowflake serverId;

  /// Get related [Server]
  /// ```dart
  /// final server = await member.resolveServer();
  /// ```
  /// You can `force` the update by setting the `force` parameter to `true` to override [CacheProviderContract] by the Discord APi Response.
  /// ```dart
  /// final server = await member.resolveServer(force: true);
  /// ```
  Future<Server> resolveServer() => _datastore.server.get(serverId.value, true);

  /// Get the [VoiceState] of the member inside [MemberVoiceManager].
  /// ```dart
  /// final voice = await member.resolveVoiceContext();
  /// ```
  ///
  /// You can `force` the update by setting the `force` parameter to `true` to override [CacheProviderContract] by the Discord APi Response.
  /// ```dart
  /// final voice = await member.resolveVoiceContext(force: true);
  /// ```
  Future<MemberVoiceManager> resolveVoiceContext({bool force = false}) async {
    final voiceState =
        await _datastore.member.getVoiceState(serverId.value, id.value, force);
    return MemberVoiceManager(serverId, id, voiceState, ctx: _ctx);
  }

  /// Get the [Presence] of the member.
  /// ```dart
  /// final presence = await member.resolvePresence();
  /// ```
  Future<Presence> resolvePresence() =>
      _wss.getMemberPresence(serverId.value, id.value);

  DateTime get createdAt => id.createdAt;

  /// Check if the member can bypass verification.
  ///
  /// ```dart
  /// if (member.canByPassVerification()) {
  ///  print('Member can bypass verification');
  /// }
  ///```
  bool get canByPassVerification =>
      flags.list.contains(MemberFlag.bypassedVerification);

  /// Check if the member has completed onboarding.
  ///
  /// ```dart
  /// if (member.hasCompletedOnboarding()) {
  ///   print('Member has completed onboarding');
  /// }
  ///```
  bool get hasCompletedOnboarding =>
      flags.list.contains(MemberFlag.completedOnboarding);

  /// Check if the member has started onboarding.
  ///
  /// ```dart
  /// if (member.hasStartedOnboarding()) {
  ///    print('Member has started onboarding');
  /// }
  ///```
  bool get hasStartedOnboarding =>
      flags.list.contains(MemberFlag.startedOnboarding);

  /// Check if the member has already rejoined the server.
  ///
  /// ```dart
  /// if (member.hasRejoined()) {
  ///    print('Member has rejoined the server');
  /// }
  ///```
  bool get hasRejoined => flags.list.contains(MemberFlag.didRejoin);

  /// Change the member's username.
  ///
  /// ```dart
  /// await member.setUsername('new-username', 'Testing');
  /// ```
  Future<void> setUsername(String value, String? reason) =>
      _datastore.member.update(
          serverId: serverId.value,
          memberId: id.value,
          payload: {'username': value},
          reason: reason);

  /// Change the member's nickname.
  ///
  /// ```dart
  /// await member.setNickname('new-nickname', 'Testing');
  /// ```
  Future<void> setNickname(String value, String? reason) =>
      _datastore.member.update(
          serverId: serverId.value,
          memberId: id.value,
          payload: {'nick': value},
          reason: reason);

  /// Ban the member.
  ///
  /// ```dart
  /// await member.ban(deleteSince: Duration(days: 7), reason: 'Testing');
  /// ```
  Future<void> ban({Duration? deleteSince, String? reason}) =>
      _datastore.member.ban(
          serverId: serverId.value,
          memberId: id.value,
          deleteSince: deleteSince);

  /// Kick the member.
  ///
  /// ```dart
  /// await member.kick(reason: 'Testing');
  /// ```
  Future<void> kick({String? reason}) => _datastore.member
      .kick(serverId: serverId.value, memberId: id.value, reason: reason);

  /// Exclude the member.
  ///
  /// ```dart
  /// await member.exclude(duration: Duration(days: 7), reason: 'Testing');
  /// ```
  Future<void> exclude({Duration? duration, String? reason}) {
    final timeout =
        duration != null ? DateTime.now().add(duration) : DateTime.now();

    return _datastore.member.update(
        serverId: serverId.value,
        memberId: id.value,
        reason: reason,
        payload: {'communication_disabled_until': timeout.toIso8601String()});
  }

  /// Unexclude the member.
  ///
  /// ```dart
  /// await member.unExclude(reason: 'Testing');
  /// ```
  Future<void> unExclude({String? reason}) => _datastore.member.update(
      serverId: serverId.value,
      memberId: id.value,
      reason: reason,
      payload: {'communication_disabled_until': null});

  /// Enable the member's MFA. This member will be required to verify their account for accessing the server.
  ///
  /// ```dart
  /// await member.enableMfa(reason: 'Testing');
  /// ```
  Future<void> enableMfa({String? reason}) => _datastore.member.update(
      serverId: serverId.value,
      memberId: id.value,
      payload: {'mfa_enable': true},
      reason: reason);

  /// Disable the member's MFA.
  ///
  /// ```dart
  /// await member.disableMfa(reason: 'Testing');
  /// ```
  Future<void> disableMfa({String? reason}) => _datastore.member.update(
      serverId: serverId.value,
      memberId: id.value,
      payload: {'mfa_enable': false},
      reason: reason);

  /// Toggle the member's MFA.
  ///
  /// ```dart
  /// await member.toggleMfa(reason: 'Testing');
  /// ```
  Future<void> toggleMfa({String? reason}) =>
      mfaEnabled ? disableMfa(reason: reason) : enableMfa(reason: reason);

  /// Edit the member.
  ///
  /// ```dart
  /// await member.edit(MemberBuilder({
  ///   nickname: 'new-nickname',
  ///   isMuted: true,
  ///   ...
  /// }), reason: 'Testing');
  /// ```
  Future<void> edit(MemberBuilder builder, {String? reason}) =>
      _datastore.member.update(
          serverId: serverId.value,
          memberId: id.value,
          reason: reason,
          payload: {
            'nick': nickname,
            'mute': builder.isMuted,
            'deaf': builder.isDeafened,
            'exclude': builder.isExcluded,
          });

  Member({
    required EntityContext ctx,
    required this.id,
    required this.username,
    required this.nickname,
    required this.globalName,
    required this.discriminator,
    required this.assets,
    required this.flags,
    required this.premiumSince,
    required this.publicFlags,
    required this.roles,
    required this.isBot,
    required this.isPending,
    required this.timeout,
    required this.mfaEnabled,
    required this.locale,
    required this.premiumType,
    required this.joinedAt,
    required this.permissions,
    required this.accentColor,
    required this.serverId,
  }) : _ctx = ctx;

  @override
  String toString() => '<@$id>';
}
