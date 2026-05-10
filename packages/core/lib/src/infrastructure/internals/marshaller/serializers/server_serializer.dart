import 'dart:async';

import 'package:mineral/api.dart';
import 'package:mineral/src/api/server/managers/rules_manager.dart';
import 'package:mineral/src/api/server/managers/threads_manager.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/common/utils/helper.dart';
import 'package:mineral/src/domains/common/utils/utils.dart';
import 'package:mineral/src/domains/services/marshaller/marshaller.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/types/serializer.dart';

final class ServerSerializer implements SerializerContract<Server> {
  final MarshallerContract _marshaller;
  final EntityContext _ctx;

  ServerSerializer(this._marshaller, this._ctx);

  @override
  Future<Map<String, dynamic>> normalize(Map<String, dynamic> json) async {
    final Map<String, dynamic> serverPayload = {
      'id': json['id'],
      'name': json['name'],
      'description': json['description'],
      'application_id': json['application_id'],
      'owner_id': json['owner_id'],
      'assets': {
        'icon': json['icon'],
        'icon_hash': json['icon_hash'],
        'splash': json['splash'],
        'discovery_splash': json['discovery_splash'],
        'banner': json['banner'],
      },
      'settings': {
        'permissions': json['permissions'],
        'afk_timeout': json['afk_timeout'],
        'widget_enabled': json['widget_enabled'] ?? false,
        'explicit_content_filter': json['explicit_content_filter'],
        'verification_level': json['verification_level'],
        'default_message_notifications': json['default_message_notifications'],
        'features': List.from(json['features'] as Iterable<dynamic>),
        'mfa_level': json['mfa_level'],
        'system_channel_flags': json['system_channel_flags'],
        'vanity_url_code': json['vanity_url_code'],
        'premium_tier': json['premium_tier'],
        'premium_subscription_count': json['premium_subscription_count'],
        'premium_progress_bar_enabled': json['premium_progress_bar_enabled'],
        'preferred_locale': json['preferred_locale'],
        'max_video_channel_users': json['max_video_channel_users'],
        'nsfw_level': json['nsfw_level'],
        'subscription': {
          'tier': json['premium_tier'],
          'subscription_count': json['premium_subscription_count'],
          'has_enabled_progress_bar': json['premium_progress_bar_enabled'],
        }
      },
      'channel_settings': {
        'afk_channel_id': json['afk_channel_id'],
        'system_channel_id': json['system_channel_id'],
        'rules_channel_id': json['rules_channel_id'],
        'public_updates_channel_id': json['public_updates_channel_id'],
        'safety_alerts_channel_id': json['safety_alerts_channel_id'],
      },
    };

    final serverCacheKey = _marshaller.cacheKey.server(json['id'] as String);
    await _marshaller.cache?.put(serverCacheKey, serverPayload);

    return serverPayload;
  }

  @override
  Future<Server> serialize(Map<String, dynamic> payload) async {
    final channelManager = ChannelManager.fromMap(
        payload['id'] as String,
        payload['channel_settings'] as Map<String, dynamic>,
        ctx: _ctx);
    final threadManager =
        ThreadsManager(Snowflake.parse(payload['id']), null, ctx: _ctx);
    final roleManager = RoleManager(Snowflake.parse(payload['id']), ctx: _ctx);
    final memberManager =
        MemberManager(Snowflake.parse(payload['id']), ctx: _ctx);

    final serverAssets = ServerAsset(
      Snowflake.parse(payload['id']),
      ctx: _ctx,
      emojis: EmojiManager(Snowflake.parse(payload['id']), ctx: _ctx),
      stickers: StickerManager(Snowflake.parse(payload['id']), ctx: _ctx),
      icon: Helper.createOrNull(
          field: payload['icon'],
          fn: () =>
              ImageAsset(['icons', payload['server_id'] as String], payload['icon'] as String)),
      splash: Helper.createOrNull(
          field: payload['splash'],
          fn: () => ImageAsset(
              ['splashes', payload['server_id'] as String], payload['splash'] as String)),
      banner: Helper.createOrNull(
          field: payload['banner'],
          fn: () =>
              ImageAsset(['banners', payload['server_id'] as String], payload['banner'] as String)),
      discoverySplash: Helper.createOrNull(
          field: payload['discovery_splash'],
          fn: () => ImageAsset(['discovery-splashes', payload['id'] as String],
              payload['discovery_splash'] as String)),
    );

    final settings = payload['settings'] as Map<String, dynamic>;
    final serverSettings = ServerSettings(
        bitfieldPermission: payload['permissions'] as String?,
        afkTimeout: payload['afk_timeout'] as int?,
        hasWidgetEnabled: payload['widget_enabled'] as bool? ?? false,
        explicitContentFilter: findInEnum(
            ExplicitContentFilter.values, settings['explicit_content_filter'],
            orElse: ExplicitContentFilter.unknown),
        verificationLevel: findInEnum(
            VerificationLevel.values, settings['verification_level'],
            orElse: VerificationLevel.unknown),
        defaultMessageNotifications: findInEnum(
            DefaultMessageNotification.values,
            settings['default_message_notifications'],
            orElse: DefaultMessageNotification.unknown),
        features: List.unmodifiable(List<String>.from(settings['features'] as Iterable<dynamic>)),
        mfaLevel: findInEnum(MfaLevel.values, settings['mfa_level'],
            orElse: MfaLevel.unknown),
        systemChannelFlags: List.unmodifiable(bitfieldToList(SystemChannelFlag.values,
            settings['system_channel_flags'] as int)),
        vanityUrlCode: payload['vanity_url_code'] as String?,
        subscription: ServerSubscription(
          tier: findInEnum(
              PremiumTier.values, settings['premium_tier'],
              orElse: PremiumTier.unknown),
          subscriptionCount: settings['premium_subscription_count'] as int?,
          hasEnabledProgressBar: settings['premium_progress_bar_enabled'] as bool,
        ),
        preferredLocale: settings['preferred_locale'] as String,
        maxVideoChannelUsers: payload['max_video_channel_users'] as int?,
        nsfwLevel: findInEnum(NsfwLevel.values, settings['nsfw_level'],
            orElse: NsfwLevel.unknown),
        rulesManager:
            RulesManager(Snowflake.parse(payload['id'] as String), ctx: _ctx));

    return Server(
      ctx: _ctx,
      id: Snowflake.parse(payload['id'] as String),
      name: payload['name'] as String,
      description: payload['description'] as String?,
      applicationId: payload['application_id'] as String?,
      members: memberManager,
      settings: serverSettings,
      roles: roleManager,
      channels: channelManager,
      assets: serverAssets,
      threads: threadManager,
      ownerId: Snowflake.parse(payload['owner_id'] as String),
    );
  }

  @override
  Future<Map<String, dynamic>> deserialize(Server server) async {
    return {
      'id': server.id,
      'name': server.name,
      'description': server.description,
      'application_id': server.applicationId,
      'owner_id': server.ownerId,
      'assets': {
        'icon': server.assets.icon?.hash,
        'splash': server.assets.splash?.hash,
        'banner': server.assets.banner?.hash,
        'discovery_splash': server.assets.discoverySplash?.hash,
        'server_id': server.assets.serverId.value,
      },
      'settings': {
        'permissions': server.settings.bitfieldPermission,
        'afk_timeout': server.settings.afkTimeout,
        'widget_enabled': server.settings.hasWidgetEnabled,
        'explicit_content_filter': server.settings.explicitContentFilter.value,
        'verification_level': server.settings.verificationLevel.value,
        'default_message_notifications':
            server.settings.defaultMessageNotifications.value,
        'features': server.settings.features,
        'mfa_level': server.settings.mfaLevel.value,
        'system_channel_flags':
            listToBitfield(server.settings.systemChannelFlags),
        'vanity_url_code': server.settings.vanityUrlCode,
        'premium_tier': server.settings.subscription.tier.value,
        'premium_subscription_count':
            server.settings.subscription.subscriptionCount,
        'premium_progress_bar_enabled':
            server.settings.subscription.hasEnabledProgressBar,
        'preferred_locale': server.settings.preferredLocale,
        'max_video_channel_users': server.settings.maxVideoChannelUsers,
        'nsfw_level': server.settings.nsfwLevel.value,
        'subscription': {
          'premium_tier': server.settings.subscription.tier.value,
          'premium_subscription_count':
              server.settings.subscription.subscriptionCount,
          'premium_progress_bar_enabled':
              server.settings.subscription.hasEnabledProgressBar,
        }
      },
      'channel_settings': {
        'afk_channel_id': server.channels.afkChannelId?.value,
        'system_channel_id': server.channels.systemChannelId?.value,
        'rules_channel_id': server.channels.rulesChannelId?.value,
        'public_updates_channel_id':
            server.channels.publicUpdatesChannelId?.value,
        'safety_alerts_channel_id':
            server.channels.safetyAlertsChannelId?.value,
      },
    };
  }
}
