import 'package:mineral/src/api/common/commands/application_integration_type.dart';
import 'package:mineral/src/api/common/commands/builder/command_declaration_builder.dart';
import 'package:mineral/src/api/common/commands/builder/message_command_builder.dart';
import 'package:mineral/src/api/common/commands/builder/user_command_builder.dart';
import 'package:mineral/src/api/common/commands/interaction_context_type.dart';
import 'package:test/test.dart';

void main() {
  group(
    'ApplicationIntegrationType and InteractionContextType serialization',
    () {
      group('CommandDeclarationBuilder', () {
        test('emits integration_types and contexts when set', () {
          final builder = CommandDeclarationBuilder()
            ..setName('test')
            ..setDescription('A test command')
            ..setHandle((ctx, options) {})
            ..setIntegrationTypes([
              ApplicationIntegrationType.guildInstall,
              ApplicationIntegrationType.userInstall,
            ])
            ..setInteractionContexts([
              InteractionContextType.guild,
              InteractionContextType.botDm,
              InteractionContextType.privateChannel,
            ]);

          final json = builder.toJson();

          expect(json['integration_types'], equals([0, 1]));
          expect(json['contexts'], equals([0, 1, 2]));
        });

        test('omits integration_types and contexts when not set', () {
          final builder = CommandDeclarationBuilder()
            ..setName('test')
            ..setDescription('A test command')
            ..setHandle((ctx, options) {});

          final json = builder.toJson();

          expect(json.containsKey('integration_types'), isFalse);
          expect(json.containsKey('contexts'), isFalse);
        });

        test('emits only integration_types when only that is set', () {
          final builder = CommandDeclarationBuilder()
            ..setName('test')
            ..setDescription('A test command')
            ..setHandle((ctx, options) {})
            ..setIntegrationTypes([ApplicationIntegrationType.userInstall]);

          final json = builder.toJson();

          expect(json['integration_types'], equals([1]));
          expect(json.containsKey('contexts'), isFalse);
        });

        test('setIntegrationTypes returns self for chaining', () {
          final builder = CommandDeclarationBuilder();
          final result = builder.setIntegrationTypes([
            ApplicationIntegrationType.guildInstall,
          ]);
          expect(result, same(builder));
        });

        test('setInteractionContexts returns self for chaining', () {
          final builder = CommandDeclarationBuilder();
          final result = builder.setInteractionContexts([
            InteractionContextType.guild,
          ]);
          expect(result, same(builder));
        });
      });

      group('UserCommandBuilder', () {
        test('emits integration_types and contexts when set', () {
          final builder = UserCommandBuilder()
            ..setName('Get user info')
            ..setIntegrationTypes([
              ApplicationIntegrationType.guildInstall,
              ApplicationIntegrationType.userInstall,
            ])
            ..setInteractionContexts([
              InteractionContextType.guild,
              InteractionContextType.botDm,
              InteractionContextType.privateChannel,
            ]);

          final json = builder.toJson();

          expect(json['integration_types'], equals([0, 1]));
          expect(json['contexts'], equals([0, 1, 2]));
        });

        test('omits integration_types and contexts when not set', () {
          final builder = UserCommandBuilder()..setName('Get user info');

          final json = builder.toJson();

          expect(json.containsKey('integration_types'), isFalse);
          expect(json.containsKey('contexts'), isFalse);
        });

        test('setIntegrationTypes returns self for chaining', () {
          final builder = UserCommandBuilder();
          final result = builder.setIntegrationTypes([
            ApplicationIntegrationType.guildInstall,
          ]);
          expect(result, same(builder));
        });

        test('setInteractionContexts returns self for chaining', () {
          final builder = UserCommandBuilder();
          final result = builder.setInteractionContexts([
            InteractionContextType.guild,
          ]);
          expect(result, same(builder));
        });
      });

      group('MessageCommandBuilder', () {
        test('emits integration_types and contexts when set', () {
          final builder = MessageCommandBuilder()
            ..setName('Report message')
            ..setIntegrationTypes([
              ApplicationIntegrationType.guildInstall,
              ApplicationIntegrationType.userInstall,
            ])
            ..setInteractionContexts([
              InteractionContextType.guild,
              InteractionContextType.botDm,
              InteractionContextType.privateChannel,
            ]);

          final json = builder.toJson();

          expect(json['integration_types'], equals([0, 1]));
          expect(json['contexts'], equals([0, 1, 2]));
        });

        test('omits integration_types and contexts when not set', () {
          final builder = MessageCommandBuilder()..setName('Report message');

          final json = builder.toJson();

          expect(json.containsKey('integration_types'), isFalse);
          expect(json.containsKey('contexts'), isFalse);
        });
      });

      group('enum values', () {
        test('ApplicationIntegrationType values are correct', () {
          expect(ApplicationIntegrationType.guildInstall.value, equals(0));
          expect(ApplicationIntegrationType.userInstall.value, equals(1));
        });

        test('InteractionContextType values are correct', () {
          expect(InteractionContextType.guild.value, equals(0));
          expect(InteractionContextType.botDm.value, equals(1));
          expect(InteractionContextType.privateChannel.value, equals(2));
        });
      });
    },
  );
}
