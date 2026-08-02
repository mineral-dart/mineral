## Unreleased

Audit remediation (chantier #458). Version deliberately unassigned — the
breaking changes below make this at least a major bump, but the call is the
maintainer's.

### Breaking changes

All four sit on code paths that threw on every invocation, so no consumer had
working code to break — but they are public-surface changes and are listed as
such.

- **`VoiceState.isDiscoverable` removed.** `discoverable` is not part of
  Discord's voice state object; the field never carried data and `serialize`
  null-cast on every voice state, so no `VoiceState` could ever be obtained.
- **`Invite.inviterId` and `Invite.createdAt` are now nullable.** Vanity invites
  genuinely have no inviter, and `created_at` only appears on the Invite
  Metadata extension. A placeholder id would not have stayed inert:
  `Invite.resolveInviter()` turns it into a real `GET /users/{id}`.
- **`Permission.usePublicThreads` and `Permission.usePrivateThreads` removed.**
  They duplicated the bit values of `createPublicThreads`/`createPrivateThreads`,
  which made every permission bitfield round-trip carry into the adjacent bit.
  Discord itself renamed these; the `create*` members are the current names.
- **`CommandBuilder` now declares members.** It was an empty marker interface;
  it now requires `name`, `context`, `toJson()`, `reduceHandlers()` and
  `declaration`. Downstream code that implements it must supply them. This is
  what removes five duplicated type-switches from the command manager and makes
  a new builder type a compile-time concern rather than a runtime throw.
- **`CommandDefinitionBuilder.context<T>()` renamed to `configure<T>()`.** It
  collided with the interface's `context` getter. The renamed method had no
  usages anywhere in the repository and no tests; the `context` getter is the
  established convention across the other builders.
- **`CommandDeclarationBuilder.reduceHandlers(String)` is now no-arg.** Every
  call site passed the receiver's own `name`.
- **`EnvPlaceholder()` no longer exposes anything without an explicit
  allowlist.** It previously copied the entire process environment — bot token
  included — into a public substitution table. Pass
  `EnvPlaceholder(keys: {...})` to opt in; the bot token is excluded
  unconditionally regardless of the allowlist.

### Fixed — paths that were broken on every call

- `message.delete()`, `message.pin()` and every reaction threw a raw `TypeError`
  (204 responses were cast through an untyped empty-map literal).
- `guild.roles.get/create/update` and `guild.emojis.fetch/get` threw
  `type 'Null' is not a subtype of type 'String'` — five datastore parts omitted
  the `guild_id` injection their siblings perform.
- `Guild.assets.icon`, `.splash`, `.banner`, `.discoverySplash`,
  `settings.bitfieldPermission`, `.afkTimeout`, `.hasWidgetEnabled`,
  `.vanityUrlCode` and `.maxVideoChannelUsers` were silently always null or
  false — `serialize` read flat keys that `normalize` nests.
- Every voice-state deserialization threw; every GIF and LOTTIE sticker threw
  `StateError` (`FormatType` declared only two of Discord's four values).
- Emoji `roles` were read as objects; Discord sends bare snowflake strings, and
  the ids were mapped to the wrong cache-key namespace.
- Button clicks in direct messages dispatched nothing at all — not the
  component handler, not even `Event.privateButtonClick`. The private handler
  matched `ButtonType` against the button's `custom_id` instead of its `type`,
  so the lookup failed for every realistic id and the method returned early.
  Behind that sat two further defects: the interactive component manager was
  never called, and the author was read from `payload['member']`, which Discord
  omits in a DM. All three are fixed together; fixing only the first would have
  turned a silent no-op into a null-cast crash.

### Fixed — resilience

- A reconnect that failed before HELLO left `intentionalDisconnect` set forever,
  killing the shard permanently while the process stayed alive and looked
  healthy. The flag is now cleared in a `finally`, and a separate `shuttingDown`
  flag carries the dispose intent it was overloaded with.
- Resume connected to the bare `resume_gateway_url`, dropping `?v=` and
  `encoding=`. Under `encoding=etf` this made Discord fall back to JSON frames
  the ETF decoder silently discarded — permanent deafness. The URL is now built
  in one place, shared by the initial connect and the resume path.
- Gateway opcode handlers dropped the futures from `reconnect()`, `resume()` and
  `heartbeat()`, so a `FatalGatewayException` reached the root zone and
  terminated the host process.
- A malformed or deeply nested ETF frame raised `RangeError` or
  `StackOverflowError` — both `Error`, which the `on Exception` guard could not
  catch — killing the isolate.
- A consumer's button, modal or select-menu handler that threw killed the bot
  process. Component dispatch now awaits inside the same crash boundary
  `EventListener` already used, with an `onComponentError` callback.
- `ReadyPacket`'s guard spanned two awaits, so a second shard's READY issued a
  duplicate global-command registration; the staggered cache clear could also
  land after GUILD_CREATE had already hydrated the cache.

### Fixed — correctness

- Unclassified HTTP statuses (304, 409, 413, 501) fell through the retry loop
  and re-sent the request up to five times — five messages, for a POST — then
  reported the failure as a rate limit. Statuses are now classified by range.
- Non-JSON error bodies (Cloudflare HTML pages) raised a bare `FormatException`
  that bypassed the retry path entirely and leaked the request queue entry.
- Slash-command registration ignored every HTTP failure except 400 and bypassed
  the rate-limit bucket entirely, so a bot in N guilds fired N unthrottled PUTs
  at startup and silently ignored the resulting 429s.
- Outbound timestamps were serialized in local time with no UTC offset, so
  `member.exclude()` could transmit an instant in the past and silently never
  apply.
- Invites were cached under the voice-state key, clobbering the inviter's cached
  voice state on the gateway path.

### Security

- The publish workflow no longer executes third-party dependency code in the job
  holding the pub.dev OIDC token. `verify` (`contents: read`) runs
  analyze/test/dry-run; `publish` (`needs: verify`, `id-token: write`) only
  publishes. `pubspec.lock` is now committed and CI resolves with
  `--enforce-lockfile`.
- The rate-limit registry no longer keys an unbounded map by raw interaction and
  webhook tokens, and evicts buckets whose reset window is long past.
- `package:mineral/api.dart` no longer re-exports the whole of `env_guard`.
  Seventeen files' worth of generic names (`Schema`, `Rule`, `Property`,
  `Validator`, `Loader`, ...) are no longer part of mineral's public namespace.

### Internal

- `ClientBuilder.build()`'s wiring is extracted into a pure `composeApp`
  function so the composition root can be tested. `build()` stays synchronous
  and its behaviour is unchanged. Both hand-closed construction cycles and
  `packetListener.init()` now have tests; deleting either line fails exactly one
  of them. `composeApp` and `AppComposition` are hidden from the public barrel —
  they exist for testability and expose internal types.

### Testing

The fixtures backing the marshaller tests were rebuilt from the Discord wire
format. They had been written to match what each serializer expected, so the
suite validated the code against itself — green while the framework was broken.
A `normalize -> serialize` round-trip assertion now guards that contract.

## 5.1.1

### WebSocket resilience fixes

- **H1** — WebSocket error handler is now always attached before the stream is
  listened to, preventing unhandled-stream-error crashes on connection failure.
- **H2** — Malformed or unexpected frame payloads are logged and dropped
  instead of crashing the shard message loop.
- **H3** — A `connect()` failure (e.g. `WebSocketException`, `SocketException`)
  now triggers the exponential-backoff reconnect strategy rather than silently
  hanging.
- **H4** — `resume()` and `reconnect()` are no longer fire-and-forget. A
  `FatalGatewayException` thrown when `maxReconnectAttempts` is exceeded is now
  caught by a supervised `catchError` handler and routed to a private
  `_handleFatal` helper (cancel heartbeat → disconnect client → invoke
  `onFatalDisconnect`). The `DisconnectAction.fatal` path likewise calls
  `_handleFatal` instead of throwing synchronously from a stream callback.
  Heartbeat Timer callbacks in `ShardAuthentication` are supervised by the same
  pattern via `_onHeartbeatError`. `onFatalDisconnect` is promoted to the
  `WebsocketOrchestratorContract` interface so any implementation (including
  test doubles) can register the callback.

# 5.1.0

## Breaking changes — `Server` → `Guild` rename

All framework identifiers that used the word "server" to refer to a Discord
guild have been renamed to "guild" for consistency with the Discord API.

### Renamed classes and types

- `Server` → `Guild`
- `ServerMessage` → `GuildMessage`
- `ServerSettings` → `GuildSettings`
- `ServerAssets` → `GuildAssets`
- `ServerSubscription` → `GuildSubscription`
- `ServerChannel` → `GuildChannel`
- `ServerTextChannel` → `GuildTextChannel`
- `ServerVoiceChannel` → `GuildVoiceChannel`
- `ServerAnnouncementChannel` → `GuildAnnouncementChannel`
- `ServerCategoryChannel` → `GuildCategoryChannel`
- `ServerForumChannel` → `GuildForumChannel`
- `ServerStageChannel` → `GuildStageChannel`
- `ServerCommandContext` → `GuildCommandContext`
- `ServerButtonContext` → `GuildButtonContext`
- `ServerModalContext` → `GuildModalContext`
- `ServerSelectContext` → `GuildSelectContext`
- `ServerBucket` → `GuildBucket`
- `ServerEvents` → `GuildEvents`
- `ServerBanAddEvent` → `GuildBanAddEvent`

### Renamed fields and parameters

- `serverId` → `guildId` on all entities, managers, and datastore parts
- `resolveServer(...)` → `resolveGuild(...)` (marshaller API)
- `client.events.server` → `client.events.guild`

### Renamed event labels

- `serverCreate` → `guildCreate`
- `serverUpdate` → `guildUpdate`
- `serverDelete` → `guildDelete`
- All `Server*Event` metadata strings → `Guild*Event`

### Cache key changes

Cache keys changed from `server/...` to `guild/...`. **Deploy cache
invalidation is required** — any persisted cache entries under `server/...`
keys will not be read after upgrading.

### Migration

Search-and-replace `Server` → `Guild` (CamelCase) and `server` → `guild`
(snake_case / camelCase prefix) across your bot source code, excluding
HTTP-layer strings such as "internal server error".

---

# 5.0.0

## Highlights

Mineral drops its built-in HMR scaffolding and relies on `package:hmr` ^2.0.0
running externally. The two-isolate model (main + development) is gone — bots
now execute in a single process and hot reload preserves both the Discord
gateway connection and in-memory state across edits.

## Breaking changes

- `ClientBuilder.setHmrDevPort(SendPort?)` removed. Bots no longer receive a
  `SendPort` from a parent isolate.
- `ClientBuilder.watch(List<Glob>)` removed. Configure watched paths in your
  app's `pubspec.yaml` under the `hmr.include` key instead.
- `main()` signature change. User entrypoints become standard
  `void main(List<String> args)` (no `SendPort? port` second argument).
- `HmrRunningStrategy` deleted. `Kernel` always uses `DefaultRunningStrategy`.
- `ReadyPacketMessage` and `RuntimeState.readyPacketMessage` removed — replay
  is no longer needed because the WebSocket session survives reloads in
  process.

## Migration

In your bot:

```diff
- import 'dart:isolate';
  import 'package:mineral/api.dart';

- void main(List<String> _, SendPort? port) async {
+ void main(List<String> args) async {
    final client = ClientBuilder()
-       .setHmrDevPort(port)
        .setIntent(Intent.allNonPrivileged)
        .build();
    await client.init();
  }
```

In your bot's `pubspec.yaml`:

```yaml
dev_dependencies:
  hmr: ^2.0.0

# optional, defaults to bin/<package>.dart
hmr:
  entrypoint: bin/main.dart
```

To run with hot reload:

```bash
dart run hmr
```

# 4.2.0

## What's Changed

- fix: late initialization error by @PandaGuerrier in https://github.com/mineral-dart/core/pull/101
- feat: Improve some changes by @LeadcodeDev in https://github.com/mineral-dart/core/pull/102
- feat: Upgrade of CLI service and some changes by @LeadcodeDev in https://github.com/mineral-dart/core/pull/103
- add soundboard feature by @PandaGuerrier in https://github.com/mineral-dart/core/pull/104
- fix: Lot of bug fixes (may refactoring) by @vic256 in https://github.com/mineral-dart/core/pull/105
- docs: Write related guild documentations by @LeadcodeDev in https://github.com/mineral-dart/core/pull/106
- feat: Add permission structure by @LeadcodeDev in https://github.com/mineral-dart/core/pull/108
- feat: Added threads (only by message) by @PandaGuerrier in https://github.com/mineral-dart/core/pull/109
- feat: Added activities in GUILD_CREATE packet. by @PandaGuerrier in https://github.com/mineral-dart/core/pull/107
- feat: References by @PandaGuerrier in https://github.com/mineral-dart/core/pull/110
- feat: doc by @PandaGuerrier in https://github.com/mineral-dart/core/pull/111
- fix: Accept null guild features by @vic256 in https://github.com/mineral-dart/core/pull/112
- fix: permissions by @PandaGuerrier in https://github.com/mineral-dart/core/pull/113
- feat: commands (roles, users and channels) permissions by @PandaGuerrier in https://github.com/mineral-dart/core/pull/115
- feat: improved the DX for subcommands by @PandaGuerrier in https://github.com/mineral-dart/core/pull/114
- feat: implement discord features & improve commands by @LeadcodeDev in https://github.com/mineral-dart/core/pull/116
- feat: implement missing features by @LeadcodeDev in https://github.com/mineral-dart/core/pull/117
- Before release by @PandaGuerrier in https://github.com/mineral-dart/core/pull/118
- Before release by @PandaGuerrier in https://github.com/mineral-dart/core/pull/119
- feat: Implement snowflake timestamp by @vic256 in https://github.com/mineral-dart/core/pull/120
- fix: option can be null by @PandaGuerrier in https://github.com/mineral-dart/core/pull/121
- Added reaction events by @PandaGuerrier in https://github.com/mineral-dart/core/pull/122
- fix: delete interaction message by @PandaGuerrier in https://github.com/mineral-dart/core/pull/123
- feat: utils before release by @PandaGuerrier in https://github.com/mineral-dart/core/pull/124
- fix: allow nullables by @LeadcodeDev in https://github.com/mineral-dart/core/pull/125
- fix: guild create by @PandaGuerrier in https://github.com/mineral-dart/core/pull/126
- New release by @PandaGuerrier in https://github.com/mineral-dart/core/pull/127
- feat: implement error handling by @LeadcodeDev in https://github.com/mineral-dart/core/pull/128
- feat: implement container by @LeadcodeDev in https://github.com/mineral-dart/core/pull/129
- feat: implement http service by @LeadcodeDev in https://github.com/mineral-dart/core/pull/130
- feat: implement environment service by @LeadcodeDev in https://github.com/mineral-dart/core/pull/131
- feat: implement logger service by @LeadcodeDev in https://github.com/mineral-dart/core/pull/132
- feat: implement kernel and developer settings by @LeadcodeDev in https://github.com/mineral-dart/core/pull/133
- feat: implement http endpoint repositories by @LeadcodeDev in https://github.com/mineral-dart/core/pull/134
- feat: implement console by @LeadcodeDev in https://github.com/mineral-dart/core/pull/135
- feat: implement http rate limit by @abitofevrything in https://github.com/mineral-dart/core/pull/136
- fix: intents by @LeadcodeDev in https://github.com/mineral-dart/core/pull/138
- feat(events): event managing by @LeadcodeDev in https://github.com/mineral-dart/core/pull/139
- feat(serializers): implement api serializers by @LeadcodeDev in https://github.com/mineral-dart/core/pull/140
- feat: implement-hmr by @LeadcodeDev in https://github.com/mineral-dart/core/pull/141
- feat: enhance infrastructure by @LeadcodeDev in https://github.com/mineral-dart/core/pull/152
- feat: implement-slash-commands-builder by @LeadcodeDev in https://github.com/mineral-dart/core/pull/155
- feat: implement-commands-domain by @PandaGuerrier in https://github.com/mineral-dart/core/pull/157
- feat(ioc): change ioc resolver from string to type by @LeadcodeDev in https://github.com/mineral-dart/core/pull/159
- feat(api): implement stage voice channels by @LeadcodeDev in https://github.com/mineral-dart/core/pull/164
- feat: enhance marshaller data structure by @LeadcodeDev in https://github.com/mineral-dart/core/pull/168
- feat: implement command translations and command definition by @LeadcodeDev in https://github.com/mineral-dart/core/pull/173
- feat: implement command class by @LeadcodeDev in https://github.com/mineral-dart/core/pull/175
- Implement interaction methods by @PandaGuerrier in https://github.com/mineral-dart/core/pull/166
- fix: member not exist when ban by @LeadcodeDev in https://github.com/mineral-dart/core/pull/177
- Implement member methods by @LeadcodeDev in https://github.com/mineral-dart/core/pull/178
- feat: implement-components by @LeadcodeDev in https://github.com/mineral-dart/core/pull/182
- feat: implement components by @LeadcodeDev in https://github.com/mineral-dart/core/pull/189
- fix: multiple bugs by @PandaGuerrier in https://github.com/mineral-dart/core/pull/190
- Remove member from cache when ban by @PyGaVS in https://github.com/mineral-dart/core/pull/180
- feat: enhance serialization by @LeadcodeDev in https://github.com/mineral-dart/core/pull/195
- feat: implement thread events by @PandaGuerrier in https://github.com/mineral-dart/core/pull/196
- feat: implement server message methods by @LeadcodeDev in https://github.com/mineral-dart/core/pull/183
- feat: implement server methods by @DakioCode in https://github.com/mineral-dart/core/pull/199
- fix: missing server_id during member normalization in GuildMemberAddPacket by @ThibaultPointurier in https://github.com/mineral-dart/core/pull/201
- fix: address multiple issues and refactor role normalization logic by @ThibaultPointurier in https://github.com/mineral-dart/core/pull/203
- feat: implement cli by @LeadcodeDev in https://github.com/mineral-dart/core/pull/205
- fix: change id from server to guild in channel update packet by @LeadcodeDev in https://github.com/mineral-dart/core/pull/210
- fix: small problems by @PandaGuerrier in https://github.com/mineral-dart/core/pull/207
- feat(docs): finish documenting methods in server side api by @PandaGuerrier in https://github.com/mineral-dart/core/pull/214
- feat: implement global states by @LeadcodeDev in https://github.com/mineral-dart/core/pull/217
- feat: enhance dependencies injection by @LeadcodeDev in https://github.com/mineral-dart/core/pull/219
- feat: implement heartbeat failed 3 time by @LeadcodeDev in https://github.com/mineral-dart/core/pull/221
- feat: implement scaffolding structure by @LeadcodeDev in https://github.com/mineral-dart/core/pull/222
- feat: server forum channel type by @LeadcodeDev in https://github.com/mineral-dart/core/pull/224
- fix: command role and member serialization by @LeadcodeDev in https://github.com/mineral-dart/core/pull/226
- feat: migrate structure serialization by @LeadcodeDev in https://github.com/mineral-dart/core/pull/228
- feat: implement ratelimit by @LeadcodeDev in https://github.com/mineral-dart/core/pull/229
- feat: implement reaction events by @LeadcodeDev in https://github.com/mineral-dart/core/pull/230
- feat: implement todo by @LeadcodeDev in https://github.com/mineral-dart/core/pull/232
- feat: implement interactive components by @LeadcodeDev in https://github.com/mineral-dart/core/pull/234
- feat: rework member roles by @LeadcodeDev in https://github.com/mineral-dart/core/pull/235
- feat: implement etf encoding by @LeadcodeDev in https://github.com/mineral-dart/core/pull/236
- fix: add message return type by @LeadcodeDev in https://github.com/mineral-dart/core/pull/241
- feat: enhance command manager by @LeadcodeDev in https://github.com/mineral-dart/core/pull/243
- fix: add missing 'inline' params in addField embed builder by @slabbdev in https://github.com/mineral-dart/core/pull/240
- feat: implement audit log events by @LeadcodeDev in https://github.com/mineral-dart/core/pull/245
- feat: implement component v2 message by @LeadcodeDev in https://github.com/mineral-dart/core/pull/246
- feat: implement-formdata-and-message-files by @LeadcodeDev in https://github.com/mineral-dart/core/pull/247
- feat: introduce invite events by @LeadcodeDev in https://github.com/mineral-dart/core/pull/248
- feat: migrate environment service to env_guard package by @LeadcodeDev in https://github.com/mineral-dart/core/pull/249
- feat: implement typing event by @LeadcodeDev in https://github.com/mineral-dart/core/pull/250
- feat: implements polls events by @PandaGuerrier in https://github.com/mineral-dart/core/pull/253
- feat: implement interactive component v2 by @LeadcodeDev in https://github.com/mineral-dart/core/pull/254
- feat: migrate to hmr package by @LeadcodeDev in https://github.com/mineral-dart/core/pull/261
- feat: implement message reaction remove all event by @PandaGuerrier in https://github.com/mineral-dart/core/pull/270
- fix: set serverId to nullable snowflake for private issues by @PandaGuerrier in https://github.com/mineral-dart/core/pull/272
- feat: implement auto moderation by @PandaGuerrier in https://github.com/mineral-dart/core/pull/274
- feat: implement automod event by @PandaGuerrier in https://github.com/mineral-dart/core/pull/276
- feat: createdAt getters by @DCodeProg in https://github.com/mineral-dart/core/pull/281
- fix: null channel id voices by @PandaGuerrier in https://github.com/mineral-dart/core/pull/279
- feat: added regex verification for name in commands by @PandaGuerrier in https://github.com/mineral-dart/core/pull/286
- feat: override toString method in User class for easy mention by @DCodeProg in https://github.com/mineral-dart/core/pull/287
- chore: remove unused import statements from automoderation rule packets by @DCodeProg in https://github.com/mineral-dart/core/pull/289
- chore: add export for voice state in API by @DCodeProg in https://github.com/mineral-dart/core/pull/292
- fix: audit logs causes crashs by @DCodeProg in https://github.com/mineral-dart/core/pull/293
- fix: add missing export for voice_move_event by @DCodeProg in https://github.com/mineral-dart/core/pull/294
- feat: add resolveServer method to voice state by @DCodeProg in https://github.com/mineral-dart/core/pull/295
- feat: add support for modal components by @DCodeProg in https://github.com/mineral-dart/core/pull/288
- fix: bind bot class to ioc services. by @PandaGuerrier in https://github.com/mineral-dart/core/pull/297
- feat: implement message gallery component attached files by @PandaGuerrier in https://github.com/mineral-dart/core/pull/298
- fix: resolve in GlobalStateManager instead of Service. by @PandaGuerrier in https://github.com/mineral-dart/core/pull/301
- chore: add createdAt getter to Interaction class by @DCodeProg in https://github.com/mineral-dart/core/pull/299
- feat: added member voices states from cache for voices by @PandaGuerrier in https://github.com/mineral-dart/core/pull/303
- 306 rework attachments in interaction for better dev by @PandaGuerrier in https://github.com/mineral-dart/core/pull/308
- refactor!: significant refactor of message and modal components by @DCodeProg in https://github.com/mineral-dart/core/pull/310
- feat: rerun ready event to prevent the non-existence of bot instance by @LeadcodeDev in https://github.com/mineral-dart/core/pull/312
- feat!: add VoiceConnect/Disconnect events and update voice event semantics by @DCodeProg in https://github.com/mineral-dart/core/pull/314
- feat: implement Intent system for gateway event subscriptions by @DCodeProg in https://github.com/mineral-dart/core/pull/317
- feat: add SubcommandDeclarationBuilder interface by @DCodeProg in https://github.com/mineral-dart/core/pull/315
- docs: add package example by @DCodeProg in https://github.com/mineral-dart/core/pull/320
- chore: update project dependencies by @DCodeProg in https://github.com/mineral-dart/core/pull/321

## New Contributors

- @abitofevrything made their first contribution in https://github.com/mineral-dart/core/pull/136
- @PyGaVS made their first contribution in https://github.com/mineral-dart/core/pull/180
- @DakioCode made their first contribution in https://github.com/mineral-dart/core/pull/199
- @slabbdev made their first contribution in https://github.com/mineral-dart/core/pull/240
- @DCodeProg made their first contribution in https://github.com/mineral-dart/core/pull/281

**Full Changelog**: https://github.com/mineral-dart/core/compare/v3.1.0...v4.0.0

# 4.1.0-dev.1

## Major Features

- Added a wide range of new Discord events: audit logs, invites, typing, polls, auto-moderation, auto-mod triggers, message reaction remove all.
- Full implementation of Components V2 + Interactive Components V2.
- Added support for modals and introduced a major refactor of message & modal components (breaking change).
- Migrated to the `hmr` package for hot-reload.
- Improved voice system: missing exports, `resolveServer`, and member voice states loaded from cache.
- Enhanced Command Manager + added regex validation for command names.
- Added `createdAt` getters across multiple entities.

## Internal Improvements

- Migrated the EnvironmentService to `env_guard`.
- Reworked attachments handling in interactions.
- Rerun of the ready event to ensure the bot instance always exists.
- Added several missing exports.

## Important Fixes

- Fixed crashes related to audit logs.
- Fixed missing `inline` parameter in embed addField.
- Fixed multiple voice-related issues (null channel ID, missing exports, nullable serverId).
- Fixed IoC binding issues (Bot binding + GlobalStateManager resolution).

# 4.0.0-dev.11

- Add `Message` as return type of `.send` and `.reply` methods

# 4.0.0-dev.10

- Rework member `Role` properties
- Enforce `Snowflake` type parsing
- Change `PermissionOverwrite`
- Add missing `thumbnail` property on `MessageEmbedBuilder`
- Implement `InteractiveDialog`, `InteractiveMenu`, `InteractiveButton`

# 4.0.0-dev.9

- Complete overhaul of the API data structures
- Continued implementation of API classes
- Added rate-limit management
- Implement `audit-log` event
- Implement message reaction events

# 4.0.0-dev.8

- Fix `Member` option in commands
- Fix `Role` option in commands

# 4.0.0-dev.7

- Add missing `LogLevel` enum in exports
- Fix parent channel as ServerChannel

# 4.0.0-dev.6

- Enhance architecture
- Move interfaces to dedicated domain
- Rename mixins
- Change `Dialog` methods builder
- Implement global states
- Migrate services passing in constructors to `ioc` resolver
- Add a reconnection treatment when the heartbeat is missed 3 times
- Implement multiple running strategies

# 4.0.0-dev.5

- Add event parameters
- Prepare integration with `mineral_cli`

# 4.0.0-dev.4

- Add server methods
- Add server events
- Fix missing `server_id` property (see [pull request](https://github.com/mineral-dart/core/pull/201))

# 4.0.0-dev.3

- Move core into src folder
- Add `api` import namespace
- Add `container` import namespace
- Add `events` import namespace
- Add `services` import namespace
- Add `utils` import namespace

# 4.0.0-dev.2

## What's Changed

- feat/enhance serialization by @LeadcodeDev in https://github.com/mineral-dart/core/pull/195
- Feat/implement thread events by @PandaGuerrier in https://github.com/mineral-dart/core/pull/196

## 4.0.0-dev.1

- Fix late initialization error by @PandaGuerrier in https://github.com/mineral-dart/core/pull/101
- feat: Improve some changes by @LeadcodeDev in https://github.com/mineral-dart/core/pull/102
- feat: Upgrade of CLI service and some changes by @LeadcodeDev in https://github.com/mineral-dart/core/pull/103
- add soundboard feature by @PandaGuerrier in https://github.com/mineral-dart/core/pull/104
- Fix: Lot of bug fixes (may refactoring) by @vic256 in https://github.com/mineral-dart/core/pull/105
- docs: Write related guild documentations by @LeadcodeDev in https://github.com/mineral-dart/core/pull/106
- feat: Add permission structure by @LeadcodeDev in https://github.com/mineral-dart/core/pull/108
- Added threads (only by message) by @PandaGuerrier in https://github.com/mineral-dart/core/pull/109
- Added activities in GUILD_CREATE packet. by @PandaGuerrier in https://github.com/mineral-dart/core/pull/107
- feat: References by @PandaGuerrier in https://github.com/mineral-dart/core/pull/110
- Feat/doc by @PandaGuerrier in https://github.com/mineral-dart/core/pull/111
- fix: Accept null guild features by @vic256 in https://github.com/mineral-dart/core/pull/112
- Fix/permissions by @PandaGuerrier in https://github.com/mineral-dart/core/pull/113
- Feat: commands (roles, users and channels) permissions by @PandaGuerrier in https://github.com/mineral-dart/core/pull/115
- Improved the DX for subcommands by @PandaGuerrier in https://github.com/mineral-dart/core/pull/114
- feat: implement discord features & improve commands by @LeadcodeDev in https://github.com/mineral-dart/core/pull/116
- feat: implement missing features by @LeadcodeDev in https://github.com/mineral-dart/core/pull/117
- Before release by @PandaGuerrier in https://github.com/mineral-dart/core/pull/118
- Before release by @PandaGuerrier in https://github.com/mineral-dart/core/pull/119
- Feat: Implement snowflake timestamp by @vic256 in https://github.com/mineral-dart/core/pull/120
- Fix: option can be null by @PandaGuerrier in https://github.com/mineral-dart/core/pull/121
- Added reaction events by @PandaGuerrier in https://github.com/mineral-dart/core/pull/122
- Fix: delete interaction message by @PandaGuerrier in https://github.com/mineral-dart/core/pull/123
- Utils before release by @PandaGuerrier in https://github.com/mineral-dart/core/pull/124
- fix: allow nullables by @LeadcodeDev in https://github.com/mineral-dart/core/pull/125
- Fix/guild create by @PandaGuerrier in https://github.com/mineral-dart/core/pull/126
- New release by @PandaGuerrier in https://github.com/mineral-dart/core/pull/127
- feat: implement error handling by @LeadcodeDev in https://github.com/mineral-dart/core/pull/128
- feat: implement container by @LeadcodeDev in https://github.com/mineral-dart/core/pull/129
- feat: implement http service by @LeadcodeDev in https://github.com/mineral-dart/core/pull/130
- feat: implement environment service by @LeadcodeDev in https://github.com/mineral-dart/core/pull/131
- feat: implement logger service by @LeadcodeDev in https://github.com/mineral-dart/core/pull/132
- feat: implement kernel and developer settings by @LeadcodeDev in https://github.com/mineral-dart/core/pull/133
- feat: implement http endpoint repositories by @LeadcodeDev in https://github.com/mineral-dart/core/pull/134
- feat: implement console by @LeadcodeDev in https://github.com/mineral-dart/core/pull/135
- feat: Implement http rate limit by @abitofevrything in https://github.com/mineral-dart/core/pull/136
- Fix/intents by @LeadcodeDev in https://github.com/mineral-dart/core/pull/138
- feat(events): event managing by @LeadcodeDev in https://github.com/mineral-dart/core/pull/139
- feat(serializers): implement api serializers by @LeadcodeDev in https://github.com/mineral-dart/core/pull/140
- feat/implement-hmr by @LeadcodeDev in https://github.com/mineral-dart/core/pull/141
- feat/enhance infrastructure by @LeadcodeDev in https://github.com/mineral-dart/core/pull/152
- feat/implement-slash-commands-builder by @LeadcodeDev in https://github.com/mineral-dart/core/pull/155
- feat/implement-commands-domain by @PandaGuerrier in https://github.com/mineral-dart/core/pull/157
- feat(ioc): change ioc resolver from string to type by @LeadcodeDev in https://github.com/mineral-dart/core/pull/159
- feat(api): implement stage voice channels by @LeadcodeDev in https://github.com/mineral-dart/core/pull/164
- feat/enhance marshaller data structure by @LeadcodeDev in https://github.com/mineral-dart/core/pull/168
- feat/implement command translations and command definition by @LeadcodeDev in https://github.com/mineral-dart/core/pull/173
- feat/implement command class by @LeadcodeDev in https://github.com/mineral-dart/core/pull/175
- Implement interaction methods by @PandaGuerrier in https://github.com/mineral-dart/core/pull/166
- fix/member not exist when ban by @LeadcodeDev in https://github.com/mineral-dart/core/pull/177
- Implement member methods by @LeadcodeDev in https://github.com/mineral-dart/core/pull/178
- feat/implement-components by @LeadcodeDev in https://github.com/mineral-dart/core/pull/182
- feat/implement components by @LeadcodeDev in https://github.com/mineral-dart/core/pull/189
- Fix/multiple bugs by @PandaGuerrier in https://github.com/mineral-dart/core/pull/190
- remove member from cache when ban by @PyGaVS in https://github.com/mineral-dart/core/pull/180

## New Contributors

- @abitofevrything made their first contribution in https://github.com/mineral-dart/core/pull/136
- @PyGaVS made their first contribution in https://github.com/mineral-dart/core/pull/180

## 3.1.0

- Implement Invites
- Implement invite packets (create, delete)
- Implement many select menus (dynamic, user, role, channel, mentionable)
- Migrate of Discord component to builders (wait next release to allow constructor declaration)
- Improve `main.dart` file entrypoint
- Implement new package concept
- Fix message delete issue (no message when resolving from message id)

## 3.0.0

- Implement cli & refactor
- Implement new features
- Assign true templates
- Improve core
- Add commands git
- Implement Attachments
- Channel not initialized
- Implement http builder & split http service
- Edit attachments in messages
- Implement message bulk delete
- Improve cache
- Interaction and commands in dm channels
- Improve users

## 2.6.2

- Fix bad guild id
- Remove nullable content of `Message`

## 2.6.1

- Remove `late` keyword & refactor
- Improve `ButtonInteration` access with getters

## 2.6.0

- Remove mixins to public access
- Add `createdAt` and `updatedAt` to `Message`
- Add correct message type from `fetch()`

## 2.5.0

- Add `make:service`
- Add `<String>.equals(value)`
- Remove String formatters and implement Recase

## 2.4.1

- Fix wrong template (make:event)
- Fix wrong template (make:state)

## 2.4.0

- Redesign of the order guest
- Implemented the new CLI from `mineral_cli`.
- Removing dependencies using `ffi`
- Refactor application
- Move managers to services

## 2.3.1

- Fix bad User avatar decoration type
- Improve `category.create()` return type
- Make allow and deny to no required params

## 2.3.0

- Improve context menu declaration
- Fix bad state matching

## 2.2.0

- Add plugins access to the `MineralContext`

## 2.1.0

- Migrate environment to dedicated package

## 2.0.0 - Release

- Improve accessibility
- Implement lasted Discord updates
- Move decorators to fully generics
- Improve collections key matching (thanks generics)
- Move framework context to dedicated mixin `MineralContext`
- Move ioc accessibility to dedicated mixin `Container`
- Standardized packages entrypoints
- Add executable compile feature
- More..

## 1.2.1

- Fix wrong userId key into interactions

## 1.2.0

- Implement `setDefaultReactionEmoji` method
- Implement `setTags` method
- Implement `setDefaultRateLimit` method

## 1.1.0

- Implement forum channels

## 1.0.8 - 1.0.9

- Add missing return

## 1.0.7

- Implement `unban` method
- Improve voice member

## 1.0.6

- Fix CategoryChannel cast
- Improve `nickname` getter, it returns the username if nickname is not defined
- Implement `getOrFail` and `getOr` methods on Environment

## 1.0.5

- Fix missing examples

## 1.0.4

- Fix badge url

## 1.0.3

- Improve `dart analyse` to get 100%
- Generate api documentation

## 1.0.2

- Write documentation examples

## 1.0.1

- Improve readme shields
- Improve `dart analyse` to get 100%
- Remove unimplemented code

## 1.0.0 Pre-release

- Initialize mineral framework project
