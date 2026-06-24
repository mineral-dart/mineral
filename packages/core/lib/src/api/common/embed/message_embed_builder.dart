import 'package:mineral/api.dart';

final class MessageEmbedBuilder {
  String? title;
  String? description;
  String? url;
  DateTime? timestamp;
  Color? color;
  MessageEmbedFooter? footer;
  MessageEmbedAuthor? author;
  MessageEmbedImage? image;
  MessageEmbedImage? thumbnail;
  List<MessageEmbedField> fields = [];

  MessageEmbedBuilder();

  MessageEmbedBuilder setTitle(String title) {
    this.title = title;
    return this;
  }

  MessageEmbedBuilder setDescription(String description) {
    this.description = description;
    return this;
  }

  MessageEmbedBuilder setUrl(String url) {
    this.url = url;
    return this;
  }

  MessageEmbedBuilder setColor(Color color) {
    this.color = color;
    return this;
  }

  MessageEmbedBuilder setFooter({
    required String text,
    String? iconUrl,
    String? proxyIconUrl,
  }) {
    footer = MessageEmbedFooter(
      text: text,
      iconUrl: iconUrl,
      proxyIconUrl: proxyIconUrl,
    );
    return this;
  }

  MessageEmbedBuilder setAuthor({
    required String name,
    String? url,
    String? iconUrl,
    String? proxyIconUrl,
  }) {
    author = MessageEmbedAuthor(
      name: name,
      url: url,
      iconUrl: iconUrl,
      proxyIconUrl: proxyIconUrl,
    );
    return this;
  }

  MessageEmbedBuilder addField({
    required String name,
    required String value,
    bool inline = false,
  }) {
    fields.add(MessageEmbedField(name: name, value: value, inline: inline));
    return this;
  }

  MessageEmbedBuilder setTimestamp({DateTime? timestamp}) {
    this.timestamp = timestamp ?? DateTime.now();
    return this;
  }

  MessageEmbedBuilder setImage({
    required String url,
    String? proxyUrl,
    int? height,
    int? width,
  }) {
    image = MessageEmbedImage(
      url: url,
      proxyUrl: proxyUrl,
      height: height,
      width: width,
    );
    return this;
  }

  MessageEmbedBuilder setThumbnail({
    required String url,
    String? proxyUrl,
    int? height,
    int? width,
  }) {
    thumbnail = MessageEmbedImage(
      url: url,
      proxyUrl: proxyUrl,
      height: height,
      width: width,
    );
    return this;
  }

  MessageEmbedBuilder setVideo({
    required String url,
    String? proxyUrl,
    int? height,
    int? width,
  }) {
    image = MessageEmbedImage(
      url: url,
      proxyUrl: proxyUrl,
      height: height,
      width: width,
    );
    return this;
  }

  MessageEmbed build() {
    return MessageEmbed(
      title: title,
      description: description,
      url: url,
      timestamp: timestamp,
      color: color ?? Color('#000000'),
      assets: MessageEmbedAssets(
        image: image,
        thumbnail: thumbnail,
        video: image,
        footer: footer,
        author: author,
      ),
      fields: fields,
    );
  }
}
