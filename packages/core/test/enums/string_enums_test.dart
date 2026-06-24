import 'package:mineral/src/api/common/embed/message_embed_type.dart';
import 'package:mineral/src/api/common/image_asset.dart';
import 'package:mineral/src/api/common/permission.dart';
import 'package:mineral/src/api/common/types/status_type.dart';
import 'package:mineral/src/domains/common/utils/utils.dart';
import 'package:mineral/src/domains/services/interactions/interaction_context_type.dart';
import 'package:mineral/src/domains/services/logger/log_level.dart';
import 'package:test/test.dart';

void main() {
  group('MessageEmbedType', () {
    test('unknown has value "unknown"', () {
      expect(MessageEmbedType.unknown.value, 'unknown');
    });

    test('known values resolve correctly', () {
      expect(
        findInEnum(MessageEmbedType.values, 'rich'),
        MessageEmbedType.rich,
      );
      expect(
        findInEnum(MessageEmbedType.values, 'image'),
        MessageEmbedType.image,
      );
      expect(
        findInEnum(MessageEmbedType.values, 'video'),
        MessageEmbedType.video,
      );
      expect(
        findInEnum(MessageEmbedType.values, 'gifv'),
        MessageEmbedType.gifv,
      );
      expect(
        findInEnum(MessageEmbedType.values, 'article'),
        MessageEmbedType.article,
      );
      expect(
        findInEnum(MessageEmbedType.values, 'link'),
        MessageEmbedType.link,
      );
    });

    test('unknown value with orElse returns unknown', () {
      expect(
        findInEnum(
          MessageEmbedType.values,
          'nope',
          orElse: MessageEmbedType.unknown,
        ),
        MessageEmbedType.unknown,
      );
    });

    test('unknown value without orElse throws ArgumentError', () {
      expect(
        () => findInEnum(MessageEmbedType.values, 'nope'),
        throwsArgumentError,
      );
    });
  });

  group('ImageExtension', () {
    test('unknown has value "unknown"', () {
      expect(ImageExtension.unknown.value, 'unknown');
    });

    test('known values resolve correctly', () {
      expect(findInEnum(ImageExtension.values, '.png'), ImageExtension.png);
      expect(findInEnum(ImageExtension.values, '.jpeg'), ImageExtension.jpeg);
      expect(findInEnum(ImageExtension.values, '.webp'), ImageExtension.webp);
      expect(findInEnum(ImageExtension.values, '.gif'), ImageExtension.gif);
      expect(findInEnum(ImageExtension.values, '.json'), ImageExtension.lottie);
    });

    test('unknown value with orElse returns unknown', () {
      expect(
        findInEnum(
          ImageExtension.values,
          '.bmp',
          orElse: ImageExtension.unknown,
        ),
        ImageExtension.unknown,
      );
    });

    test('unknown value without orElse throws ArgumentError', () {
      expect(
        () => findInEnum(ImageExtension.values, '.bmp'),
        throwsArgumentError,
      );
    });
  });

  group('StatusType', () {
    test('unknown has value "unknown"', () {
      expect(StatusType.unknown.value, 'unknown');
    });

    test('known values resolve correctly', () {
      expect(findInEnum(StatusType.values, 'online'), StatusType.online);
      expect(findInEnum(StatusType.values, 'idle'), StatusType.idle);
      expect(findInEnum(StatusType.values, 'dnd'), StatusType.doNotDerange);
      expect(findInEnum(StatusType.values, 'offline'), StatusType.offline);
    });

    test('unknown value with orElse returns unknown', () {
      expect(
        findInEnum(StatusType.values, 'invisible', orElse: StatusType.unknown),
        StatusType.unknown,
      );
    });

    test('unknown value without orElse throws ArgumentError', () {
      expect(
        () => findInEnum(StatusType.values, 'invisible'),
        throwsArgumentError,
      );
    });
  });

  group('LogLevel', () {
    test('unknown has value "unknown"', () {
      expect(LogLevel.unknown.value, 'unknown');
    });

    test('known values resolve correctly', () {
      expect(findInEnum(LogLevel.values, 'TRACE'), LogLevel.trace);
      expect(findInEnum(LogLevel.values, 'FATAL'), LogLevel.fatal);
      expect(findInEnum(LogLevel.values, 'ERROR'), LogLevel.error);
      expect(findInEnum(LogLevel.values, 'WARN'), LogLevel.warn);
      expect(findInEnum(LogLevel.values, 'INFO'), LogLevel.info);
    });

    test('unknown value with orElse returns unknown', () {
      expect(
        findInEnum(LogLevel.values, 'DEBUG', orElse: LogLevel.unknown),
        LogLevel.unknown,
      );
    });

    test('unknown value without orElse throws ArgumentError', () {
      expect(() => findInEnum(LogLevel.values, 'DEBUG'), throwsArgumentError);
    });
  });

  group('Permission', () {
    test('unknown has value -1', () {
      expect(Permission.unknown.value, -1);
    });

    test('known values resolve correctly', () {
      expect(
        findInEnum(Permission.values, 1 << 0),
        Permission.createInstantInvite,
      );
      expect(findInEnum(Permission.values, 1 << 3), Permission.administrator);
      expect(findInEnum(Permission.values, 1 << 11), Permission.sendMessages);
      expect(
        findInEnum(Permission.values, 1 << 40),
        Permission.moderateMembers,
      );
    });

    test('unknown value with orElse returns unknown', () {
      expect(
        findInEnum(Permission.values, -999, orElse: Permission.unknown),
        Permission.unknown,
      );
    });

    test('unknown value without orElse throws ArgumentError', () {
      expect(() => findInEnum(Permission.values, -999), throwsArgumentError);
    });
  });

  group('InteractionContextType', () {
    test('unknown has value -1', () {
      expect(InteractionContextType.unknown.value, -1);
    });

    test('known values resolve correctly', () {
      expect(
        findInEnum(InteractionContextType.values, 0),
        InteractionContextType.guild,
      );
      expect(
        findInEnum(InteractionContextType.values, 1),
        InteractionContextType.botPrivate,
      );
      expect(
        findInEnum(InteractionContextType.values, 2),
        InteractionContextType.privateChannel,
      );
    });

    test('unknown value with orElse returns unknown', () {
      expect(
        findInEnum(
          InteractionContextType.values,
          99,
          orElse: InteractionContextType.unknown,
        ),
        InteractionContextType.unknown,
      );
    });

    test('unknown value without orElse throws ArgumentError', () {
      expect(
        () => findInEnum(InteractionContextType.values, 99),
        throwsArgumentError,
      );
    });
  });
}
