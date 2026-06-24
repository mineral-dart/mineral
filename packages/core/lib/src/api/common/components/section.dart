import 'package:mineral/api.dart';

final class Section implements MessageComponent {
  ComponentType get type => ComponentType.section;

  final MessageBuilder builder;
  final Button? _button;
  final Thumbnail? _thumbnail;

  Section({required this.builder, Button? button, Thumbnail? thumbnail})
    : assert(
        button == null || thumbnail == null,
        'Accessory must be either a button or a thumbnail, not both.',
      ),
      _button = button,
      _thumbnail = thumbnail;

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      if (_button != null || _thumbnail != null)
        'accessory': _button?.toJson() ?? _thumbnail?.toJson(),
      'components': builder.build(),
    };
  }
}
