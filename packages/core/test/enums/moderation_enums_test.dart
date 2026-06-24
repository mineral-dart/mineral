import 'package:mineral/src/api/guild/moderation/enums/action_type.dart';
import 'package:mineral/src/api/guild/moderation/enums/auto_moderation_event_type.dart';
import 'package:mineral/src/api/guild/moderation/enums/keyword_preset_type.dart';
import 'package:mineral/src/api/guild/moderation/enums/trigger_type.dart';
import 'package:mineral/src/domains/common/utils/utils.dart';
import 'package:test/test.dart';

void main() {
  group('KeywordPresetType', () {
    test('unknown has value -1', () {
      expect(KeywordPresetType.unknown.value, -1);
    });

    test('known values resolve correctly', () {
      expect(
          findInEnum(KeywordPresetType.values, 1), KeywordPresetType.profanity);
      expect(findInEnum(KeywordPresetType.values, 2),
          KeywordPresetType.sexualContent);
      expect(findInEnum(KeywordPresetType.values, 3), KeywordPresetType.slurs);
    });

    test('unknown value with orElse returns unknown', () {
      expect(
        findInEnum(KeywordPresetType.values, 99,
            orElse: KeywordPresetType.unknown),
        KeywordPresetType.unknown,
      );
    });

    test('unknown value without orElse throws ArgumentError', () {
      expect(
        () => findInEnum(KeywordPresetType.values, 99),
        throwsArgumentError,
      );
    });
  });

  group('TriggerType', () {
    test('unknown has value -1', () {
      expect(TriggerType.unknown.value, -1);
    });

    test('known values resolve correctly', () {
      expect(findInEnum(TriggerType.values, 1), TriggerType.keyword);
      expect(findInEnum(TriggerType.values, 3), TriggerType.spam);
      expect(findInEnum(TriggerType.values, 4), TriggerType.keywordPreset);
      expect(findInEnum(TriggerType.values, 5), TriggerType.mentionSpam);
      expect(findInEnum(TriggerType.values, 6), TriggerType.memberProfile);
    });

    test('unknown value with orElse returns unknown', () {
      expect(
        findInEnum(TriggerType.values, 99, orElse: TriggerType.unknown),
        TriggerType.unknown,
      );
    });

    test('unknown value without orElse throws ArgumentError', () {
      expect(
        () => findInEnum(TriggerType.values, 99),
        throwsArgumentError,
      );
    });
  });

  group('ActionType', () {
    test('unknown has value -1', () {
      expect(ActionType.unknown.value, -1);
    });

    test('known values resolve correctly', () {
      expect(findInEnum(ActionType.values, 1), ActionType.blockMessage);
      expect(findInEnum(ActionType.values, 2), ActionType.sendAlertMessage);
      expect(findInEnum(ActionType.values, 3), ActionType.timeout);
      expect(
          findInEnum(ActionType.values, 4), ActionType.blockMemberInteraction);
    });

    test('unknown value with orElse returns unknown', () {
      expect(
        findInEnum(ActionType.values, 99, orElse: ActionType.unknown),
        ActionType.unknown,
      );
    });

    test('unknown value without orElse throws ArgumentError', () {
      expect(
        () => findInEnum(ActionType.values, 99),
        throwsArgumentError,
      );
    });
  });

  group('AutoModerationEventType', () {
    test('unknown has value -1', () {
      expect(AutoModerationEventType.unknown.value, -1);
    });

    test('known values resolve correctly', () {
      expect(findInEnum(AutoModerationEventType.values, 1),
          AutoModerationEventType.messageSend);
      expect(findInEnum(AutoModerationEventType.values, 2),
          AutoModerationEventType.memberUpdate);
    });

    test('unknown value with orElse returns unknown', () {
      expect(
        findInEnum(AutoModerationEventType.values, 99,
            orElse: AutoModerationEventType.unknown),
        AutoModerationEventType.unknown,
      );
    });

    test('unknown value without orElse throws ArgumentError', () {
      expect(
        () => findInEnum(AutoModerationEventType.values, 99),
        throwsArgumentError,
      );
    });
  });
}
