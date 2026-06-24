import 'package:mineral/src/api/common/commands/builder/command_group_builder.dart';
import 'package:mineral/src/api/common/commands/builder/translation.dart';
import 'package:mineral/src/api/common/commands/command_type.dart';
import 'package:mineral/src/api/common/lang.dart';
import 'package:mineral/src/infrastructure/io/exceptions/missing_property_exception.dart';
import 'package:test/test.dart';

void main() {
  group('CommandGroupBuilder', () {
    late CommandGroupBuilder builder;

    setUp(() {
      builder = CommandGroupBuilder();
    });

    group('setName', () {
      test('stores the name', () {
        builder.setName('admin');
        expect(builder.name, 'admin');
      });

      test('returns self for chaining', () {
        final result = builder.setName('admin');
        expect(result, same(builder));
      });

      test('stores name localizations with translation', () {
        final translation = Translation({
          'name': {Lang.fr: 'administrateur'},
        });

        builder.setName('admin', translation: translation);
        expect(builder.name, 'admin');
      });
    });

    group('setDescription', () {
      test('returns self for chaining', () {
        final result = builder.setDescription('Admin commands');
        expect(result, same(builder));
      });
    });

    group('addSubCommand', () {
      test('creates and adds a sub command', () {
        builder.addSubCommand((sub) {
          sub
            ..setName('ban')
            ..setDescription('Ban a user')
            ..setHandle((ctx, options) {});
        });

        expect(builder.commands, hasLength(1));
        expect(builder.commands.first.name, 'ban');
      });

      test('adds multiple sub commands', () {
        builder
          ..addSubCommand((sub) {
            sub
              ..setName('ban')
              ..setDescription('Ban')
              ..setHandle((ctx, options) {});
          })
          ..addSubCommand((sub) {
            sub
              ..setName('kick')
              ..setDescription('Kick')
              ..setHandle((ctx, options) {});
          });

        expect(builder.commands, hasLength(2));
        expect(builder.commands[0].name, 'ban');
        expect(builder.commands[1].name, 'kick');
      });

      test('returns self for chaining', () {
        final result = builder.addSubCommand((sub) {
          sub
            ..setName('test')
            ..setDescription('test')
            ..setHandle((ctx, options) {});
        });
        expect(result, same(builder));
      });
    });

    group('toJson', () {
      test('generates correct JSON', () {
        builder
          ..setName('admin')
          ..setDescription('Admin commands')
          ..addSubCommand((sub) {
            sub
              ..setName('ban')
              ..setDescription('Ban user')
              ..setHandle((ctx, options) {});
          });

        final json = builder.toJson();

        expect(json['name'], 'admin');
        expect(json['description'], 'Admin commands');
        expect(json['type'], CommandType.subCommandGroup.value);
        expect(json['options'], hasLength(1));
      });

      test('includes name localizations', () {
        final translation = Translation({
          'name': {Lang.fr: 'administrateur'},
        });

        builder
          ..setName('admin', translation: translation)
          ..setDescription('Admin')
          ..addSubCommand((sub) {
            sub
              ..setName('test')
              ..setDescription('test')
              ..setHandle((ctx, options) {});
          });

        final json = builder.toJson();

        expect(json['name_localizations'], isNotNull);
        expect(json['name_localizations']['fr'], 'administrateur');
      });

      test('includes description localizations', () {
        final translation = Translation({
          'description': {Lang.fr: 'Commandes admin'},
        });

        builder
          ..setName('admin')
          ..setDescription('Admin commands', translation: translation)
          ..addSubCommand((sub) {
            sub
              ..setName('test')
              ..setDescription('test')
              ..setHandle((ctx, options) {});
          });

        final json = builder.toJson();

        expect(json['description_localizations'], isNotNull);
        expect(json['description_localizations']['fr'], 'Commandes admin');
      });

      test('throws MissingPropertyException when name is null', () {
        builder.setDescription('test');
        expect(
          () => builder.toJson(),
          throwsA(isA<MissingPropertyException>()),
        );
      });

      test('throws MissingPropertyException when description is null', () {
        builder.setName('test');
        expect(
          () => builder.toJson(),
          throwsA(isA<MissingPropertyException>()),
        );
      });

      test('serializes sub commands in options', () {
        builder
          ..setName('admin')
          ..setDescription('Admin')
          ..addSubCommand((sub) {
            sub
              ..setName('ban')
              ..setDescription('Ban user')
              ..setHandle((ctx, options) {});
          })
          ..addSubCommand((sub) {
            sub
              ..setName('kick')
              ..setDescription('Kick user')
              ..setHandle((ctx, options) {});
          });

        final json = builder.toJson();

        expect(json['options'], hasLength(2));
        expect(json['options'][0]['name'], 'ban');
        expect(json['options'][0]['type'], CommandType.subCommand.value);
        expect(json['options'][1]['name'], 'kick');
      });
    });

    group('fromJson', () {
      test('reconstructs builder from JSON', () {
        final json = {
          'name': 'admin',
          'description': 'Admin commands',
          'commands': [
            {'name': 'ban', 'description': 'Ban a user'},
            {'name': 'kick', 'description': 'Kick a user'},
          ],
        };

        final group = CommandGroupBuilder.fromJson(json);

        expect(group.name, 'admin');
        expect(group.commands, hasLength(2));
        expect(group.commands[0].name, 'ban');
        expect(group.commands[1].name, 'kick');
      });
    });
  });
}
