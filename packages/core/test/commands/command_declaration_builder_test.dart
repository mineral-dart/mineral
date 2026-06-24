import 'dart:async';

import 'package:mineral/src/api/common/commands/builder/command_declaration_builder.dart';
import 'package:mineral/src/api/common/commands/builder/translation.dart';
import 'package:mineral/src/api/common/commands/command_context_type.dart';
import 'package:mineral/src/api/common/commands/command_option.dart';
import 'package:mineral/src/api/common/commands/command_option_type.dart';
import 'package:mineral/src/api/common/commands/command_type.dart';
import 'package:mineral/src/api/common/lang.dart';
import 'package:mineral/src/domains/commands/command_context.dart';
import 'package:mineral/src/domains/commands/command_options.dart';
import 'package:mineral/src/infrastructure/io/exceptions/command_name_exception.dart';
import 'package:mineral/src/infrastructure/io/exceptions/missing_method_exception.dart';
import 'package:mineral/src/infrastructure/io/exceptions/missing_property_exception.dart';
import 'package:test/test.dart';

void main() {
  group('CommandDeclarationBuilder', () {
    late CommandDeclarationBuilder builder;

    setUp(() {
      builder = CommandDeclarationBuilder();
    });

    group('setName', () {
      test('stores name in lowercase', () {
        builder.setName('Ping');
        expect(builder.name, 'ping');
      });

      test('returns self for chaining', () {
        final result = builder.setName('ping');
        expect(result, same(builder));
      });

      test('throws on invalid name', () {
        expect(() => builder.setName('invalid name'),
            throwsA(isA<CommandNameException>()));
      });

      test('stores name localizations with translation', () {
        final translation = Translation({
          'name': {
            Lang.fr: 'ping',
            Lang.de: 'ping',
          },
        });

        builder.setName('ping', translation: translation);
        expect(builder.name, 'ping');
      });
    });

    group('setDescription', () {
      test('returns self for chaining', () {
        final result = builder.setDescription('A test command');
        expect(result, same(builder));
      });
    });

    group('setContext', () {
      test('defaults to guild context', () {
        expect(builder.context, CommandContextType.guild);
      });

      test('changes to global context', () {
        builder.setContext(CommandContextType.global);
        expect(builder.context, CommandContextType.global);
      });

      test('returns self for chaining', () {
        final result = builder.setContext(CommandContextType.global);
        expect(result, same(builder));
      });
    });

    group('addOption', () {
      test('adds option to list', () {
        builder.addOption(
            Option.string(name: 'target', description: 'The target'));
        expect(builder.options.length, 1);
        expect(builder.options.first.name, 'target');
      });

      test('adds multiple options', () {
        builder
          ..addOption(Option.string(name: 'name', description: 'Name'))
          ..addOption(Option.integer(name: 'count', description: 'Count'));
        expect(builder.options.length, 2);
      });

      test('returns self for chaining', () {
        final result = builder.addOption(
            Option.string(name: 'target', description: 'The target'));
        expect(result, same(builder));
      });
    });

    group('setHandle', () {
      test('returns self for chaining', () {
        final result = builder.setHandle((ctx, options) {});
        expect(result, same(builder));
      });
    });

    group('addSubCommand', () {
      test('creates and adds a sub command', () {
        builder.addSubCommand((sub) {
          sub
            ..setName('user')
            ..setDescription('Ban a user')
            ..setHandle((ctx, options) {});
        });

        expect(builder.subCommands.length, 1);
        expect(builder.subCommands.first.name, 'user');
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

    group('createGroup', () {
      test('creates and adds a group', () {
        builder.createGroup((group) {
          group
            ..setName('admin')
            ..setDescription('Admin commands')
            ..addSubCommand((sub) {
              sub
                ..setName('ban')
                ..setDescription('Ban a user')
                ..setHandle((ctx, options) {});
            });
        });

        expect(builder.groups.length, 1);
        expect(builder.groups.first.name, 'admin');
        expect(builder.groups.first.commands.length, 1);
      });

      test('returns self for chaining', () {
        final result = builder.createGroup((group) {
          group
            ..setName('test')
            ..setDescription('test');
        });
        expect(result, same(builder));
      });
    });

    group('toJson', () {
      test('generates correct JSON for simple command', () {
        builder
          ..setName('ping')
          ..setDescription('Pong!')
          ..setHandle((ctx, options) {});

        final json = builder.toJson();

        expect(json['name'], 'ping');
        expect(json['description'], 'Pong!');
        expect(json['type'], CommandType.subCommand.value);
        expect(json['options'], isEmpty);
      });

      test('generates JSON with options', () {
        builder
          ..setName('ban')
          ..setDescription('Ban a user')
          ..addOption(Option.user(
              name: 'target', description: 'User to ban', required: true))
          ..addOption(Option.string(name: 'reason', description: 'Reason'))
          ..setHandle((ctx, options) {});

        final json = builder.toJson();

        expect(json['options'], hasLength(2));
        expect(json['options'][0]['name'], 'target');
        expect(json['options'][0]['type'], CommandOptionType.user.value);
        expect(json['options'][0]['required'], true);
        expect(json['options'][1]['name'], 'reason');
        expect(json['options'][1]['required'], false);
      });

      test('generates JSON with subcommands', () {
        builder
          ..setName('mod')
          ..setDescription('Mod commands')
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
        expect(json.containsKey('type'), isFalse);
      });

      test('generates JSON with groups', () {
        builder
          ..setName('admin')
          ..setDescription('Admin commands')
          ..createGroup((group) {
            group
              ..setName('user')
              ..setDescription('User management')
              ..addSubCommand((sub) {
                sub
                  ..setName('ban')
                  ..setDescription('Ban user')
                  ..setHandle((ctx, options) {});
              });
          });

        final json = builder.toJson();

        expect(json['options'], hasLength(1));
        expect(json['options'][0]['type'], CommandType.subCommandGroup.value);
        expect(json.containsKey('type'), isFalse);
      });

      test('includes name localizations when set', () {
        final translation = Translation({
          'name': {
            Lang.fr: 'ping',
          },
        });

        builder
          ..setName('ping', translation: translation)
          ..setDescription('Pong!')
          ..setHandle((ctx, options) {});

        final json = builder.toJson();

        expect(json['name_localizations'], isNotNull);
        expect(json['name_localizations']['fr'], 'ping');
      });

      test('includes description localizations when set', () {
        final translation = Translation({
          'description': {
            Lang.fr: 'Pong !',
          },
        });

        builder
          ..setName('ping')
          ..setDescription('Pong!', translation: translation)
          ..setHandle((ctx, options) {});

        final json = builder.toJson();

        expect(json['description_localizations'], isNotNull);
        expect(json['description_localizations']['fr'], 'Pong !');
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

    group('reduceHandlers', () {
      test('returns single handler for simple command', () {
        FutureOr<void> handler(CommandContext ctx, CommandOptions options) {}
        builder
          ..setName('ping')
          ..setDescription('Pong!')
          ..setHandle(handler);

        final registrations = builder.reduceHandlers('ping');

        expect(registrations, hasLength(1));
        expect(registrations.first.name, 'ping');
        expect(registrations.first.handler, handler);
      });

      test('returns handlers for subcommands with dotted names', () {
        FutureOr<void> banHandler(CommandContext ctx, CommandOptions options) {}
        FutureOr<void> kickHandler(CommandContext ctx, CommandOptions options) {}

        builder
          ..setName('mod')
          ..setDescription('Mod commands')
          ..addSubCommand((sub) {
            sub
              ..setName('ban')
              ..setDescription('Ban')
              ..setHandle(banHandler);
          })
          ..addSubCommand((sub) {
            sub
              ..setName('kick')
              ..setDescription('Kick')
              ..setHandle(kickHandler);
          });

        final registrations = builder.reduceHandlers('mod');

        expect(registrations, hasLength(2));
        expect(registrations[0].name, 'mod.ban');
        expect(registrations[0].handler, banHandler);
        expect(registrations[1].name, 'mod.kick');
        expect(registrations[1].handler, kickHandler);
      });

      test('returns handlers for groups with triple-dotted names', () {
        FutureOr<void> handler(CommandContext ctx, CommandOptions options) {}

        builder
          ..setName('admin')
          ..setDescription('Admin')
          ..createGroup((group) {
            group
              ..setName('user')
              ..setDescription('User management')
              ..addSubCommand((sub) {
                sub
                  ..setName('ban')
                  ..setDescription('Ban')
                  ..setHandle(handler);
              });
          });

        final registrations = builder.reduceHandlers('admin');

        expect(registrations, hasLength(1));
        expect(registrations.first.name, 'admin.user.ban');
        expect(registrations.first.handler, handler);
      });

      test('includes declared options in registration', () {
        builder
          ..setName('ban')
          ..setDescription('Ban user')
          ..addOption(
              Option.user(name: 'target', description: 'User', required: true))
          ..addOption(Option.string(name: 'reason', description: 'Reason'))
          ..setHandle((ctx, options) {});

        final registrations = builder.reduceHandlers('ban');

        expect(registrations.first.declaredOptions, hasLength(2));
        expect(registrations.first.declaredOptions[0].name, 'target');
        expect(registrations.first.declaredOptions[0].isRequired, isTrue);
        expect(registrations.first.declaredOptions[1].name, 'reason');
        expect(registrations.first.declaredOptions[1].isRequired, isFalse);
      });

      test('throws MissingMethodException when subcommand has no handler', () {
        builder
          ..setName('mod')
          ..setDescription('Mod')
          ..addSubCommand((sub) {
            sub
              ..setName('ban')
              ..setDescription('Ban');
          });

        expect(() => builder.reduceHandlers('mod'),
            throwsA(isA<MissingMethodException>()));
      });
    });
  });
}
