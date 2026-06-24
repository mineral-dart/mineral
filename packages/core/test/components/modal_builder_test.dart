import 'package:mineral/src/api/common/components/builder/modal_builder.dart';
import 'package:mineral/src/api/common/components/component.dart';
import 'package:mineral/src/api/common/components/select_menu.dart';
import 'package:mineral/src/api/common/components/text_input.dart';
import 'package:test/test.dart';

void main() {
  group('ModalBuilder', () {
    late ModalBuilder modal;

    setUp(() {
      modal = ModalBuilder('test_modal');
    });

    group('build', () {
      test('generates valid Discord API JSON for empty modal', () {
        expect(
          modal.build(),
          equals({'custom_id': 'test_modal', 'title': null, 'components': []}),
        );
      });

      test('generates valid Discord API JSON with title', () {
        modal.setTitle('My Modal');

        expect(
          modal.build(),
          equals({
            'custom_id': 'test_modal',
            'title': 'My Modal',
            'components': [],
          }),
        );
      });
    });

    group('addTextInput', () {
      test(
        'generates valid Discord API JSON with Label wrapping TextInput',
        () {
          modal.addTextInput(
            customId: 'feedback',
            label: 'Your Feedback',
            style: TextInputStyle.paragraph,
            placeholder: 'Tell us what you think...',
            minLength: 10,
            maxLength: 500,
            isRequired: true,
            description: 'Be specific',
          );

          final result = modal.build();
          expect(result['custom_id'], equals('test_modal'));
          expect(result['components'], hasLength(1));

          final component = result['components'][0] as Map<String, dynamic>;
          expect(
            component,
            equals({
              'type': ComponentType.label.value,
              'label': 'Your Feedback',
              'description': 'Be specific',
              'component': {
                'type': ComponentType.textInput.value,
                'custom_id': 'feedback',
                'style': 2,
                'min_length': 10,
                'max_length': 500,
                'placeholder': 'Tell us what you think...',
                'required': true,
              },
            }),
          );
        },
      );

      test('generates valid Discord API JSON with multiple text inputs', () {
        modal
          ..setTitle('Registration')
          ..addTextInput(customId: 'username', label: 'Username')
          ..addTextInput(
            customId: 'bio',
            label: 'Bio',
            style: TextInputStyle.paragraph,
          );

        final result = modal.build();
        expect(result['components'], hasLength(2));

        final first = result['components'][0] as Map<String, dynamic>;
        expect(first['label'], equals('Username'));
        expect(
          first['component'],
          equals({
            'type': ComponentType.textInput.value,
            'custom_id': 'username',
            'style': 1,
          }),
        );

        final second = result['components'][1] as Map<String, dynamic>;
        expect(second['label'], equals('Bio'));
        expect(
          second['component'],
          equals({
            'type': ComponentType.textInput.value,
            'custom_id': 'bio',
            'style': 2,
          }),
        );
      });
    });

    group('addText', () {
      test('generates TextDisplay in components', () {
        modal.addText('Please fill in the form below:');

        final result = modal.build();
        expect(result['components'], hasLength(1));

        final component = result['components'][0] as Map<String, dynamic>;
        expect(
          component,
          equals({
            'type': ComponentType.textDisplay.value,
            'content': 'Please fill in the form below:',
          }),
        );
      });
    });

    group('addSelectMenu', () {
      test(
        'generates valid Discord API JSON with Label wrapping SelectMenu',
        () {
          final menu = SelectMenu.text('category', [
            SelectMenuOption(label: 'Bug', value: 'bug'),
            SelectMenuOption(label: 'Feature', value: 'feature'),
          ]);

          modal.addSelectMenu(
            label: 'Issue Category',
            menu: menu,
            description: 'Select the category',
          );

          final result = modal.build();
          expect(result['components'], hasLength(1));

          final component = result['components'][0] as Map<String, dynamic>;
          expect(
            component,
            equals({
              'type': ComponentType.label.value,
              'label': 'Issue Category',
              'description': 'Select the category',
              'component': {
                'type': ComponentType.textSelectMenu.value,
                'custom_id': 'category',
                'options': [
                  {
                    'label': 'Bug',
                    'value': 'bug',
                    'description': null,
                    'default': false,
                  },
                  {
                    'label': 'Feature',
                    'value': 'feature',
                    'description': null,
                    'default': false,
                  },
                ],
              },
            }),
          );
        },
      );
    });

    group('complex modal', () {
      test('generates valid Discord API JSON for complete form', () {
        modal
          ..setTitle('Bug Report')
          ..addText('**Please describe the bug you encountered.**')
          ..addTextInput(
            customId: 'title',
            label: 'Bug Title',
            style: TextInputStyle.short,
            placeholder: 'Brief summary',
            maxLength: 100,
            isRequired: true,
          )
          ..addTextInput(
            customId: 'description',
            label: 'Description',
            style: TextInputStyle.paragraph,
            placeholder: 'Detailed description...',
            minLength: 20,
            maxLength: 2000,
            isRequired: true,
            description: 'Please provide as much detail as possible',
          );

        final result = modal.build();
        expect(result['custom_id'], equals('test_modal'));
        expect(result['title'], equals('Bug Report'));
        expect(result['components'], hasLength(3));

        expect(
          result['components'][0],
          equals({
            'type': ComponentType.textDisplay.value,
            'content': '**Please describe the bug you encountered.**',
          }),
        );

        expect(
          result['components'][1],
          equals({
            'type': ComponentType.label.value,
            'label': 'Bug Title',
            'description': null,
            'component': {
              'type': ComponentType.textInput.value,
              'custom_id': 'title',
              'style': 1,
              'placeholder': 'Brief summary',
              'max_length': 100,
              'required': true,
            },
          }),
        );

        expect(
          result['components'][2],
          equals({
            'type': ComponentType.label.value,
            'label': 'Description',
            'description': 'Please provide as much detail as possible',
            'component': {
              'type': ComponentType.textInput.value,
              'custom_id': 'description',
              'style': 2,
              'placeholder': 'Detailed description...',
              'min_length': 20,
              'max_length': 2000,
              'required': true,
            },
          }),
        );
      });
    });
  });
}
