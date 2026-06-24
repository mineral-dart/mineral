import 'package:mineral/src/api/common/components/action_row.dart';
import 'package:mineral/src/api/common/components/button.dart';
import 'package:mineral/src/api/common/components/component.dart';
import 'package:mineral/src/api/common/components/select_menu.dart';
import 'package:test/test.dart';

void main() {
  group('ActionRow', () {
    test('generates valid Discord API JSON with empty components', () {
      final row = ActionRow();

      expect(
        row.toJson(),
        equals({'type': ComponentType.actionRow.value, 'components': []}),
      );
    });

    test('generates valid Discord API JSON with buttons', () {
      final row = ActionRow(
        components: [
          Button.primary('btn_1', label: 'First'),
          Button.secondary('btn_2', label: 'Second'),
        ],
      );

      expect(
        row.toJson(),
        equals({
          'type': ComponentType.actionRow.value,
          'components': [
            {
              'type': ComponentType.button.value,
              'style': 1,
              'custom_id': 'btn_1',
              'label': 'First',
            },
            {
              'type': ComponentType.button.value,
              'style': 2,
              'custom_id': 'btn_2',
              'label': 'Second',
            },
          ],
        }),
      );
    });

    test('generates valid Discord API JSON with select menu', () {
      final row = ActionRow(
        components: [
          SelectMenu.text('color_select', [
            SelectMenuOption(label: 'Red', value: 'red'),
          ]),
        ],
      );

      expect(
        row.toJson(),
        equals({
          'type': ComponentType.actionRow.value,
          'components': [
            {
              'type': ComponentType.textSelectMenu.value,
              'custom_id': 'color_select',
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
        }),
      );
    });

    test('preserves component insertion order', () {
      final row = ActionRow(
        components: [
          Button.danger('third', label: '3'),
          Button.primary('first', label: '1'),
          Button.success('second', label: '2'),
        ],
      );

      final components =
          row.toJson()['components'] as List<Map<String, dynamic>>;
      expect(components[0]['custom_id'], equals('third'));
      expect(components[1]['custom_id'], equals('first'));
      expect(components[2]['custom_id'], equals('second'));
    });
  });
}
