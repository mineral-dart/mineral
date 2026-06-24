import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/api/guild/managers/threads_manager.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class Guild {
  final EntityContext _ctx;
  DataStoreContract get _datastore => _ctx.datastore;

  final Snowflake id;
  final String? applicationId;
  final String name;
  final String? description;
  final Snowflake ownerId;
  final MemberManager members;
  final GuildSettings settings;
  final RoleManager roles;
  final ChannelManager channels;
  final GuildThreadManager threads;
  final GuildAsset assets;

  Guild({
    required EntityContext ctx,
    required this.id,
    required this.name,
    required this.ownerId,
    required this.members,
    required this.settings,
    required this.roles,
    required this.channels,
    required this.description,
    required this.applicationId,
    required this.assets,
    required this.threads,
  }) : _ctx = ctx;

  DateTime get createdAt => id.createdAt;

  /// Access this guild's guild templates.
  TemplateManager get templates => TemplateManager(id, ctx: _ctx);

  /// Access this guild's scheduled events.
  ScheduledEventManager get scheduledEvents =>
      ScheduledEventManager(id, ctx: _ctx);

  /// Access this guild's soundboard sounds.
  SoundboardManager get soundboardSounds => SoundboardManager(id, ctx: _ctx);

  /// Set the guild's name.
  ///
  /// ```dart
  /// await guild.setName('New Guild Name', reason: 'Testing');
  /// ```
  Future<void> setName(String name, {String? reason}) async {
    await _datastore.guild.update(id.value, {'name': name}, reason);
  }

  /// Set the guild's description.
  ///
  /// ```dart
  /// await guild.setDescription('New Guild Description', reason: 'Testing');
  /// ```
  Future<void> setDescription(String description, {String? reason}) async {
    await _datastore.guild
        .update(id.value, {'description': description}, reason);
  }

  /// Set the default message notifications for the guild.
  ///
  /// ```dart
  /// await guild.setDefaultMessageNotifications(DefaultMessageNotification.allMessages, reason: 'Testing');
  /// ```
  Future<void> setDefaultMessageNotifications(DefaultMessageNotification value,
      {String? reason}) async {
    await _datastore.guild.update(
        id.value, {'default_message_notifications': value.value}, reason);
  }

  /// Set the explicit content filter for the guild.
  ///
  /// ```dart
  /// await guild.setExplicitContentFilter(ExplicitContentFilter.disabled, reason: 'Testing');
  /// ```
  Future<void> setExplicitContentFilter(ExplicitContentFilter value,
      {String? reason}) async {
    await _datastore.guild
        .update(id.value, {'explicit_content_filter': value.value}, reason);
  }

  /// Set the guild's afk timeout.
  ///
  ///  ```dart
  ///  await guild.setAfkTimeout(300, reason: 'Testing');
  ///  ```
  Future<void> setAfkTimeout(int value, {String? reason}) async {
    await _datastore.guild.update(id.value, {'afk_timeout': value}, reason);
  }

  /// Set the guild's enabled premium features.
  ///
  /// ```dart
  /// await guild.enablePremiumProgressBar(true, reason: 'Testing');
  /// ```
  Future<void> enablePremiumProgressBar(bool value, {String? reason}) async {
    await _datastore.guild
        .update(id.value, {'premium_progress_bar_enabled': value}, reason);
  }

  /// Set the guild's safety alerts channel.
  ///
  /// ```dart
  /// await guild.setSafetyAlertsChannel('1091121140090535956', reason: 'Testing');
  /// ```
  Future<void> setSafetyAlertsChannel(String? channelId,
      {String? reason}) async {
    await _datastore.guild
        .update(id.value, {'safety_alerts_channel_id': channelId}, reason);
  }

  /// Set the guild's preferred locale.
  ///
  /// ```dart
  /// await guild.setPreferredLocale('en-US', reason: 'Testing');
  /// ```
  Future<void> setPreferredLocale(String value, {String? reason}) async {
    await _datastore.guild
        .update(id.value, {'preferred_locale': value}, reason);
  }

  /// Set the guild's vanity url code.
  ///
  /// ```dart
  /// await guild.setVanityUrlCode('new-vanity-url', reason: 'Testing');
  /// ```
  Future<void> setVanityUrlCode(String value, {String? reason}) async {
    await _datastore.guild
        .update(id.value, {'vanity_url_code': value}, reason);
  }

  /// Resolve the guild owner's name.
  /// ```dart
  /// final owner = await guild.resolveOwner();
  /// ```
  Future<Member> resolveOwner({bool force = false}) async {
    final member = await _datastore.member.get(id.value, ownerId.value, force);
    return member!;
  }

  /// Fetch the guild welcome screen.
  ///
  /// ```dart
  /// final screen = await guild.fetchWelcomeScreen();
  /// ```
  Future<WelcomeScreen> fetchWelcomeScreen() =>
      _datastore.welcomeScreen.fetch(id.value);

  /// Update the guild welcome screen.
  ///
  /// Only the provided parameters are sent in the request body.
  ///
  /// ```dart
  /// await guild.updateWelcomeScreen(
  ///   description: 'Welcome!',
  ///   enabled: true,
  ///   reason: 'Setting up welcome screen',
  /// );
  /// ```
  Future<WelcomeScreen> updateWelcomeScreen({
    bool? enabled,
    List<WelcomeChannel>? welcomeChannels,
    String? description,
    String? reason,
  }) {
    final channelsJson =
        welcomeChannels?.map((c) => c.toJson()).toList();
    return _datastore.welcomeScreen.update(
      id.value,
      enabled: enabled,
      welcomeChannels: channelsJson,
      description: description,
      reason: reason,
    );
  }

  /// Fetch the guild onboarding configuration.
  ///
  /// ```dart
  /// final onboarding = await guild.fetchOnboarding();
  /// ```
  Future<Onboarding> fetchOnboarding() =>
      _datastore.onboarding.fetch(id.value);

  /// Update the guild onboarding configuration.
  ///
  /// Only the provided parameters are sent in the request body.
  ///
  /// ```dart
  /// await guild.updateOnboarding(
  ///   enabled: true,
  ///   mode: OnboardingMode.default_,
  ///   reason: 'Enabling onboarding',
  /// );
  /// ```
  Future<Onboarding> updateOnboarding({
    List<OnboardingPrompt>? prompts,
    List<Snowflake>? defaultChannelIds,
    bool? enabled,
    OnboardingMode? mode,
    String? reason,
  }) {
    return _datastore.onboarding.update(
      id.value,
      prompts: prompts,
      defaultChannelIds: defaultChannelIds?.cast<Object>(),
      enabled: enabled,
      mode: mode,
      reason: reason,
    );
  }
}
