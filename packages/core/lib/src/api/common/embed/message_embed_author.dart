import 'package:mineral/src/domains/common/utils/utils.dart';

final class MessageEmbedAuthor {
  final String name;
  final String? url;
  final String? iconUrl;
  final String? proxyIconUrl;

  MessageEmbedAuthor({
    required this.name,
    required this.url,
    required this.iconUrl,
    required this.proxyIconUrl,
  }) {
    expectOrThrow(
      name.length <= 256,
      message: 'Author name must be 256 or fewer in length',
    );
  }

  Object toJson() {
    return {
      'name': name,
      'url': url,
      'icon_url': iconUrl,
      'proxy_icon_url': proxyIconUrl,
    };
  }

  factory MessageEmbedAuthor.fromJson(Map<String, dynamic> json) {
    return MessageEmbedAuthor(
      name: json['name'] as String,
      url: json['url'] as String?,
      iconUrl: json['icon_url'] as String?,
      proxyIconUrl: json['proxy_icon_url'] as String?,
    );
  }
}
