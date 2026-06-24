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
    (previousValue, element) => previousValue += element.value,
  );
}

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
