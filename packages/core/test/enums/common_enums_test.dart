import 'package:mineral/src/api/common/commands/command_option_type.dart';
import 'package:mineral/src/api/common/commands/command_type.dart';
import 'package:mineral/src/api/common/components/button.dart';
import 'package:mineral/src/api/common/components/component.dart';
import 'package:mineral/src/api/common/components/text_input.dart';
import 'package:mineral/src/api/common/message_type.dart';
import 'package:mineral/src/api/common/polls/poll_layout.dart';
import 'package:mineral/src/api/common/premium_tier.dart';
import 'package:mineral/src/api/common/video_quality.dart';
import 'package:mineral/src/domains/common/utils/utils.dart';
import 'package:test/test.dart';

void main() {
  group('ComponentType', () {
    test('unknown has value -1', () {
      expect(ComponentType.unknown.value, -1);
    });

    test('known values resolve correctly', () {
      expect(findInEnum(ComponentType.values, 1), ComponentType.actionRow);
      expect(findInEnum(ComponentType.values, 2), ComponentType.button);
      expect(findInEnum(ComponentType.values, 4), ComponentType.textInput);
      expect(findInEnum(ComponentType.values, 17), ComponentType.container);
    });

    test('unknown value with orElse returns unknown', () {
      expect(
        findInEnum(ComponentType.values, 999, orElse: ComponentType.unknown),
        ComponentType.unknown,
      );
    });

    test('unknown value without orElse throws ArgumentError', () {
      expect(() => findInEnum(ComponentType.values, 999), throwsArgumentError);
    });
  });

  group('TextInputStyle', () {
    test('unknown has value -1', () {
      expect(TextInputStyle.unknown.value, -1);
    });

    test('known values resolve correctly', () {
      expect(findInEnum(TextInputStyle.values, 1), TextInputStyle.short);
      expect(findInEnum(TextInputStyle.values, 2), TextInputStyle.paragraph);
    });

    test('unknown value with orElse returns unknown', () {
      expect(
        findInEnum(TextInputStyle.values, 99, orElse: TextInputStyle.unknown),
        TextInputStyle.unknown,
      );
    });

    test('unknown value without orElse throws ArgumentError', () {
      expect(() => findInEnum(TextInputStyle.values, 99), throwsArgumentError);
    });
  });

  group('ButtonType', () {
    test('unknown has value -1', () {
      expect(ButtonType.unknown.value, -1);
    });

    test('known values resolve correctly', () {
      expect(findInEnum(ButtonType.values, 1), ButtonType.primary);
      expect(findInEnum(ButtonType.values, 2), ButtonType.secondary);
      expect(findInEnum(ButtonType.values, 3), ButtonType.success);
      expect(findInEnum(ButtonType.values, 4), ButtonType.danger);
      expect(findInEnum(ButtonType.values, 5), ButtonType.link);
      expect(findInEnum(ButtonType.values, 6), ButtonType.premium);
    });

    test('unknown value with orElse returns unknown', () {
      expect(
        findInEnum(ButtonType.values, 99, orElse: ButtonType.unknown),
        ButtonType.unknown,
      );
    });

    test('unknown value without orElse throws ArgumentError', () {
      expect(() => findInEnum(ButtonType.values, 99), throwsArgumentError);
    });
  });

  group('CommandOptionType', () {
    test('unknown has value -1', () {
      expect(CommandOptionType.unknown.value, -1);
    });

    test('known values resolve correctly', () {
      expect(findInEnum(CommandOptionType.values, 3), CommandOptionType.string);
      expect(
        findInEnum(CommandOptionType.values, 4),
        CommandOptionType.integer,
      );
      expect(
        findInEnum(CommandOptionType.values, 5),
        CommandOptionType.boolean,
      );
      expect(findInEnum(CommandOptionType.values, 6), CommandOptionType.user);
      expect(
        findInEnum(CommandOptionType.values, 7),
        CommandOptionType.channel,
      );
      expect(
        findInEnum(CommandOptionType.values, 11),
        CommandOptionType.attachment,
      );
    });

    test('unknown value with orElse returns unknown', () {
      expect(
        findInEnum(
          CommandOptionType.values,
          99,
          orElse: CommandOptionType.unknown,
        ),
        CommandOptionType.unknown,
      );
    });

    test('unknown value without orElse throws ArgumentError', () {
      expect(
        () => findInEnum(CommandOptionType.values, 99),
        throwsArgumentError,
      );
    });
  });

  group('CommandType', () {
    test('unknown has value -1', () {
      expect(CommandType.unknown.value, -1);
    });

    test('known values resolve correctly', () {
      expect(findInEnum(CommandType.values, 1), CommandType.subCommand);
      expect(findInEnum(CommandType.values, 2), CommandType.subCommandGroup);
    });

    test('unknown value with orElse returns unknown', () {
      expect(
        findInEnum(CommandType.values, 99, orElse: CommandType.unknown),
        CommandType.unknown,
      );
    });

    test('unknown value without orElse throws ArgumentError', () {
      expect(() => findInEnum(CommandType.values, 99), throwsArgumentError);
    });
  });

  group('MessageType', () {
    test('unknown has value -1', () {
      expect(MessageType.unknown.value, -1);
    });

    test('known values resolve correctly', () {
      expect(findInEnum(MessageType.values, 0), MessageType.initial);
      expect(findInEnum(MessageType.values, 7), MessageType.userJoin);
      expect(findInEnum(MessageType.values, 19), MessageType.reply);
      expect(
        findInEnum(MessageType.values, 32),
        MessageType.guildApplicationPremiumSubscription,
      );
    });

    test('unknown value with orElse returns unknown', () {
      expect(
        findInEnum(MessageType.values, 999, orElse: MessageType.unknown),
        MessageType.unknown,
      );
    });

    test('unknown value without orElse throws ArgumentError', () {
      expect(() => findInEnum(MessageType.values, 999), throwsArgumentError);
    });
  });

  group('PollLayout', () {
    test('unknown has value -1', () {
      expect(PollLayout.unknown.value, -1);
    });

    test('known values resolve correctly', () {
      expect(findInEnum(PollLayout.values, 1), PollLayout.initial);
    });

    test('unknown value with orElse returns unknown', () {
      expect(
        findInEnum(PollLayout.values, 99, orElse: PollLayout.unknown),
        PollLayout.unknown,
      );
    });

    test('unknown value without orElse throws ArgumentError', () {
      expect(() => findInEnum(PollLayout.values, 99), throwsArgumentError);
    });
  });

  group('PremiumTier', () {
    test('unknown has value -1', () {
      expect(PremiumTier.unknown.value, -1);
    });

    test('known values resolve correctly', () {
      expect(findInEnum(PremiumTier.values, 0), PremiumTier.none);
      expect(findInEnum(PremiumTier.values, 1), PremiumTier.classic);
      expect(findInEnum(PremiumTier.values, 2), PremiumTier.game);
      expect(findInEnum(PremiumTier.values, 3), PremiumTier.basic);
    });

    test('unknown value with orElse returns unknown', () {
      expect(
        findInEnum(PremiumTier.values, 99, orElse: PremiumTier.unknown),
        PremiumTier.unknown,
      );
    });

    test('unknown value without orElse throws ArgumentError', () {
      expect(() => findInEnum(PremiumTier.values, 99), throwsArgumentError);
    });
  });

  group('VideoQuality', () {
    test('unknown has value -1', () {
      expect(VideoQuality.unknown.value, -1);
    });

    test('known values resolve correctly', () {
      expect(findInEnum(VideoQuality.values, 1), VideoQuality.auto);
      expect(findInEnum(VideoQuality.values, 2), VideoQuality.full);
    });

    test('unknown value with orElse returns unknown', () {
      expect(
        findInEnum(VideoQuality.values, 99, orElse: VideoQuality.unknown),
        VideoQuality.unknown,
      );
    });

    test('unknown value without orElse throws ArgumentError', () {
      expect(() => findInEnum(VideoQuality.values, 99), throwsArgumentError);
    });
  });
}
