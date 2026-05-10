import 'dart:io';

import 'package:mineral/contracts.dart';
import 'package:mineral/src/api/common/image_asset.dart';
import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/api/server/managers/emoji_manager.dart';
import 'package:mineral/src/api/server/managers/sticker_manager.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class ServerAsset {
  final EntityContext _ctx;
  DataStoreContract get _datastore => _ctx.datastore;

  final Snowflake serverId;
  final ImageAsset? icon;
  final ImageAsset? splash;
  final ImageAsset? banner;
  final ImageAsset? discoverySplash;
  final EmojiManager emojis;
  final StickerManager stickers;

  ServerAsset(
    this.serverId, {
    required EntityContext ctx,
    required this.emojis,
    required this.stickers,
    required this.icon,
    required this.splash,
    required this.banner,
    required this.discoverySplash,
  }) : _ctx = ctx;

  /// Set the server's icon.
  ///
  /// ```dart
  /// await server.assets.setIcon(File('icon.png'), reason: 'Testing');
  /// ```
  Future<void> setIcon(File icon, {String? reason}) async {
    final iconAsset = ImageAsset.makeAsset(icon);
    await _datastore.server
        .update(serverId.value, {'icon': iconAsset.makeUrl()}, reason);
  }

  /// Set the server's banner.
  ///
  /// ```dart
  /// await server.assets.setBanner(File('banner.png'), reason: 'Testing');
  /// ```
  Future<void> setBanner(File banner, {String? reason}) async {
    final bannerAsset = ImageAsset.makeAsset(banner);
    await _datastore.server
        .update(serverId.value, {'banner': bannerAsset.makeUrl()}, reason);
  }

  /// Set the server's splash.
  ///
  /// ```dart
  /// await server.assets.setSplash(File('splash.png'), reason: 'Testing');
  /// ```
  Future<void> setSplash(File splash, {String? reason}) async {
    final splashAsset = ImageAsset.makeAsset(splash);
    await _datastore.server
        .update(serverId.value, {'splash': splashAsset.makeUrl()}, reason);
  }

  /// Set the server's discovery splash.
  ///
  /// ```dart
  /// await server.assets.setDiscoverySplash(File('discovery_splash.png'), reason: 'Testing');
  /// ```
  Future<void> setDiscoverySplash(File discoverySplash,
      {String? reason}) async {
    final discoverySplashAsset = ImageAsset.makeAsset(discoverySplash);
    await _datastore.server.update(serverId.value,
        {'discovery_splash': discoverySplashAsset.makeUrl()}, reason);
  }
}
