import 'package:mineral/src/domains/common/utils/utils.dart';

final class MessageEmbedField {
  final String name;
  final String value;
  final bool inline;

  MessageEmbedField({
    required this.name,
    required this.value,
    this.inline = false,
  }) {
    expectOrThrow(
      name.length <= 256,
      message: 'Name must be 256 or fewer in length',
    );
    expectOrThrow(
      value.length <= 1024,
      message: 'Value must be 1024 or fewer in length',
    );
  }

  Object toJson() {
    return {'name': name, 'value': value, 'inline': inline};
  }

  factory MessageEmbedField.fromJson(Map<String, dynamic> json) {
    return MessageEmbedField(
      name: json['name'] as String,
      value: json['value'] as String,
      inline: json['inline'] as bool,
    );
  }
}
