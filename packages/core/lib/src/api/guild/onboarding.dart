import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/api/guild/enums/onboarding_mode.dart';
import 'package:mineral/src/api/guild/enums/onboarding_prompt_type.dart';

export 'package:mineral/src/api/guild/enums/onboarding_mode.dart';
export 'package:mineral/src/api/guild/enums/onboarding_prompt_type.dart';

/// An option inside an [OnboardingPrompt].
final class OnboardingPromptOption {
  /// The option's unique id.
  final Snowflake id;

  /// Channel ids that a member gains access to when this option is selected.
  final List<Snowflake> channelIds;

  /// Role ids assigned to the member when this option is selected.
  final List<Snowflake> roleIds;

  /// The emoji id if the emoji is custom.
  final Snowflake? emojiId;

  /// The emoji name if custom, the unicode character if standard, or null.
  final String? emojiName;

  /// Whether the emoji is animated.
  final bool? emojiAnimated;

  /// The title of the option.
  final String title;

  /// The description of the option.
  final String? description;

  const OnboardingPromptOption({
    required this.id,
    required this.channelIds,
    required this.roleIds,
    required this.title,
    this.emojiId,
    this.emojiName,
    this.emojiAnimated,
    this.description,
  });

  factory OnboardingPromptOption.fromJson(Map<String, dynamic> json) {
    final emoji = json['emoji'] as Map<String, dynamic>?;
    final rawChannelIds = (json['channel_ids'] as List<dynamic>? ?? [])
        .cast<String>();
    final rawRoleIds = (json['role_ids'] as List<dynamic>? ?? [])
        .cast<String>();

    return OnboardingPromptOption(
      id: Snowflake.parse(json['id']),
      channelIds: rawChannelIds.map(Snowflake.parse).toList(),
      roleIds: rawRoleIds.map(Snowflake.parse).toList(),
      emojiId: emoji != null ? Snowflake.nullable(emoji['id']) : null,
      emojiName: emoji?['name'] as String?,
      emojiAnimated: emoji?['animated'] as bool?,
      title: json['title'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.value,
      'channel_ids': channelIds.map((s) => s.value).toList(),
      'role_ids': roleIds.map((s) => s.value).toList(),
      if (emojiId != null || emojiName != null || emojiAnimated != null)
        'emoji': {
          if (emojiId != null) 'id': emojiId!.value,
          if (emojiName != null) 'name': emojiName,
          if (emojiAnimated != null) 'animated': emojiAnimated,
        },
      'title': title,
      if (description != null) 'description': description,
    };
  }
}

/// A single onboarding prompt shown to new members.
final class OnboardingPrompt {
  /// The prompt's unique id.
  final Snowflake id;

  /// The type of prompt (multiple choice or dropdown).
  final OnboardingPromptType type;

  /// The options available in this prompt.
  final List<OnboardingPromptOption> options;

  /// The title displayed for this prompt.
  final String title;

  /// Whether only one option can be selected at a time.
  final bool singleSelect;

  /// Whether the prompt is required before a member can finish onboarding.
  final bool required;

  /// Whether the prompt is present in the onboarding flow.
  final bool inOnboarding;

  const OnboardingPrompt({
    required this.id,
    required this.type,
    required this.options,
    required this.title,
    required this.singleSelect,
    required this.required,
    required this.inOnboarding,
  });

  factory OnboardingPrompt.fromJson(Map<String, dynamic> json) {
    final rawOptions = (json['options'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final typeValue = json['type'] as int;
    return OnboardingPrompt(
      id: Snowflake.parse(json['id']),
      type: OnboardingPromptType.values.firstWhere(
        (e) => e.value == typeValue,
        orElse: () => OnboardingPromptType.multipleChoice,
      ),
      options: rawOptions.map(OnboardingPromptOption.fromJson).toList(),
      title: json['title'] as String,
      singleSelect: json['single_select'] as bool,
      required: json['required'] as bool,
      inOnboarding: json['in_onboarding'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.value,
      'type': type.value,
      'options': options.map((o) => o.toJson()).toList(),
      'title': title,
      'single_select': singleSelect,
      'required': required,
      'in_onboarding': inOnboarding,
    };
  }
}

/// A guild's onboarding configuration.
final class Onboarding {
  /// The id of the guild this onboarding belongs to.
  final Snowflake guildId;

  /// The prompts shown during onboarding and in the community customization
  /// menu.
  final List<OnboardingPrompt> prompts;

  /// The channel ids that members get opted into automatically.
  final List<Snowflake> defaultChannelIds;

  /// Whether onboarding is enabled in the guild.
  final bool enabled;

  /// The mode for onboarding.
  final OnboardingMode mode;

  const Onboarding({
    required this.guildId,
    required this.prompts,
    required this.defaultChannelIds,
    required this.enabled,
    required this.mode,
  });

  factory Onboarding.fromJson(Map<String, dynamic> json) {
    final rawPrompts = (json['prompts'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final rawChannelIds = (json['default_channel_ids'] as List<dynamic>? ?? [])
        .cast<String>();
    final modeValue = json['mode'] as int;
    return Onboarding(
      guildId: Snowflake.parse(json['guild_id']),
      prompts: rawPrompts.map(OnboardingPrompt.fromJson).toList(),
      defaultChannelIds: rawChannelIds.map(Snowflake.parse).toList(),
      enabled: json['enabled'] as bool,
      mode: OnboardingMode.values.firstWhere(
        (e) => e.value == modeValue,
        orElse: () => OnboardingMode.default_,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'guild_id': guildId.value,
      'prompts': prompts.map((p) => p.toJson()).toList(),
      'default_channel_ids': defaultChannelIds.map((s) => s.value).toList(),
      'enabled': enabled,
      'mode': mode.value,
    };
  }
}
