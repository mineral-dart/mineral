final class MessageEmbedProvider {
  final String? name;
  final String? url;

  const MessageEmbedProvider({required this.name, required this.url});

  factory MessageEmbedProvider.fromJson(Map<String, dynamic> json) {
    return MessageEmbedProvider(
      name: json['name'] as String?,
      url: json['url'] as String?,
    );
  }
}
