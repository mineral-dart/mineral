import 'package:mineral/src/api/guild/audit_log/audit_log.dart';
import 'package:mineral/src/api/guild/enums/default_message_notification.dart';
import 'package:mineral/src/api/guild/enums/explicit_content_filter.dart';
import 'package:mineral/src/api/guild/enums/forum_layout_types.dart';
import 'package:mineral/src/api/guild/enums/member_flag.dart';
import 'package:mineral/src/api/guild/enums/mfa_level.dart';
import 'package:mineral/src/api/guild/enums/nsfw_level.dart';
import 'package:mineral/src/api/guild/enums/sort_order_forum.dart';
import 'package:mineral/src/api/guild/enums/system_channel_flag.dart';
import 'package:mineral/src/api/guild/enums/verification_level.dart';
import 'package:mineral/src/domains/common/utils/utils.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultMessageNotification', () {
    test('unknown has value -1', () {
      expect(DefaultMessageNotification.unknown.value, -1);
    });

    test('known values resolve correctly', () {
      expect(
        findInEnum(DefaultMessageNotification.values, 0),
        DefaultMessageNotification.allMessages,
      );
      expect(
        findInEnum(DefaultMessageNotification.values, 1),
        DefaultMessageNotification.onlyMentions,
      );
    });

    test('unknown value with orElse returns unknown', () {
      expect(
        findInEnum(
          DefaultMessageNotification.values,
          99,
          orElse: DefaultMessageNotification.unknown,
        ),
        DefaultMessageNotification.unknown,
      );
    });

    test('unknown value without orElse throws ArgumentError', () {
      expect(
        () => findInEnum(DefaultMessageNotification.values, 99),
        throwsArgumentError,
      );
    });
  });

  group('ExplicitContentFilter', () {
    test('unknown has value -1', () {
      expect(ExplicitContentFilter.unknown.value, -1);
    });

    test('known values resolve correctly', () {
      expect(
        findInEnum(ExplicitContentFilter.values, 0),
        ExplicitContentFilter.disabled,
      );
      expect(
        findInEnum(ExplicitContentFilter.values, 1),
        ExplicitContentFilter.membersWithoutRoles,
      );
      expect(
        findInEnum(ExplicitContentFilter.values, 2),
        ExplicitContentFilter.allMembers,
      );
    });

    test('unknown value with orElse returns unknown', () {
      expect(
        findInEnum(
          ExplicitContentFilter.values,
          99,
          orElse: ExplicitContentFilter.unknown,
        ),
        ExplicitContentFilter.unknown,
      );
    });

    test('unknown value without orElse throws ArgumentError', () {
      expect(
        () => findInEnum(ExplicitContentFilter.values, 99),
        throwsArgumentError,
      );
    });
  });

  group('ForumLayoutType', () {
    test('unknown has value -1', () {
      expect(ForumLayoutType.unknown.value, -1);
    });

    test('known values resolve correctly', () {
      expect(findInEnum(ForumLayoutType.values, 0), ForumLayoutType.notSet);
      expect(findInEnum(ForumLayoutType.values, 1), ForumLayoutType.listView);
      expect(
        findInEnum(ForumLayoutType.values, 2),
        ForumLayoutType.galleryView,
      );
    });

    test('unknown value with orElse returns unknown', () {
      expect(
        findInEnum(ForumLayoutType.values, 99, orElse: ForumLayoutType.unknown),
        ForumLayoutType.unknown,
      );
    });

    test('unknown value without orElse throws ArgumentError', () {
      expect(() => findInEnum(ForumLayoutType.values, 99), throwsArgumentError);
    });
  });

  group('MemberFlag', () {
    test('unknown has value -1', () {
      expect(MemberFlag.unknown.value, -1);
    });

    test('known values resolve correctly', () {
      expect(findInEnum(MemberFlag.values, 1 << 0), MemberFlag.didRejoin);
      expect(
        findInEnum(MemberFlag.values, 1 << 1),
        MemberFlag.completedOnboarding,
      );
      expect(
        findInEnum(MemberFlag.values, 1 << 2),
        MemberFlag.bypassedVerification,
      );
      expect(
        findInEnum(MemberFlag.values, 1 << 3),
        MemberFlag.startedOnboarding,
      );
    });

    test('unknown value with orElse returns unknown', () {
      expect(
        findInEnum(MemberFlag.values, 999, orElse: MemberFlag.unknown),
        MemberFlag.unknown,
      );
    });

    test('unknown value without orElse throws ArgumentError', () {
      expect(() => findInEnum(MemberFlag.values, 999), throwsArgumentError);
    });
  });

  group('MfaLevel', () {
    test('unknown has value -1', () {
      expect(MfaLevel.unknown.value, -1);
    });

    test('known values resolve correctly', () {
      expect(findInEnum(MfaLevel.values, 0), MfaLevel.none);
      expect(findInEnum(MfaLevel.values, 1), MfaLevel.elevated);
    });

    test('unknown value with orElse returns unknown', () {
      expect(
        findInEnum(MfaLevel.values, 99, orElse: MfaLevel.unknown),
        MfaLevel.unknown,
      );
    });

    test('unknown value without orElse throws ArgumentError', () {
      expect(() => findInEnum(MfaLevel.values, 99), throwsArgumentError);
    });
  });

  group('NsfwLevel', () {
    test('unknown has value -1', () {
      expect(NsfwLevel.unknown.value, -1);
    });

    test('known values resolve correctly', () {
      expect(findInEnum(NsfwLevel.values, 0), NsfwLevel.none);
      expect(findInEnum(NsfwLevel.values, 1), NsfwLevel.explicit);
      expect(findInEnum(NsfwLevel.values, 2), NsfwLevel.safe);
      expect(findInEnum(NsfwLevel.values, 3), NsfwLevel.ageRestricted);
    });

    test('unknown value with orElse returns unknown', () {
      expect(
        findInEnum(NsfwLevel.values, 99, orElse: NsfwLevel.unknown),
        NsfwLevel.unknown,
      );
    });

    test('unknown value without orElse throws ArgumentError', () {
      expect(() => findInEnum(NsfwLevel.values, 99), throwsArgumentError);
    });
  });

  group('SortOrderType', () {
    test('unknown has value -1', () {
      expect(SortOrderType.unknown.value, -1);
    });

    test('known values resolve correctly', () {
      expect(findInEnum(SortOrderType.values, 0), SortOrderType.lastedActivity);
      expect(findInEnum(SortOrderType.values, 1), SortOrderType.creationDate);
    });

    test('unknown value with orElse returns unknown', () {
      expect(
        findInEnum(SortOrderType.values, 99, orElse: SortOrderType.unknown),
        SortOrderType.unknown,
      );
    });

    test('unknown value without orElse throws ArgumentError', () {
      expect(() => findInEnum(SortOrderType.values, 99), throwsArgumentError);
    });
  });

  group('SystemChannelFlag', () {
    test('unknown has value -1', () {
      expect(SystemChannelFlag.unknown.value, -1);
    });

    test('known values resolve correctly', () {
      expect(
        findInEnum(SystemChannelFlag.values, 1 << 0),
        SystemChannelFlag.suppressJoinNotifications,
      );
      expect(
        findInEnum(SystemChannelFlag.values, 1 << 1),
        SystemChannelFlag.suppressPremiumSubscriptions,
      );
      expect(
        findInEnum(SystemChannelFlag.values, 1 << 2),
        SystemChannelFlag.suppressGuildReminderNotifications,
      );
      expect(
        findInEnum(SystemChannelFlag.values, 1 << 3),
        SystemChannelFlag.suppressJoinNotificationReplies,
      );
      expect(
        findInEnum(SystemChannelFlag.values, 1 << 4),
        SystemChannelFlag.suppressRoleSubscriptionPurchaseNotifications,
      );
      expect(
        findInEnum(SystemChannelFlag.values, 1 << 5),
        SystemChannelFlag.suppressRoleSubscriptionPurchaseNotificationReplies,
      );
    });

    test('unknown value with orElse returns unknown', () {
      expect(
        findInEnum(
          SystemChannelFlag.values,
          999,
          orElse: SystemChannelFlag.unknown,
        ),
        SystemChannelFlag.unknown,
      );
    });

    test('unknown value without orElse throws ArgumentError', () {
      expect(
        () => findInEnum(SystemChannelFlag.values, 999),
        throwsArgumentError,
      );
    });
  });

  group('VerificationLevel', () {
    test('unknown has value -1', () {
      expect(VerificationLevel.unknown.value, -1);
    });

    test('known values resolve correctly', () {
      expect(findInEnum(VerificationLevel.values, 0), VerificationLevel.none);
      expect(findInEnum(VerificationLevel.values, 1), VerificationLevel.low);
      expect(findInEnum(VerificationLevel.values, 2), VerificationLevel.medium);
      expect(findInEnum(VerificationLevel.values, 3), VerificationLevel.high);
      expect(
        findInEnum(VerificationLevel.values, 4),
        VerificationLevel.veryHigh,
      );
    });

    test('unknown value with orElse returns unknown', () {
      expect(
        findInEnum(
          VerificationLevel.values,
          99,
          orElse: VerificationLevel.unknown,
        ),
        VerificationLevel.unknown,
      );
    });

    test('unknown value without orElse throws ArgumentError', () {
      expect(
        () => findInEnum(VerificationLevel.values, 99),
        throwsArgumentError,
      );
    });
  });

  group('AuditLogType', () {
    test('unknown has value -1', () {
      expect(AuditLogType.unknown.value, -1);
    });

    test('known values resolve correctly', () {
      expect(findInEnum(AuditLogType.values, 1), AuditLogType.guildUpdate);
      expect(findInEnum(AuditLogType.values, 10), AuditLogType.channelCreate);
      expect(findInEnum(AuditLogType.values, 20), AuditLogType.memberKick);
      expect(findInEnum(AuditLogType.values, 72), AuditLogType.messageDelete);
      expect(
        findInEnum(AuditLogType.values, 191),
        AuditLogType.homeSettingsUpdate,
      );
    });

    test('unknown value with orElse returns unknown', () {
      expect(
        findInEnum(AuditLogType.values, 999, orElse: AuditLogType.unknown),
        AuditLogType.unknown,
      );
    });

    test('unknown value without orElse throws ArgumentError', () {
      expect(() => findInEnum(AuditLogType.values, 999), throwsArgumentError);
    });
  });
}
