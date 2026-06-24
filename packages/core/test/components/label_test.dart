import 'package:mineral/src/api/common/components/component.dart';
import 'package:mineral/src/api/common/components/label.dart';
import 'package:mineral/src/api/common/components/select_menu.dart';
import 'package:mineral/src/api/common/components/text_input.dart';
import 'package:test/test.dart';

void main() {
  group('Label', () {
    test('generates valid Discord API JSON with TextInput', () {
      final input = TextInput('name_input', style: TextInputStyle.short);
      final label = Label(label: 'Your Name', component: input);

      expect(
        label.toJson(),
        equals({
          'type': ComponentType.label.value,
          'label': 'Your Name',
          'description': null,
          'component': {
            'type': ComponentType.textInput.value,
            'custom_id': 'name_input',
            'style': 1,
          },
        }),
      );
    });

    test('generates valid Discord API JSON with description', () {
      final input = TextInput('email', style: TextInputStyle.short);
      final label = Label(
        label: 'Email',
        component: input,
        description: 'We will not share your email',
      );

      expect(
        label.toJson(),
        equals({
          'type': ComponentType.label.value,
          'label': 'Email',
          'description': 'We will not share your email',
          'component': {
            'type': ComponentType.textInput.value,
            'custom_id': 'email',
            'style': 1,
          },
        }),
      );
    });

    test('generates valid Discord API JSON with SelectMenu', () {
      final menu = SelectMenu.text('role_select', [
        SelectMenuOption(label: 'Admin', value: 'admin'),
      ]);
      final label = Label(label: 'Select Role', component: menu);

      expect(
        label.toJson(),
        equals({
          'type': ComponentType.label.value,
          'label': 'Select Role',
          'description': null,
          'component': {
            'type': ComponentType.textSelectMenu.value,
            'custom_id': 'role_select',
            'options': [
              {
                'label': 'Admin',
                'value': 'admin',
                'description': null,
                'default': false,
              },
            ],
          },
        }),
      );
    });
  });
}
