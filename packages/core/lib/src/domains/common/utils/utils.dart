import 'dart:async';
import 'package:mineral/src/api/common/types/enhanced_enum.dart';

FutureOr<T?> createOrNull<T>({
  required dynamic field,
  required FutureOr<T?> Function() fn,
}) async => field != null ? await fn() : null;

List<T> bitfieldToList<T extends EnhancedEnum<int>>(
  List<T> values,
  int bitfield,
) {
  final List<T> flags = [];

  for (final element in values) {
    if ((bitfield & element.value) == element.value) {
      flags.add(element);
    }
  }
  return flags;
}

int listToBitfield<T extends EnhancedEnum<int>>(List<T> values) {
  return values.fold(
    0,
    (previousValue, element) => previousValue | element.value,
  );
}

/// Converts [dateTime] to the UTC ISO-8601 string Discord's API expects for
/// outbound timestamps (e.g. `2026-08-02T12:30:00.000Z`).
///
/// `DateTime.now()` returns a local-zone value, and [DateTime.toIso8601String]
/// only appends the `Z` suffix when the instance is UTC. Sending a bare
/// local-zone string is misread by Discord as an already-UTC instant, so
/// every outbound timestamp must be routed through this helper first.
String toDiscordTimestamp(DateTime dateTime) =>
    dateTime.toUtc().toIso8601String();

T findInEnum<T extends EnhancedEnum<R>, R>(
  List<T> values,
  R? value, {
  T? orElse,
}) {
  if (value == null) {
    if (orElse != null) {
      return orElse;
    }
    throw ArgumentError('No $T found for null value');
  }
  return values.firstWhere(
    (element) => element.value == value,
    orElse: orElse != null
        ? () => orElse
        : () => throw ArgumentError('No $T found for value "$value"'),
  );
}

void expectOrThrow(bool value, {String? message}) {
  if (!value) {
    throw Exception(message);
  }
}
