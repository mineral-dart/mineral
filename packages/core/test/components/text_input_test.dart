import 'package:mineral/src/api/common/components/component.dart';
import 'package:mineral/src/api/common/components/text_input.dart';
import 'package:test/test.dart';

void main() {
  group('TextInput', () {
    test('generates valid Discord API JSON with minimal fields', () {
      final input = TextInput('username', style: TextInputStyle.short);

      expect(
        input.toJson(),
        equals({
          'type': ComponentType.textInput.value,
          'custom_id': 'username',
          'style': 1,
        }),
      );
    });

    test('omits optional fields when not set', () {
      final json = TextInput('id', style: TextInputStyle.short).toJson();

      expect(json.containsKey('min_length'), isFalse);
      expect(json.containsKey('max_length'), isFalse);
      expect(json.containsKey('placeholder'), isFalse);
      expect(json.containsKey('value'), isFalse);
      expect(json.containsKey('required'), isFalse);
    });

    test('generates valid Discord API JSON with all fields', () {
      final input = TextInput(
        'feedback',
        style: TextInputStyle.paragraph,
        minLength: 10,
        maxLength: 500,
        placeholder: 'Tell us what you think...',
        value: 'Pre-filled text',
        isRequired: true,
      );

      expect(
        input.toJson(),
        equals({
          'type': ComponentType.textInput.value,
          'custom_id': 'feedback',
          'style': 2,
          'min_length': 10,
          'max_length': 500,
          'placeholder': 'Tell us what you think...',
          'value': 'Pre-filled text',
          'required': true,
        }),
      );
    });

    test('generates valid Discord API JSON with short style', () {
      final input = TextInput('name', style: TextInputStyle.short);

      expect(input.toJson()['style'], equals(1));
    });

    test('generates valid Discord API JSON with paragraph style', () {
      final input = TextInput('bio', style: TextInputStyle.paragraph);

      expect(input.toJson()['style'], equals(2));
    });

    test('generates valid Discord API JSON with required false', () {
      final input = TextInput(
        'optional',
        style: TextInputStyle.short,
        isRequired: false,
      );

      expect(input.toJson()['required'], equals(false));
    });
  });
}
