import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:recase/recase.dart';

final class EnvPlaceholder implements PlaceholderContract {
  final Map<String, dynamic> _values = {};

  @override
  String get identifier => 'env';

  @override
  Map<String, dynamic> get values => _values;

  EnvPlaceholder() {
    _injectEntryMap(identifier, env.toJson());
  }

  void _injectEntryMap(String identifier, Map<String, dynamic> values) {
    final mapEntry = Map<String, dynamic>.from(
      values.map((key, value) {
        final currentKey = key.snakeCase.toUpperCase();
        return MapEntry('$identifier.$currentKey', value);
      }),
    );

    _values.addAll(mapEntry);
  }

  @override
  String apply(String value) {
    return values.entries.fold(value, (acc, element) {
      final String finalValue = switch (element.value) {
        final String s => s,
        final int i => i.toString(),
        _ => throw Exception('Invalid type'),
      };

      return acc
          .replaceAll('{${element.key}}', finalValue)
          .replaceAll('{{ ${element.key} }}', finalValue);
    });
  }
}
