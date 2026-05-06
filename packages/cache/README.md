# Cache

The cache package provides a straightforward and effective solution for cache management in Mineral applications. By externalizing application consumption, it helps improve performance and optimize resources, thus offering a better user experience.

![icons technologies](https://skillicons.dev/icons?i=discord,dart,redis, )

## Introduction

Caching plays a crucial role in many applications by offering a temporary and decoupled storage solution from the core of the project. It helps optimize performance by reducing response times and limiting calls to external resources such as databases or APIs.

## Features

- **In-Memory Cache** — stores data directly in memory, providing fast response times for accessing data already loaded into the cache.
- **Redis Cache** — distributed caching with sub-second TTL precision via `SET … PX`.

## Installation

```yaml
dependencies:
  mineral_cache: ^1.2.0
```

Then run `dart pub get`.

## Usage

```dart
final client = ClientBuilder()
  .setIntent(Intent.allNonPrivileged)
  .setCache(MemoryProvider.new)
  .build();
```

`setCache` accepts an optional `config:` to customize the runtime behavior:

```dart
.setCache(MemoryProvider.new, config: CacheConfig.defaults())   // default
.setCache(MemoryProvider.new, config: CacheConfig.legacy())     // pre-v5
.setCache(MemoryProvider.new, config: CacheConfig(
  ttlPolicy: CacheTtlPolicy.defaults().override({
    'users/': const Duration(minutes: 15),
  }),
  sweeperInterval: const Duration(seconds: 30),
))
```

## Cache strategy

`CacheConfig.defaults()` is applied automatically when `setCache(provider)` is called without a config. It enables four behaviors:

| Flag                   | Default               | What it does                                                                 |
| ---------------------- | --------------------- | ---------------------------------------------------------------------------- |
| `ttlPolicy`            | `CacheTtlPolicy.defaults()` | Longest-match prefix/segment rules. See table below.                   |
| `clearOnReady`         | `true`                | Clears the cache on the first `READY` to discard data stale during downtime. |
| `invalidationEnabled`  | `true`                | Routes `cache.invalidate(...)` calls inside packet listeners to `cache.remove(...)`. |
| `sweeperInterval`      | `1 minute`            | In-memory provider sweeps expired entries on this cadence (`Duration.zero` disables it). |
| `staggerClearMs`       | `500`                 | Random delay applied before `clearOnReady` runs, to spread reconnect storms across shards. |

### TTL policy defaults

| Key family           | Example                          | TTL        |
| -------------------- | -------------------------------- | ---------- |
| `ref:…`              | `ref:server/123/assets`          | never      |
| `voice_states/…`     | `voice_states/server/1/members/2`| 5 minutes  |
| `…/members/…`        | `server/1/members/2`             | 30 minutes |
| `…/roles/…`          | `server/1/roles/9`               | 4 hours    |
| `…/emojis/…`         | `server/1/emojis/9`              | 12 hours   |
| `…/stickers/…`       | `server/1/stickers/9`            | 12 hours   |
| `…/messages/…`       | `channels/1/messages/2`          | 10 minutes |
| `server/…`           | `server/123`                     | 4 hours    |
| `channels/…`         | `channels/456`                   | 2 hours    |
| `users/…`            | `users/789`                      | 1 hour     |
| `threads/…`          | `threads/100`                    | 2 hours    |
| `messages/…`         | `messages/200/embeds/uid`        | 10 minutes |
| `invites/…`          | `invites/abc123`                 | 1 hour     |

Custom rules win over defaults via `CacheTtlPolicy.override({'users/': Duration(minutes: 15)})`.

### Opting out

To preserve the pre-TTL behavior (entries live forever, no automatic invalidation):

```dart
.setCache(MemoryProvider.new, config: CacheConfig.legacy())
```

Custom `CacheProviderContract` implementations must accept the `{Duration? ttl}` named optional on `put` / `putMany`.
