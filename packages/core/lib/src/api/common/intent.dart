/// Gateway intents for controlling which events your bot receives from Discord.
///
/// Intents are used to specify which events your bot wants to receive from Discord's
/// gateway. This allows you to reduce bandwidth usage and improve performance by only
/// subscribing to the events you need.
///
/// ## Usage
///
/// ### Single Intent
/// ```dart
/// final client = ClientBuilder()
///   ..setIntent(Intent.guilds)
///   ..build();
/// ```
///
/// ### Multiple Intents (Bitwise OR)
/// ```dart
/// final client = ClientBuilder()
///   ..setIntent(
///     Intent.guilds |
///     Intent.guildMessages |
///     Intent.guildMembers,
///   )
///   ..build();
/// ```
///
/// ### All Intents
/// ```dart
/// final client = ClientBuilder()
///   ..setIntent(Intent.all)
///   ..build();
/// ```
///
/// ### All Non-Privileged Intents
/// ```dart
/// final client = ClientBuilder()
///   ..setIntent(Intent.allNonPrivileged)
///   ..build();
/// ```
///
/// ## Privileged Intents
///
/// Some intents require special approval from Discord:
/// - [guildMembers]: Access to member-related events
/// - [guildPresences]: Access to presence updates
/// - [messageContent]: Access to message content in messages
///
/// To use privileged intents:
/// 1. Go to the Discord Developer Portal
/// 2. Select your application
/// 3. Go to the "Bot" section
/// 4. Enable the required privileged intents
///
/// ## Intent Categories
///
/// ### Guild (Guild) Events
/// - [guilds]: Guild create/update/delete, channel create/update/delete, role create/update/delete
/// - [guildMembers]: Member join/update/remove (privileged)
/// - [guildModeration]: Ban/unban events
/// - [guildEmojisAndStickers]: Emoji and sticker updates
/// - [guildIntegrations]: Integration updates
/// - [guildWebhooks]: Webhook updates
/// - [guildInvites]: Invite create/delete
/// - [guildVoiceStates]: Voice state updates
/// - [guildPresences]: Presence updates (privileged)
///
/// ### Message Events
/// - [guildMessages]: Guild message events
/// - [guildMessageReactions]: Guild message reaction events
/// - [guildMessageTyping]: Guild typing start events
/// - [directMessages]: DM message events
/// - [directMessageReactions]: DM reaction events
/// - [directMessageTyping]: DM typing start events
/// - [messageContent]: Message content access (privileged)
///
/// ### Scheduled Events
/// - [guildScheduledEvents]: Scheduled event create/update/delete/user add/remove
///
/// ### Auto Moderation
/// - [autoModerationConfiguration]: Auto moderation rule create/update/delete
/// - [autoModerationExecution]: Auto moderation rule execution
///
/// ### Polls
/// - [guildMessagePolls]: Guild message poll vote add/remove
/// - [directMessagePolls]: DM message poll vote add/remove
///
/// ## Best Practices
///
/// - **Request only what you need**: Each intent increases memory usage and bandwidth
/// - **Enable privileged intents carefully**: They require approval and expose sensitive data
/// - **Use specific intents**: Avoid using [all] unless necessary
/// - **Consider [allNonPrivileged]**: Good default for bots that don't need privileged data
/// - **Test with minimal intents**: Start with minimal intents and add as needed
///
/// ## Examples
///
/// ### Moderation Bot
/// ```dart
/// final client = ClientBuilder()
///   ..setIntent(
///     Intent.guilds |
///     Intent.guildMembers |        // Privileged
///     Intent.guildModeration |
///     Intent.guildMessages |
///     Intent.messageContent,       // Privileged
///   )
///   ..build();
/// ```
///
/// ### Music Bot
/// ```dart
/// final client = ClientBuilder()
///   ..setIntent(
///     Intent.guilds |
///     Intent.guildVoiceStates |
///     Intent.guildMessages,
///   )
///   ..build();
/// ```
///
/// ### Utility Bot (Commands Only)
/// ```dart
/// final client = ClientBuilder()
///   ..setIntent(Intent.guilds)  // Minimal for slash commands
///   ..build();
/// ```
///
/// ### Social Bot
/// ```dart
/// final client = ClientBuilder()
///   ..setIntent(
///     Intent.guilds |
///     Intent.guildMessages |
///     Intent.guildMessageReactions |
///     Intent.guildPresences |      // Privileged
///     Intent.messageContent,       // Privileged
///   )
///   ..build();
/// ```
///
/// See also:
/// - [ClientBuilder.setIntent] for setting intents
/// - Discord's [Gateway Intents documentation](https://discord.com/developers/docs/topics/gateway#gateway-intents)
final class Intent {
  /// Combines all non-privileged intents.
  ///
  /// This is a safe default that doesn't require special approval from Discord.
  /// Includes everything except [guildMembers], [guildPresences], and [messageContent].
  ///
  /// Value: 32509
  static const int allNonPrivileged = guilds |
      guildModeration |
      guildEmojisAndStickers |
      guildIntegrations |
      guildWebhooks |
      guildInvites |
      guildVoiceStates |
      guildMessages |
      guildMessageReactions |
      guildMessageTyping |
      directMessages |
      directMessageReactions |
      directMessageTyping |
      guildScheduledEvents |
      autoModerationConfiguration |
      autoModerationExecution |
      guildMessagePolls |
      directMessagePolls;

  /// Combines all available intents (privileged and non-privileged).
  ///
  /// **Warning:** Requires all privileged intents to be enabled in the
  /// Discord Developer Portal. Only use if your bot genuinely needs all events.
  ///
  /// Value: 53608447
  static const int all =
      allNonPrivileged | guildMembers | guildPresences | messageContent;

  // ============================================================================
  // Guild Events
  // ============================================================================

  /// Subscribes to guild and channel events.
  ///
  /// **Events received:**
  /// - Guild create, update, delete
  /// - Channel create, update, delete
  /// - Role create, update, delete
  ///
  /// **Required for:** Most bots (needed for slash commands to work properly)
  ///
  /// Value: 1 << 0 (1)
  static const int guilds = 1 << 0;

  /// Subscribes to guild member events (privileged).
  ///
  /// **Events received:**
  /// - Member join, update, remove
  /// - Thread members update
  ///
  /// **Privileged:** Requires approval in Discord Developer Portal
  ///
  /// **Use cases:** Welcome messages, member counting, role persistence
  ///
  /// Value: 1 << 1 (2)
  static const int guildMembers = 1 << 1;

  /// Subscribes to guild ban and unban events.
  ///
  /// **Events received:**
  /// - Member ban
  /// - Member unban
  ///
  /// **Use cases:** Moderation logging, ban synchronization
  ///
  /// Value: 1 << 2 (4)
  static const int guildModeration = 1 << 2;

  /// Subscribes to emoji and sticker events.
  ///
  /// **Events received:**
  /// - Emoji create, update, delete
  /// - Sticker create, update, delete
  ///
  /// **Use cases:** Emoji managers, sticker tracking
  ///
  /// Value: 1 << 3 (8)
  static const int guildEmojisAndStickers = 1 << 3;

  /// Subscribes to integration events.
  ///
  /// **Events received:**
  /// - Integration create, update, delete
  ///
  /// **Use cases:** Integration management bots
  ///
  /// Value: 1 << 4 (16)
  static const int guildIntegrations = 1 << 4;

  /// Subscribes to webhook events.
  ///
  /// **Events received:**
  /// - Webhook create, update, delete
  ///
  /// **Use cases:** Webhook management, audit logging
  ///
  /// Value: 1 << 5 (32)
  static const int guildWebhooks = 1 << 5;

  /// Subscribes to invite events.
  ///
  /// **Events received:**
  /// - Invite create
  /// - Invite delete
  ///
  /// **Use cases:** Invite tracking, anti-raid protection
  ///
  /// Value: 1 << 6 (64)
  static const int guildInvites = 1 << 6;

  /// Subscribes to voice state events.
  ///
  /// **Events received:**
  /// - Voice state update
  ///
  /// **Required for:** Music bots, voice activity tracking
  ///
  /// **Use cases:** Voice channel monitoring, music bots
  ///
  /// Value: 1 << 7 (128)
  static const int guildVoiceStates = 1 << 7;

  /// Subscribes to presence update events (privileged).
  ///
  /// **Events received:**
  /// - Presence update (status, activity, client status)
  ///
  /// **Privileged:** Requires approval in Discord Developer Portal
  ///
  /// **Use cases:** Activity tracking, status-based features
  ///
  /// **Warning:** Can generate significant traffic in large guilds
  ///
  /// Value: 1 << 8 (256)
  static const int guildPresences = 1 << 8;

  // ============================================================================
  // Message Events
  // ============================================================================

  /// Subscribes to guild message events.
  ///
  /// **Events received:**
  /// - Message create, update, delete (bulk delete)
  ///
  /// **Note:** Without [messageContent], you won't receive the actual message text
  /// for messages not directed at your bot
  ///
  /// **Use cases:** Message logging, chat bots, auto-responders
  ///
  /// Value: 1 << 9 (512)
  static const int guildMessages = 1 << 9;

  /// Subscribes to guild message reaction events.
  ///
  /// **Events received:**
  /// - Reaction add, remove, remove all, remove emoji
  ///
  /// **Use cases:** Reaction roles, starboard, polls
  ///
  /// Value: 1 << 10 (1024)
  static const int guildMessageReactions = 1 << 10;

  /// Subscribes to guild typing events.
  ///
  /// **Events received:**
  /// - Typing start in guild channels
  ///
  /// **Use cases:** Typing indicators, activity monitoring
  ///
  /// **Note:** Can generate significant traffic
  ///
  /// Value: 1 << 11 (2048)
  static const int guildMessageTyping = 1 << 11;

  /// Subscribes to direct message events.
  ///
  /// **Events received:**
  /// - DM message create, update, delete
  ///
  /// **Use cases:** Support tickets, direct user interaction
  ///
  /// Value: 1 << 12 (4096)
  static const int directMessages = 1 << 12;

  /// Subscribes to direct message reaction events.
  ///
  /// **Events received:**
  /// - DM reaction add, remove, remove all, remove emoji
  ///
  /// **Use cases:** DM-based interactive features
  ///
  /// Value: 1 << 13 (8192)
  static const int directMessageReactions = 1 << 13;

  /// Subscribes to direct message typing events.
  ///
  /// **Events received:**
  /// - Typing start in DMs
  ///
  /// **Use cases:** DM typing indicators
  ///
  /// Value: 1 << 14 (16384)
  static const int directMessageTyping = 1 << 14;

  /// Enables access to message content (privileged).
  ///
  /// **Provides access to:**
  /// - Message content field
  /// - Message embeds field
  /// - Message attachments field
  /// - Message components field
  ///
  /// **Privileged:** Requires approval in Discord Developer Portal
  ///
  /// **Required for:** Chat bots, content moderation, message analysis
  ///
  /// **Note:** Always available for:
  /// - Messages where your bot is mentioned
  /// - DMs with your bot
  /// - Messages from your bot
  ///
  /// Value: 1 << 15 (32768)
  static const int messageContent = 1 << 15;

  // ============================================================================
  // Scheduled Events
  // ============================================================================

  /// Subscribes to scheduled event notifications.
  ///
  /// **Events received:**
  /// - Scheduled event create, update, delete
  /// - Scheduled event user add, remove
  ///
  /// **Use cases:** Event reminders, event management
  ///
  /// Value: 1 << 16 (65536)
  static const int guildScheduledEvents = 1 << 16;

  // ============================================================================
  // Auto Moderation
  // ============================================================================

  /// Subscribes to auto moderation rule configuration events.
  ///
  /// **Events received:**
  /// - Auto moderation rule create, update, delete
  ///
  /// **Use cases:** Auto moderation management, audit logging
  ///
  /// Value: 1 << 20 (1048576)
  static const int autoModerationConfiguration = 1 << 20;

  /// Subscribes to auto moderation execution events.
  ///
  /// **Events received:**
  /// - Auto moderation action execution
  ///
  /// **Use cases:** Moderation logging, rule effectiveness tracking
  ///
  /// Value: 1 << 21 (2097152)
  static const int autoModerationExecution = 1 << 21;

  // ============================================================================
  // Polls
  // ============================================================================

  /// Subscribes to guild message poll vote events.
  ///
  /// **Events received:**
  /// - Poll vote add, remove in guild messages
  ///
  /// **Use cases:** Poll result tracking, vote-based features
  ///
  /// Value: 1 << 24 (16777216)
  static const int guildMessagePolls = 1 << 24;

  /// Subscribes to direct message poll vote events.
  ///
  /// **Events received:**
  /// - Poll vote add, remove in DMs
  ///
  /// **Use cases:** DM-based polls
  ///
  /// Value: 1 << 25 (33554432)
  static const int directMessagePolls = 1 << 25;

  // Private constructor to prevent instantiation
  Intent._();
}
