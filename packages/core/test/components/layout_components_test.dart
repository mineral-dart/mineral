import 'package:mineral/src/api/common/color.dart';
import 'package:mineral/src/api/common/components/builder/message_builder.dart';
import 'package:mineral/src/api/common/components/button.dart';
import 'package:mineral/src/api/common/components/component.dart';
import 'package:mineral/src/api/common/components/container.dart';
import 'package:mineral/src/api/common/components/media_gallery.dart';
import 'package:mineral/src/api/common/components/media_item.dart';
import 'package:mineral/src/api/common/components/message_thumbnail.dart';
import 'package:mineral/src/api/common/components/section.dart';
import 'package:mineral/src/api/common/components/separator.dart';
import 'package:mineral/src/api/common/components/text_display.dart';
import 'package:test/test.dart';

void main() {
  group('Separator', () {
    test('generates valid Discord API JSON with defaults', () {
      final separator = Separator(true, SeparatorSize.small);

      expect(
        separator.toJson(),
        equals({
          'type': ComponentType.separator.value,
          'divider': true,
          'spacing': 1,
        }),
      );
    });

    test('generates valid Discord API JSON with large spacing', () {
      final separator = Separator(false, SeparatorSize.large);

      expect(
        separator.toJson(),
        equals({
          'type': ComponentType.separator.value,
          'divider': false,
          'spacing': 2,
        }),
      );
    });
  });

  group('TextDisplay', () {
    test('generates valid Discord API JSON', () {
      final text = TextDisplay('Hello **world**');

      expect(
        text.toJson(),
        equals({
          'type': ComponentType.textDisplay.value,
          'content': 'Hello **world**',
        }),
      );
    });

    test('preserves markdown formatting', () {
      final text = TextDisplay('# Title\n- item 1\n- item 2');

      expect(
        text.toJson(),
        equals({
          'type': ComponentType.textDisplay.value,
          'content': '# Title\n- item 1\n- item 2',
        }),
      );
    });
  });

  group('Section', () {
    test('generates valid Discord API JSON with button accessory', () {
      final builder = MessageBuilder()..addText('Important notice');
      final section = Section(
        builder: builder,
        button: Button.primary('learn_more', label: 'Learn More'),
      );

      expect(
        section.toJson(),
        equals({
          'type': ComponentType.section.value,
          'accessory': {
            'type': ComponentType.button.value,
            'style': 1,
            'custom_id': 'learn_more',
            'label': 'Learn More',
          },
          'components': [
            {
              'type': ComponentType.textDisplay.value,
              'content': 'Important notice',
            },
          ],
        }),
      );
    });

    test('generates valid Discord API JSON with thumbnail accessory', () {
      final builder = MessageBuilder()..addText('User profile');
      final thumbnail = Thumbnail(
        MediaItem.fromNetwork('https://example.com/avatar.png'),
      );
      final section = Section(builder: builder, thumbnail: thumbnail);

      expect(
        section.toJson(),
        equals({
          'type': ComponentType.section.value,
          'accessory': {
            'type': ComponentType.thumbnail.value,
            'media': {'url': 'https://example.com/avatar.png'},
          },
          'components': [
            {
              'type': ComponentType.textDisplay.value,
              'content': 'User profile',
            },
          ],
        }),
      );
    });

    test('generates valid Discord API JSON without accessory', () {
      final builder = MessageBuilder()..addText('Simple section');
      final section = Section(builder: builder);

      expect(
        section.toJson(),
        equals({
          'type': ComponentType.section.value,
          'components': [
            {
              'type': ComponentType.textDisplay.value,
              'content': 'Simple section',
            },
          ],
        }),
      );
    });
  });

  group('Container', () {
    test('generates valid Discord API JSON with color and spoiler', () {
      final builder = MessageBuilder()..addText('Secret content');
      final container = Container(Color('#ff0000'), true, builder);

      expect(
        container.toJson(),
        equals({
          'type': ComponentType.container.value,
          'accent_color': 0xff0000,
          'spoiler': true,
          'components': [
            {
              'type': ComponentType.textDisplay.value,
              'content': 'Secret content',
            },
          ],
        }),
      );
    });

    test('generates valid Discord API JSON without color', () {
      final container = Container(null, null, null);

      expect(
        container.toJson(),
        equals({
          'type': ComponentType.container.value,
          'accent_color': null,
          'spoiler': false,
          'components': [],
        }),
      );
    });

    test('throws FormatException when nested container detected', () {
      final innerBuilder = MessageBuilder()
        ..addContainer(builder: MessageBuilder()..addText('deep'));

      expect(
        () => Container(null, null, innerBuilder).toJson(),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('MediaGallery', () {
    test('generates valid Discord API JSON', () {
      final gallery = MediaGallery(
        items: [
          MediaItem.fromNetwork('https://example.com/img1.png'),
          MediaItem.fromNetwork('https://example.com/img2.png'),
        ],
      );

      expect(
        gallery.toJson(),
        equals({
          'type': ComponentType.mediaGallery.value,
          'items': [
            {
              'url': 'https://example.com/img1.png',
              'media': {'url': 'https://example.com/img1.png'},
            },
            {
              'url': 'https://example.com/img2.png',
              'media': {'url': 'https://example.com/img2.png'},
            },
          ],
        }),
      );
    });

    test('generates valid Discord API JSON with description and spoiler', () {
      final gallery = MediaGallery(
        items: [
          MediaItem.fromNetwork(
            'https://example.com/img.png',
            description: 'A landscape',
            spoiler: true,
          ),
        ],
      );

      expect(
        gallery.toJson(),
        equals({
          'type': ComponentType.mediaGallery.value,
          'items': [
            {
              'description': 'A landscape',
              'url': 'https://example.com/img.png',
              'spoiler': true,
              'media': {'url': 'https://example.com/img.png'},
            },
          ],
        }),
      );
    });
  });

  group('Thumbnail', () {
    test('generates valid Discord API JSON', () {
      final thumbnail = Thumbnail(
        MediaItem.fromNetwork('https://example.com/thumb.png'),
      );

      expect(
        thumbnail.toJson(),
        equals({
          'type': ComponentType.thumbnail.value,
          'media': {'url': 'https://example.com/thumb.png'},
        }),
      );
    });

    test('generates valid Discord API JSON with description', () {
      final thumbnail = Thumbnail(
        MediaItem.fromNetwork(
          'https://example.com/thumb.png',
          description: 'Profile picture',
        ),
      );

      expect(
        thumbnail.toJson(),
        equals({
          'type': ComponentType.thumbnail.value,
          'media': {'url': 'https://example.com/thumb.png'},
          'description': 'Profile picture',
        }),
      );
    });

    test('generates valid Discord API JSON with spoiler', () {
      final thumbnail = Thumbnail(
        MediaItem.fromNetwork('https://example.com/thumb.png', spoiler: true),
      );

      expect(
        thumbnail.toJson(),
        equals({
          'type': ComponentType.thumbnail.value,
          'media': {'url': 'https://example.com/thumb.png'},
          'spoiler': true,
        }),
      );
    });
  });
}
