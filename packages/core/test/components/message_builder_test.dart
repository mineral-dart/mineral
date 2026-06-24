import 'package:mineral/src/api/common/color.dart';
import 'package:mineral/src/api/common/components/builder/message_builder.dart';
import 'package:mineral/src/api/common/components/button.dart';
import 'package:mineral/src/api/common/components/component.dart';
import 'package:mineral/src/api/common/components/select_menu.dart';
import 'package:mineral/src/api/common/components/separator.dart';
import 'package:test/test.dart';

void main() {
  group('MessageBuilder', () {
    late MessageBuilder builder;

    setUp(() {
      builder = MessageBuilder();
    });

    group('MessageBuilder.text', () {
      test('generates valid Discord API JSON', () {
        final result = MessageBuilder.text('Hello, world!').build();

        expect(
          result,
          equals([
            {
              'type': ComponentType.textDisplay.value,
              'content': 'Hello, world!',
            },
          ]),
        );
      });
    });

    group('addText', () {
      test('generates valid Discord API JSON', () {
        builder
          ..addText('First line')
          ..addText('Second line');

        expect(
          builder.build(),
          equals([
            {'type': ComponentType.textDisplay.value, 'content': 'First line'},
            {'type': ComponentType.textDisplay.value, 'content': 'Second line'},
          ]),
        );
      });
    });

    group('addButton', () {
      test('generates valid Discord API JSON wrapped in ActionRow', () {
        builder.addButton(Button.primary('click_me', label: 'Click Me'));

        expect(
          builder.build(),
          equals([
            {
              'type': ComponentType.actionRow.value,
              'components': [
                {
                  'type': ComponentType.button.value,
                  'style': 1,
                  'custom_id': 'click_me',
                  'label': 'Click Me',
                },
              ],
            },
          ]),
        );
      });
    });

    group('addButtons', () {
      test(
        'generates valid Discord API JSON with multiple buttons in one ActionRow',
        () {
          builder.addButtons([
            Button.primary('yes', label: 'Yes'),
            Button.danger('no', label: 'No'),
          ]);

          expect(
            builder.build(),
            equals([
              {
                'type': ComponentType.actionRow.value,
                'components': [
                  {
                    'type': ComponentType.button.value,
                    'style': 1,
                    'custom_id': 'yes',
                    'label': 'Yes',
                  },
                  {
                    'type': ComponentType.button.value,
                    'style': 4,
                    'custom_id': 'no',
                    'label': 'No',
                  },
                ],
              },
            ]),
          );
        },
      );

      test('throws ArgumentError when more than 5 buttons', () {
        expect(
          () => builder.addButtons([
            Button.primary('1', label: '1'),
            Button.primary('2', label: '2'),
            Button.primary('3', label: '3'),
            Button.primary('4', label: '4'),
            Button.primary('5', label: '5'),
            Button.primary('6', label: '6'),
          ]),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('addSelectMenu', () {
      test('generates valid Discord API JSON wrapped in ActionRow', () {
        builder.addSelectMenu(
          SelectMenu.text('color', [
            SelectMenuOption(label: 'Red', value: 'red'),
          ]),
        );

        expect(
          builder.build(),
          equals([
            {
              'type': ComponentType.actionRow.value,
              'components': [
                {
                  'type': ComponentType.textSelectMenu.value,
                  'custom_id': 'color',
                  'options': [
                    {
                      'label': 'Red',
                      'value': 'red',
                      'description': null,
                      'default': false,
                    },
                  ],
                },
              ],
            },
          ]),
        );
      });
    });

    group('addSeparator', () {
      test('generates valid Discord API JSON with defaults', () {
        builder.addSeparator();

        expect(
          builder.build(),
          equals([
            {
              'type': ComponentType.separator.value,
              'divider': true,
              'spacing': 1,
            },
          ]),
        );
      });

      test('generates valid Discord API JSON with custom values', () {
        builder.addSeparator(show: false, spacing: SeparatorSize.large);

        expect(
          builder.build(),
          equals([
            {
              'type': ComponentType.separator.value,
              'divider': false,
              'spacing': 2,
            },
          ]),
        );
      });
    });

    group('addContainer', () {
      test('generates valid Discord API JSON', () {
        final nested = MessageBuilder()..addText('Inside container');
        builder.addContainer(
          builder: nested,
          color: Color('#0000ff'),
          spoiler: true,
        );

        expect(
          builder.build(),
          equals([
            {
              'type': ComponentType.container.value,
              'accent_color': 0x0000ff,
              'spoiler': true,
              'components': [
                {
                  'type': ComponentType.textDisplay.value,
                  'content': 'Inside container',
                },
              ],
            },
          ]),
        );
      });
    });

    group('addSection', () {
      test('generates valid Discord API JSON with button accessory', () {
        final sectionBuilder = MessageBuilder()..addText('Section text');
        builder.addSection(
          builder: sectionBuilder,
          button: Button.link('https://example.com', label: 'Visit'),
        );

        expect(
          builder.build(),
          equals([
            {
              'type': ComponentType.section.value,
              'accessory': {
                'type': ComponentType.button.value,
                'style': 5,
                'url': 'https://example.com',
                'label': 'Visit',
              },
              'components': [
                {
                  'type': ComponentType.textDisplay.value,
                  'content': 'Section text',
                },
              ],
            },
          ]),
        );
      });

      test(
        'throws FormatException when section contains non-text components',
        () {
          final sectionBuilder = MessageBuilder()
            ..addButton(Button.primary('btn', label: 'Btn'));

          expect(
            () => builder.addSection(builder: sectionBuilder),
            throwsA(isA<FormatException>()),
          );
        },
      );
    });

    group('build', () {
      test('returns empty list when nothing added', () {
        expect(builder.build(), equals([]));
      });

      test('generates valid Discord API JSON for complex message', () {
        builder
          ..addText('# Welcome!')
          ..addSeparator()
          ..addText('Choose an action:')
          ..addButtons([
            Button.primary('accept', label: 'Accept'),
            Button.danger('decline', label: 'Decline'),
          ]);

        expect(
          builder.build(),
          equals([
            {'type': ComponentType.textDisplay.value, 'content': '# Welcome!'},
            {
              'type': ComponentType.separator.value,
              'divider': true,
              'spacing': 1,
            },
            {
              'type': ComponentType.textDisplay.value,
              'content': 'Choose an action:',
            },
            {
              'type': ComponentType.actionRow.value,
              'components': [
                {
                  'type': ComponentType.button.value,
                  'style': 1,
                  'custom_id': 'accept',
                  'label': 'Accept',
                },
                {
                  'type': ComponentType.button.value,
                  'style': 4,
                  'custom_id': 'decline',
                  'label': 'Decline',
                },
              ],
            },
          ]),
        );
      });
    });

    group('copy', () {
      test('creates independent copy', () {
        builder.addText('Original');
        final copy = builder.copy()..addText('Added to copy');

        expect(builder.build(), hasLength(1));
        expect(copy.build(), hasLength(2));
      });
    });

    group('copyWith', () {
      test('combines two builders', () {
        builder.addText('First');
        final other = MessageBuilder()..addText('Second');
        final combined = builder.copyWith(other);

        expect(
          combined.build(),
          equals([
            {'type': ComponentType.textDisplay.value, 'content': 'First'},
            {'type': ComponentType.textDisplay.value, 'content': 'Second'},
          ]),
        );
      });

      test('does not modify originals', () {
        builder.addText('A');
        final other = MessageBuilder()..addText('B');
        builder.copyWith(other);

        expect(builder.build(), hasLength(1));
        expect(other.build(), hasLength(1));
      });
    });

    group('appendFrom', () {
      test('appends components from other builder', () {
        builder.addText('First');
        final other = MessageBuilder()..addText('Second');
        builder.appendFrom(other);

        expect(
          builder.build(),
          equals([
            {'type': ComponentType.textDisplay.value, 'content': 'First'},
            {'type': ComponentType.textDisplay.value, 'content': 'Second'},
          ]),
        );
      });
    });

    group('prependFrom', () {
      test('prepends components from other builder', () {
        builder.addText('Second');
        final header = MessageBuilder()..addText('First');
        builder.prependFrom(header);

        expect(
          builder.build(),
          equals([
            {'type': ComponentType.textDisplay.value, 'content': 'First'},
            {'type': ComponentType.textDisplay.value, 'content': 'Second'},
          ]),
        );
      });
    });
  });
}
