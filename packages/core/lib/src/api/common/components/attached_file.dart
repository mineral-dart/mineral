import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mineral/api.dart';

final class AttachedFile implements MessageComponent {
  ComponentType get type => ComponentType.file;

  MediaItem item;

  AttachedFile._(this.item);

  /// Creates an [AttachedFile] from a local file.
  ///
  /// Example:
  /// ```dart
  /// final file = File('assets/image.png');
  /// final attachedFile = AttachedFile.fromFile(file, 'image.png', spoiler: false);
  /// ```
  factory AttachedFile.fromFile(
    File file,
    String name, {
    bool? spoiler,
    String? proxyUrl,
    int? height,
    int? width,
    String? contentType,
    String? description,
  }) {
    final mediaItem = MediaItem.fromFile(
      file,
      name,
      spoiler: spoiler,
      proxyUrl: proxyUrl,
      height: height,
      width: width,
      contentType: contentType,
      description: description,
    );
    return AttachedFile._(mediaItem);
  }

  /// Creates an [AttachedFile] from a [MediaItem].
  ///
  /// If the [MediaItem] was created using [MediaItem.fromNetwork] and doesn't
  /// have bytes yet, this method will fetch the file from the network URL.
  ///
  /// Example:
  /// ```dart
  /// final mediaItem = MediaItem.fromNetwork('https://example.com/image.png');
  /// final attachedFile = await AttachedFile.fromMediaItem(mediaItem);
  /// ```
  static Future<AttachedFile> fromMediaItem(MediaItem mediaItem) async {
    // If bytes are already present (e.g., from MediaItem.fromFile), use them directly
    if (mediaItem.bytes != null) {
      return AttachedFile._(mediaItem);
    }

    // If no bytes, fetch from the network URL
    final uri = Uri.parse(mediaItem.url);
    final response = await http.get(uri);

    // Extract filename from the URL or use a default
    final name = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : 'file.txt';

    // Create a new MediaItem with the fetched bytes and attachment:// URL
    final media = MediaItem.fromNetwork(
      'attachment://$name',
      spoiler: mediaItem.spoiler,
      proxyUrl: mediaItem.proxyUrl,
      height: mediaItem.height,
      width: mediaItem.width,
      contentType: mediaItem.contentType,
      description: mediaItem.description,
    )..bytes = response.bodyBytes;

    return AttachedFile._(media);
  }

  /// Creates an [AttachedFile] by fetching a file from a network URL.
  ///
  /// This method downloads the file from the specified [url] and prepares it
  /// for attachment to a Discord message. The file is automatically converted
  /// to use Discord's `attachment://` protocol with the provided [name].
  ///
  /// Example:
  /// ```dart
  /// final attachedFile = await AttachedFile.fromNetwork(
  ///   'https://example.com/data/data.json',
  ///   'data.json',
  ///   spoiler: true,
  /// );
  ///
  /// final builder = MessageBuilder()
  ///   ..addText('Check out these datas!')
  ///   ..addFile(attachedFile);
  /// ```
  static Future<AttachedFile> fromNetwork(
    String url,
    String name, {
    bool? spoiler,
    String? proxyUrl,
    int? height,
    int? width,
    String? contentType,
    String? description,
  }) async {
    // Fetch bytes from the network URL
    final uri = Uri.parse(url);
    final response = await http.get(uri);

    // Create a MediaItem with the fetched bytes
    final media =
        MediaItem.fromNetwork(
            'attachment://$name',
            spoiler: spoiler,
            proxyUrl: proxyUrl,
            height: height,
            width: width,
            contentType: contentType,
            description: description,
          )
          ..bytes = response.bodyBytes
          ..spoiler = spoiler;

    return AttachedFile._(media);
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type.value, ...item.toJson()};
  }
}
