import 'package:mineral/src/api/common/components/button.dart';
import 'package:mineral/src/api/common/components/component.dart';
import 'package:mineral/src/api/common/partial_emoji.dart';
import 'package:test/test.dart';

void main() {
  group('Button', () {
    group('Button.primary', () {
      test('generates valid Discord API JSON', () {
        final button = Button.primary('accept_rules', label: 'Accept Rules');

        expect(
          button.toJson(),
          equals({
            'type': ComponentType.button.value,
            'style': 1,
            'custom_id': 'accept_rules',
            'label': 'Accept Rules',
          }),
        );
      });

      test('generates valid Discord API JSON without label', () {
        final button = Button.primary('click_me');

        expect(
          button.toJson(),
          equals({
            'type': ComponentType.button.value,
            'style': 1,
            'custom_id': 'click_me',
          }),
        );
      });

      test('generates valid Discord API JSON with emoji', () {
        final button = Button.primary(
          'confirm',
          label: 'Confirm',
          emoji: PartialEmoji.fromUnicode('✅'),
        );

        expect(
          button.toJson(),
          equals({
            'type': ComponentType.button.value,
            'style': 1,
            'custom_id': 'confirm',
            'label': 'Confirm',
            'emoji': {'name': '✅', 'id': null, 'animated': false},
          }),
        );
      });

      test('generates valid Discord API JSON with disabled', () {
        final button = Button.primary(
          'disabled_btn',
          label: 'Disabled',
          disabled: true,
        );

        expect(
          button.toJson(),
          equals({
            'type': ComponentType.button.value,
            'style': 1,
            'custom_id': 'disabled_btn',
            'label': 'Disabled',
            'disabled': true,
          }),
        );
      });

      test('omits disabled when false', () {
        final json = Button.primary('btn', disabled: false).toJson();

        expect(json.containsKey('disabled'), isFalse);
      });
    });

    group('Button.secondary', () {
      test('generates valid Discord API JSON', () {
        final button = Button.secondary('learn_more', label: 'Learn More');

        expect(
          button.toJson(),
          equals({
            'type': ComponentType.button.value,
            'style': 2,
            'custom_id': 'learn_more',
            'label': 'Learn More',
          }),
        );
      });
    });

    group('Button.success', () {
      test('generates valid Discord API JSON', () {
        final button = Button.success('approve', label: 'Approve');

        expect(
          button.toJson(),
          equals({
            'type': ComponentType.button.value,
            'style': 3,
            'custom_id': 'approve',
            'label': 'Approve',
          }),
        );
      });
    });

    group('Button.danger', () {
      test('generates valid Discord API JSON', () {
        final button = Button.danger('delete', label: 'Delete');

        expect(
          button.toJson(),
          equals({
            'type': ComponentType.button.value,
            'style': 4,
            'custom_id': 'delete',
            'label': 'Delete',
          }),
        );
      });
    });

    group('Button.link', () {
      test('generates valid Discord API JSON', () {
        final button = Button.link('https://example.com', label: 'Visit');

        expect(
          button.toJson(),
          equals({
            'type': ComponentType.button.value,
            'style': 5,
            'url': 'https://example.com',
            'label': 'Visit',
          }),
        );
      });

      test('omits custom_id', () {
        final json = Button.link('https://example.com').toJson();

        expect(json.containsKey('custom_id'), isFalse);
      });

      test('generates valid Discord API JSON with disabled', () {
        final button = Button.link(
          'https://example.com',
          label: 'Disabled Link',
          disabled: true,
        );

        expect(
          button.toJson(),
          equals({
            'type': ComponentType.button.value,
            'style': 5,
            'url': 'https://example.com',
            'label': 'Disabled Link',
            'disabled': true,
          }),
        );
      });
    });

    group('Button.premium', () {
      test('generates valid Discord API JSON', () {
        final button = Button.premium('sku_12345', label: 'Subscribe');

        expect(
          button.toJson(),
          equals({
            'type': ComponentType.button.value,
            'style': 6,
            'sku_id': 'sku_12345',
            'label': 'Subscribe',
          }),
        );
      });

      test('omits custom_id', () {
        final json = Button.premium('sku_12345').toJson();

        expect(json.containsKey('custom_id'), isFalse);
      });
    });
  });
}
