import 'package:mineral/api.dart';
import 'package:mineral/src/domains/common/utils/helper.dart';

final class MessageEmbedAssets {
  final MessageEmbedImage? image;
  final MessageEmbedImage? thumbnail;
  final MessageEmbedImage? video;
  final MessageEmbedFooter? footer;
  final MessageEmbedAuthor? author;

  const MessageEmbedAssets({
    required this.image,
    required this.thumbnail,
    required this.video,
    required this.footer,
    required this.author,
  });

  Map<String, dynamic> toJson() {
    return {
      'image': image?.toJson(),
      'thumbnail': thumbnail?.toJson(),
      'video': video?.toJson(),
      'footer': footer?.toJson(),
      'author': author?.toJson(),
    };
  }

  factory MessageEmbedAssets.fromJson(Map<String, dynamic> json) {
    return MessageEmbedAssets(
      image: Helper.createOrNull(
        field: json['image'],
        fn: () =>
            MessageEmbedImage.fromJson(json['image'] as Map<String, dynamic>),
      ),
      thumbnail: Helper.createOrNull(
        field: json['thumbnail'],
        fn: () => MessageEmbedImage.fromJson(
          json['thumbnail'] as Map<String, dynamic>,
        ),
      ),
      video: Helper.createOrNull(
        field: json['video'],
        fn: () =>
            MessageEmbedImage.fromJson(json['video'] as Map<String, dynamic>),
      ),
      footer: Helper.createOrNull(
        field: json['footer'],
        fn: () =>
            MessageEmbedFooter.fromJson(json['footer'] as Map<String, dynamic>),
      ),
      author: Helper.createOrNull(
        field: json['author'],
        fn: () =>
            MessageEmbedAuthor.fromJson(json['author'] as Map<String, dynamic>),
      ),
    );
  }
}
