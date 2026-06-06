import 'package:mineral/src/api/common/commands/builder/sub_command_builder.dart';
import 'package:mineral/src/api/common/commands/builder/translation.dart';
import 'package:mineral/src/api/common/commands/command_option.dart';
import 'package:mineral/src/api/common/commands/command_option_type.dart';
import 'package:mineral/src/api/common/commands/command_type.dart';
import 'package:mineral/src/api/common/lang.dart';
import 'package:mineral/src/infrastructure/io/exceptions/missing_property_exception.dart';
import 'package:test/test.dart';

void main() {
  group('SubCommandBuilder', () {
    late SubCommandBuilder builder;

    setUp(() {
      builder = SubCommandBuilder();
    });

    group('setName', () {
      test('stores the name', () {
        builder.setName('ban');
        expect(builder.name, 'ban');
      });

      test('returns self for chaining', () {
        final result = builder.setName('ban');
        expect(result, same(builder));
      });

      test('stores name localizations with translation', () {
        final translation = Translation({
          'name': {
            Lang.fr: 'bannir',
            Lang.de: 'verbannen',
          },
        });

        builder.setName('ban', translation: translation);
        expect(builder.name, 'ban');
      });
    });

    group('setDescription', () {
      test('returns self for chaining', () {
        final result = builder.setDescription('Ban a user');
        expect(result, same(builder));
      });
    });

    group('addOption', () {
      test('adds option to the list', () {
        builder.addOption(Option.string(name: 'reason', description: 'Reason'));
        expect(builder.options, hasLength(1));
        expect(builder.options.first.name, 'reason');
      });

      test('adds multiple options', () {
        builder
          ..addOption(Option.user(name: 'target', description: 'Target'))
          ..addOption(Option.string(name: 'reason', description: 'Reason'));
        expect(builder.options, hasLength(2));
      });

      test('returns self for chaining', () {
        final result =
            builder.addOption(Option.string(name: 'test', description: 'test'));
        expect(result, same(builder));
      });
    });

    group('setHandle', () {
      test('stores the handler function', () {
        void handler(ctx, options) {}
        builder.setHandle(handler);
        expect(builder.handle, handler);
      });

      test('returns self for chaining', () {
        final result = builder.setHandle((ctx, options) {});
        expect(result, same(builder));
      });
    });

    group('toJson', () {
      test('generates correct JSON', () {
        builder
          ..setName('ban')
          ..setDescription('Ban a user')
          ..setHandle((ctx, options) {});

        final json = builder.toJson();

        expect(json['name'], 'ban');
        expect(json['description'], 'Ban a user');
        expect(json['type'], CommandType.subCommand.value);
        expect(json['options'], isEmpty);
      });

      test('includes options in JSON', () {
        builder
          ..setName('ban')
          ..setDescription('Ban a user')
          ..addOption(Option.user(
              name: 'target', description: 'User to ban', required: true))
          ..setHandle((ctx, options) {});

        final json = builder.toJson();

        expect(json['options'], hasLength(1));
        expect(json['options'][0]['name'], 'target');
        expect(json['options'][0]['type'], CommandOptionType.user.value);
        expect(json['options'][0]['required'], true);
      });

      test('includes name localizations', () {
        final translation = Translation({
          'name': {
            Lang.fr: 'bannir',
          },
        });

        builder
          ..setName('ban', translation: translation)
          ..setDescription('Ban a user')
          ..setHandle((ctx, options) {});

        final json = builder.toJson();

        expect(json['name_localizations'], isNotNull);
        expect(json['name_localizations']['fr'], 'bannir');
      });

      test('includes description localizations', () {
        final translation = Translation({
          'description': {
            Lang.fr: 'Bannir un utilisateur',
          },
        });

        builder
          ..setName('ban')
          ..setDescription('Ban a user', translation: translation)
          ..setHandle((ctx, options) {});

        final json = builder.toJson();

        expect(json['description_localizations'], isNotNull);
        expect(
            json['description_localizations']['fr'], 'Bannir un utilisateur');
      });

      test('throws MissingPropertyException when name is null', () {
        builder.setDescription('test');
        expect(
            () => builder.toJson(), throwsA(isA<MissingPropertyException>()));
      });

      test('throws MissingPropertyException when description is null', () {
        builder.setName('test');
        expect(
            () => builder.toJson(), throwsA(isA<MissingPropertyException>()));
      });
    });
  });
}
