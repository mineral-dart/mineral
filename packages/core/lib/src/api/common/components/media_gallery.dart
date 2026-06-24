import 'package:mineral/api.dart';

final class MediaGallery implements MessageComponent {
  ComponentType get type => ComponentType.mediaGallery;
  final List<MediaItem> _items;

  MediaGallery({required List<MediaItem> items})
    : assert(
        items.isNotEmpty && items.length <= 10,
        'MediaGallery must contain between 1 and 10 items.',
      ),
      _items = items;

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'items': _items.map((e) => e.toJson()).toList(),
    };
  }
}
