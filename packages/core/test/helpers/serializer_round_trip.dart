/// Test helpers enforcing the contract that ties a serializer's two halves
/// together.
///
/// A serializer is fed *raw Discord payloads* by the packet listeners and the
/// datastore parts, which call [SerializerContract.normalize] and hand its
/// output straight to [SerializerContract.serialize]. Nothing in the type
/// system links those two shapes: `normalize` returns `Map<String, dynamic>`
/// and `serialize` accepts `Map<String, dynamic>`, so a key that one nests and
/// the other reads flat compiles fine and yields `null` at runtime.
///
/// Testing the halves in isolation — a fixture shaped for `serialize`, another
/// shaped for `normalize` — cannot catch that. It is how `mineral` shipped
/// v5.1.1 with `Guild.assets.icon` always null and `guild.roles.get()` throwing
/// on every call while the suite stayed green.
///
/// **Fixtures must mirror the Discord wire format, never the serializer's
/// expectations.** When Discord marks a field optional, exercise both the
/// present and the absent case: a fixture that always supplies an optional
/// field proves nothing about the path real traffic takes.
library;

import 'dart:async';

import 'package:mineral/src/infrastructure/internals/marshaller/types/serializer.dart';
import 'package:test/test.dart';

/// Runs the real pipeline: `serialize(await normalize(raw))`.
///
/// [raw] must be a payload Discord actually sends. Throws whatever the
/// serializer throws — which is the point: a serializer that cannot consume its
/// own `normalize` output must fail here rather than silently produce an entity
/// full of nulls.
Future<T> roundTrip<T>(
  SerializerContract<T> serializer,
  Map<String, dynamic> raw,
) async {
  final normalized = await serializer.normalize(raw);
  return serializer.serialize(normalized);
}

/// Asserts that the raw Discord payload survives `normalize` -> `serialize`.
///
/// [expectations] maps a human-readable field label to a getter on the produced
/// entity; each is checked against the matcher supplied by the caller. Labels
/// appear verbatim in the failure message, so name them after the public
/// accessor a bot author would use (`Guild.assets.icon`, not `icon`).
///
/// ```dart
/// await expectRoundTrip(
///   serializer,
///   rawDiscordPayload(),
///   {
///     'Guild.assets.icon': (g) => expect(g.assets.icon, isNotNull),
///     'Guild.settings.afkTimeout': (g) => expect(g.settings.afkTimeout, 300),
///   },
/// );
/// ```
Future<void> expectRoundTrip<T>(
  SerializerContract<T> serializer,
  Map<String, dynamic> raw,
  Map<String, void Function(T entity)> expectations,
) async {
  final entity = await roundTrip(serializer, raw);

  for (final entry in expectations.entries) {
    try {
      entry.value(entity);
    } on TestFailure catch (error) {
      fail(
        'Round-trip lost "${entry.key}".\n'
        'serialize(normalize(raw)) did not preserve this field — check that '
        'serialize reads the shape normalize writes.\n'
        '${error.message}',
      );
    }
  }
}

/// Asserts the pipeline survives a payload where every optional field is
/// absent.
///
/// [raw] is the full payload; [optionalKeys] are the keys Discord documents as
/// optional (or nullable). They are removed before the round-trip. A serializer
/// that hard-casts an optional field throws here.
Future<void> expectRoundTripWithoutOptionals<T>(
  SerializerContract<T> serializer,
  Map<String, dynamic> raw,
  Set<String> optionalKeys,
) async {
  final trimmed = Map<String, dynamic>.from(raw)
    ..removeWhere((key, _) => optionalKeys.contains(key));

  await expectLater(
    roundTrip(serializer, trimmed),
    completes,
    reason:
        'Discord omits ${optionalKeys.join(', ')} on this payload; the '
        'serializer must not hard-cast them.',
  );
}
