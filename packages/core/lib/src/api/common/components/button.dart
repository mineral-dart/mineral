import 'package:mineral/api.dart';

enum ButtonType implements EnhancedEnum<int> {
  primary(1),
  secondary(2),
  success(3),
  danger(4),
  link(5),
  premium(6),
  unknown(-1);

  @override
  final int value;

  const ButtonType(this.value);
}

final class Button implements MessageComponent {
  final ButtonType _type;
  final String? _customId;
  final String? _label;
  final String? _url;
  final String? _skuId;
  final PartialEmoji? _emoji;
  final bool _disabled;

  Button({
    required ButtonType type,
    String? customId,
    String? label,
    String? url,
    String? skuId,
    PartialEmoji? emoji,
    bool? disabled,
  }) : _type = type,
       _customId = customId,
       _label = label,
       _url = url,
       _skuId = skuId,
       _emoji = emoji,
       _disabled = disabled ?? false;

  factory Button.primary(
    String customId, {
    String? label,
    PartialEmoji? emoji,
    bool? disabled,
  }) => Button(
    type: ButtonType.primary,
    customId: customId,
    label: label,
    emoji: emoji,
    disabled: disabled,
  );

  factory Button.secondary(
    String customId, {
    String? label,
    PartialEmoji? emoji,
    bool? disabled,
  }) => Button(
    type: ButtonType.secondary,
    customId: customId,
    label: label,
    emoji: emoji,
    disabled: disabled,
  );

  factory Button.success(
    String customId, {
    String? label,
    PartialEmoji? emoji,
    bool? disabled,
  }) => Button(
    type: ButtonType.success,
    customId: customId,
    label: label,
    emoji: emoji,
    disabled: disabled,
  );

  factory Button.danger(
    String customId, {
    String? label,
    PartialEmoji? emoji,
    bool? disabled,
  }) => Button(
    type: ButtonType.danger,
    customId: customId,
    label: label,
    emoji: emoji,
    disabled: disabled,
  );

  factory Button.link(
    String url, {
    String? label,
    PartialEmoji? emoji,
    bool? disabled,
  }) => Button(
    type: ButtonType.link,
    url: url,
    label: label,
    emoji: emoji,
    disabled: disabled,
  );

  factory Button.premium(
    String skuId, {
    String? label,
    PartialEmoji? emoji,
    bool? disabled,
  }) => Button(
    type: ButtonType.premium,
    skuId: skuId,
    label: label,
    emoji: emoji,
    disabled: disabled,
  );

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': ComponentType.button.value,
      'style': _type.value,
      if (_customId != null) 'custom_id': _customId,
      if (_skuId != null) 'sku_id': _skuId,
      if (_url != null) 'url': _url,
      if (_label != null) 'label': _label,
      if (_disabled) 'disabled': _disabled,
      if (_emoji != null)
        'emoji': {
          'name': _emoji.name,
          'id': _emoji.id,
          'animated': _emoji.animated,
        },
    };
  }
}
