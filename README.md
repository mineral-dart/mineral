# Mineral

Mineral is a Dart framework for building Discord bots. It handles the Discord gateway, REST API, and interaction routing so you can focus on your bot's logic.

Everything is organized around **providers** — isolated modules that register commands, events, and components. Each feature lives in its own class, making bots easy to grow and maintain across a team.

[![Discord](https://img.shields.io/badge/Discord-7289DA?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/fH9UQDMZSn)

---

## Packages

| Package                         | Description                                                      | Version                                                                                          |
| ------------------------------- | ---------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| [mineral](packages/core)        | Core framework — gateway, REST API, commands, events, components | [![pub](https://img.shields.io/pub/v/mineral.svg)](https://pub.dev/packages/mineral)             |
| [mineral_cache](packages/cache) | Cache providers — in-memory and Redis                            | [![pub](https://img.shields.io/pub/v/mineral_cache.svg)](https://pub.dev/packages/mineral_cache) |

---

## Examples

### Setting up a bot

Register providers and start the bot. Each provider groups related commands, events, and components.

```dart
void main() async {
  final client = await ClientBuilder()
    .setIntent(Intent.allNonPrivileged)
    .registerProvider(WelcomeProvider.new)
    .registerProvider(FeedbackProvider.new)
    .build();

  await client.init();
}
```

```dart
final class WelcomeProvider extends Provider {
  final Client _client;

  WelcomeProvider(this._client) {
    _client
      ..register<OnMemberJoin>(OnMemberJoin.new)
      ..register<FeedbackButton>(FeedbackButton.new);
  }
}
```

---

### Welcoming a new member

React to a member joining the guild and send a message in the system channel.

```dart
final class OnMemberJoin extends GuildMemberAddEvent {
  @override
  Future<void> handle(Member member, Guild guild) async {
    final channel = await guild.channels.resolveSystemChannel();
    await channel?.send(MessageBuilder.text('Welcome, ${member.username}!'));
  }
}
```

---

### Slash command with an option

Declare a `/say` command that repeats a message back to the user.

```dart
final class SayCommand implements CommandDeclaration {
  Future<void> handle(GuildCommandContext ctx, CommandOptions options) async {
    final message = options.require<String>('message');
    await ctx.interaction.reply(builder: MessageBuilder.text(message));
  }

  @override
  CommandDeclarationBuilder build() {
    return CommandDeclarationBuilder()
      ..setName('say')
      ..setDescription('Repeat a message')
      ..addOption(Option.string(name: 'message', description: 'Text to repeat', required: true))
      ..setHandle(handle);
  }
}
```

---

### Button interaction

Bind a button to a handler by its `customId`. Mineral routes the click automatically — no switch statement, no manual dispatch.

```dart
final class FeedbackButton extends GuildButtonClickEvent {
  @override
  String? get customId => 'open_feedback';

  @override
  Future<void> handle(GuildButtonContext ctx) async {
    await ctx.interaction.reply(
      builder: MessageBuilder.text('Thanks for your feedback!'),
    );
  }
}
```

---

## Development

This repo uses [Dart workspaces](https://dart.dev/tools/pub/workspaces). All packages share a single dependency resolution from the root.

```bash
# Install all dependencies
dart pub get

# Run tests for a specific package
dart test packages/core
dart test packages/cache

# Analyze a specific package
dart analyze packages/core
dart analyze packages/cache
```

---

## Publishing

Each package is published independently, triggered by a git tag.

```bash
git tag core-v4.3.0 && git push origin core-v4.3.0      # publishes mineral
git tag cache-v1.3.0 && git push origin cache-v1.3.0    # publishes mineral_cache
```
